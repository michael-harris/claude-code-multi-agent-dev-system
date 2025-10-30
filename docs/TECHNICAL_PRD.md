# Technical Product Requirements Document: CS Archiver

## Executive Summary

CS Archiver is a web-based application for archiving media files from QNAP NAS to Globus cloud storage. The system automates the workflow of copying folders from network shares, compressing them into 7z archives, uploading to Globus with verification, and safely deleting source files.

**Technology Stack:**
- **Backend:** FastAPI (Python)
- **Frontend:** React
- **Storage:** QNAP NAS mounted at `/mnt/qnap/`
- **Cloud:** Globus Transfer API
- **Compression:** 7z (p7zip)

---

## 1. System Architecture

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    React Frontend                        │
│  • Folder Browser • Queue View • Job Status • Logs      │
└──────────────────────┬──────────────────────────────────┘
                       │ REST API + WebSocket
┌──────────────────────▼──────────────────────────────────┐
│                   FastAPI Backend                        │
│  • API Endpoints • Authentication • Job Management       │
└──┬────────────────────────────────────────────┬─────────┘
   │                                             │
   │  Background Workers                         │  Database
   │                                             │
┌──▼──────────────────┐    ┌──────────────────▼─────────┐
│  Copy/Compress      │    │  PostgreSQL / SQLite        │
│  Worker             │    │  • Jobs • Users • Logs      │
│  (1 instance)       │    │  • Progress • History       │
└──┬──────────────────┘    └────────────────────────────┘
   │
┌──▼──────────────────┐
│  Upload Worker      │
│  (1 instance)       │
│  Can run parallel   │
└──┬──────────────────┘
   │
┌──▼──────────────────┐
│  Globus Transfer    │
│  API Client         │
└─────────────────────┘
```

### 1.2 Worker Concurrency Model

**Concurrency Rules:**
- **Copy/Compress Worker:** Single instance, processes one job at a time
- **Upload Worker:** Single instance, can run in parallel with Copy/Compress
- **Not Allowed:** Copy and Compression running simultaneously (same worker handles both)

**State Transitions:**
```
Job Created → Queued → Copying → Compressing → Uploading → Verifying → Completed
                ↓         ↓           ↓            ↓            ↓
              Cancelled  Failed     Failed      Failed      Failed
```

---

## 2. Core Functionality Requirements

### 2.1 Folder Discovery & Selection

**Source Path Pattern:**
```
/mnt/qnap/CitySpace Tech Team/*/*/*/
```

**Discovery Logic:**
- Scan all subdirectories exactly **3 levels deep** under `/mnt/qnap/CitySpace Tech Team/`
- **Level 1:** Category (e.g., `Category1/`)
- **Level 2:** Subcategory (e.g., `Subcategory1/`)
- **Level 3:** Target folders to archive (e.g., `Folder_A/`)

**Exclusion Rules:**
1. **Ignore folders with only a single `.txt` file** (regardless of filename)
2. **Ignore folders with any marker file** (`.archived`, `-ARCHIVED-TO-GLOBUS.txt`, etc.)
3. Empty folders should be ignored

**Example:**
```
/mnt/qnap/CitySpace Tech Team/
├── Production/                          [Level 1]
│   ├── 2024/                            [Level 2]
│   │   ├── Project_Alpha/               [Level 3] ✅ List this
│   │   │   ├── file1.mp4
│   │   │   └── file2.mp4
│   │   ├── Project_Beta/                [Level 3] ❌ Ignore (only txt file)
│   │   │   └── notes.txt
│   │   └── Project_Gamma/               [Level 3] ❌ Ignore (has marker)
│   │       ├── file1.mp4
│   │       └── -ARCHIVED-TO-GLOBUS.txt
│   └── 2023/                            [Level 2]
│       └── Old_Project/                 [Level 3] ✅ List this
│           └── media/
│               └── video.mp4
```

### 2.2 Copy & Compress Workflow

**Strategy:** Copy to local storage first, then compress.

**Step 1: Copy to Local**
- **Source:** `/mnt/qnap/CitySpace Tech Team/{level1}/{level2}/{folder_name}/`
- **Destination:** `/storage/temp/{job_id}/{folder_name}/`
- **Method:** High-performance copy strategy from `wbur-archiver`
  - Small (<1GB): `shutil.copy2`
  - Medium (1-100GB): `rsync` with progress
  - Large (100GB-1TB): `dd` with 1MB blocks
  - Huge (>1TB): Parallel copy with ThreadPoolExecutor

**Step 2: Compress**
- **Input:** `/storage/temp/{job_id}/{folder_name}/`
- **Output:** `/storage/archives/{folder_name}.tar.7z`
- **Command:**
  ```bash
  7z a -t7z -mx1 -mmt=on /storage/archives/{folder_name}.tar.7z /storage/temp/{job_id}/{folder_name}/
  ```
- **Parameters:**
  - `-t7z`: 7z format
  - `-mx1`: Fast compression (level 1)
  - `-mmt=on`: Multi-threaded compression

**Step 3: Verify Archive Integrity**
- **Command:**
  ```bash
  7z t /storage/archives/{folder_name}.tar.7z
  ```
- **Success:** Exit code 0
- **Failure:** Delete archive, mark job as failed, retry (see retry logic)

**Step 4: Delete Temporary Copy**
- Delete `/storage/temp/{job_id}/` after successful compression and verification

### 2.3 Upload Workflow

**Upload to Globus**
- **Source:** `/storage/archives/{folder_name}.tar.7z`
- **Destination:** Same path structure on Globus as source on QNAP
  - QNAP: `/mnt/qnap/CitySpace Tech Team/{level1}/{level2}/{folder_name}/`
  - Globus: `/{level1}/{level2}/{folder_name}.tar.7z`
- **Method:** Globus Transfer API
  ```python
  tc.submit_transfer(TransferData(
      source_endpoint=LOCAL_ENDPOINT,
      destination_endpoint=GLOBUS_ENDPOINT,
      verify_checksum=True,
      sync_level="checksum"
  ))
  ```

**Upload Monitoring**
- Poll Globus task status every 60 seconds
- Timeout: 12 hours (for TB-sized files)
- Update job progress in database

### 2.4 Upload Verification (Triple Verification)

**Verification 1: Task Completion**
```python
# Poll Globus API until task status = SUCCEEDED
task_status = tc.get_task(task_id)
if task_status['status'] != 'SUCCEEDED':
    verification_failed()
```

**Verification 2: Remote File Exists**
```python
# Use Globus operation_ls to check file exists
remote_info = tc.operation_ls(endpoint_id, path=remote_path)
if not remote_info or remote_file not in remote_info['DATA']:
    verification_failed()
```

**Verification 3: Size Match (within 1% tolerance)**
```python
remote_size = remote_info['size']
local_size = os.path.getsize(local_archive_path)
percentage_diff = abs(remote_size - local_size) / local_size * 100

if percentage_diff >= 1.0:  # More than 1% difference
    verification_failed()
```

**Only proceed to deletion if ALL THREE verifications pass.**

### 2.5 Archive Deletion (Local)

**After Triple Verification Passes:**
- Delete `/storage/archives/{folder_name}.tar.7z`
- Log deletion with timestamp and file size

**Safety:**
- Never delete local archive unless all 3 verifications pass
- Log all deletion attempts and results

### 2.6 Source Deletion (QNAP)

**After Successful Upload and Verification:**

**Step 1: Delete all folder contents**
```python
# Delete all files and subdirectories
for root, dirs, files in os.walk(source_path, topdown=False):
    for file in files:
        os.remove(os.path.join(root, file))
    for dir in dirs:
        os.rmdir(os.path.join(root, dir))
```

**Step 2: Create marker file**
- **Filename:** `{folder_name}-ARCHIVED-TO-GLOBUS.txt`
- **Location:** `/mnt/qnap/CitySpace Tech Team/{level1}/{level2}/{folder_name}/{folder_name}-ARCHIVED-TO-GLOBUS.txt`
- **Contents:**
  ```
  Archived on: 2024-01-15 14:32:01 UTC
  Archive name: {folder_name}.tar.7z
  Globus path: /{level1}/{level2}/{folder_name}.tar.7z
  Job ID: {job_id}
  User: {username}
  ```

**Result:** Folder remains on QNAP but is empty except for marker file.

**Job Cancellation Behavior:**
- If job is cancelled **before** upload completes, source folder remains untouched
- If job is cancelled **during** verification, source folder remains untouched
- Source deletion **only** happens after successful verification

---

## 3. Queue & Job Management

### 3.1 Job Queue System

**Single Unified Queue:**
- Jobs are processed in FIFO order
- Queue stored in database (persistent across restarts)

**Job States:**
```python
class JobStatus(enum.Enum):
    QUEUED = "queued"           # Waiting to start
    COPYING = "copying"         # Copying from QNAP to /storage/temp/
    COMPRESSING = "compressing" # Creating .tar.7z archive
    VERIFYING = "verifying"     # 7z integrity test
    UPLOADING = "uploading"     # Globus transfer in progress
    UPLOAD_VERIFYING = "upload_verifying"  # Triple verification
    DELETING_SOURCE = "deleting_source"    # Removing QNAP source
    COMPLETED = "completed"     # Successfully finished
    FAILED = "failed"           # Error occurred
    CANCELLED = "cancelled"     # User cancelled
```

**Concurrency Model:**
- **1 Copy/Compress job** can run at a time (states: COPYING, COMPRESSING, VERIFYING)
- **1 Upload job** can run at a time (states: UPLOADING, UPLOAD_VERIFYING, DELETING_SOURCE)
- These **can run in parallel** (e.g., Job A uploading while Job B compresses)

### 3.2 Job Database Schema

```sql
CREATE TABLE jobs (
    id UUID PRIMARY KEY,
    folder_name TEXT NOT NULL,
    source_path TEXT NOT NULL,              -- /mnt/qnap/CitySpace Tech Team/.../folder_name
    globus_destination_path TEXT NOT NULL,  -- /{level1}/{level2}/{folder_name}.tar.7z
    archive_path TEXT,                       -- /storage/archives/{folder_name}.tar.7z
    status TEXT NOT NULL,                    -- JobStatus enum
    progress_percent INTEGER DEFAULT 0,      -- 0-100
    current_operation TEXT,                  -- Human-readable status
    folder_size_bytes BIGINT,
    archive_size_bytes BIGINT,
    created_by TEXT NOT NULL,                -- Username
    created_at TIMESTAMP NOT NULL,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    globus_task_id TEXT                      -- For monitoring
);

CREATE TABLE job_logs (
    id SERIAL PRIMARY KEY,
    job_id UUID REFERENCES jobs(id),
    timestamp TIMESTAMP NOT NULL,
    level TEXT NOT NULL,                     -- INFO, WARNING, ERROR
    message TEXT NOT NULL
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL,
    last_login TIMESTAMP
);
```

### 3.3 Error Handling & Retries

**Retry Configuration:**
- **Compression failures:** 3 retries, 30-second delays
- **Upload failures:** 5 retries, 30-second delays
- **Connection errors:** 10 retries, 30-second delays

**Retry Logic:**
```python
max_retries = {
    'compression': 3,
    'upload': 5,
    'connection_error': 10
}

retry_delay = 30  # seconds

while retry_count < max_retries[operation]:
    try:
        result = perform_operation()
        if result.success:
            break
    except Exception as e:
        retry_count += 1
        log_error(f"Attempt {retry_count} failed: {e}")
        if retry_count < max_retries:
            time.sleep(retry_delay)
        else:
            mark_job_failed()
```

**Failed Job Handling:**
- After max retries, job status → `FAILED`
- Error message stored in database
- User can **manually retry** from UI:
  - Click "Retry" button on failed job
  - Job returns to `QUEUED` state
  - Retry counter resets to 0

**Transient vs Permanent Errors:**
- **Transient (retry):** Network errors, I/O timeouts, connection refused
- **Permanent (fail immediately):** File not found, permission denied, invalid archive format

---

## 4. Disk Space Management

### 4.1 Space Requirements

**Before Starting Job:**
```python
# Conservative estimate
folder_size_gb = folder_size_bytes / (1024**3)
estimated_archive_size_gb = folder_size_gb * 0.7  # 70% compression ratio
required_space_gb = max(estimated_archive_size_gb, 10.0)  # Minimum 10GB

# Check available space
free_space_gb = get_free_space('/storage')

if free_space_gb < required_space_gb:
    # Block job from starting
    update_status("Waiting for disk space")
    # Keep in QUEUED state, check again later
```

**Space Monitoring:**
- Check disk space before starting each job
- If insufficient space, job remains in `QUEUED` state
- Re-check every 60 seconds
- Display warning in UI

**Cleanup Strategy:**
- Temporary files (`/storage/temp/{job_id}/`) deleted after compression
- Archives (`/storage/archives/{folder_name}.tar.7z`) deleted after upload verification
- Failed job artifacts moved to `/storage/failed/{job_id}/` for debugging

### 4.2 Storage Paths

```
/storage/
├── temp/                      # Temporary copies during processing
│   └── {job_id}/
│       └── {folder_name}/     # Copy of QNAP folder
├── archives/                  # Compressed archives waiting for upload
│   └── {folder_name}.tar.7z
└── failed/                    # Failed job artifacts for debugging
    └── {job_id}/
        ├── {folder_name}.tar.7z
        └── error.log
```

---

## 5. API Endpoints

### 5.1 Authentication

**POST /api/auth/login**
```json
Request:
{
  "username": "string",
  "password": "string"
}

Response:
{
  "access_token": "jwt_token_string",
  "token_type": "bearer",
  "user": {
    "id": "int",
    "username": "string",
    "is_admin": "boolean"
  }
}
```

**POST /api/auth/logout**
```json
Headers: Authorization: Bearer {token}
Response: 204 No Content
```

**GET /api/auth/me**
```json
Headers: Authorization: Bearer {token}
Response:
{
  "id": "int",
  "username": "string",
  "is_admin": "boolean"
}
```

### 5.2 User Management (Admin Only)

**GET /api/users**
```json
Headers: Authorization: Bearer {admin_token}
Response:
[
  {
    "id": "int",
    "username": "string",
    "is_admin": "boolean",
    "created_at": "iso8601",
    "last_login": "iso8601"
  }
]
```

**POST /api/users**
```json
Headers: Authorization: Bearer {admin_token}
Request:
{
  "username": "string",
  "password": "string",
  "is_admin": "boolean"
}
Response: 201 Created
{
  "id": "int",
  "username": "string",
  "is_admin": "boolean"
}
```

**DELETE /api/users/{user_id}**
```json
Headers: Authorization: Bearer {admin_token}
Response: 204 No Content
```

### 5.3 Folder Discovery

**GET /api/folders**
```json
Headers: Authorization: Bearer {token}
Query Parameters:
  - refresh: boolean (force rescan, default: false)

Response:
[
  {
    "path": "/mnt/qnap/CitySpace Tech Team/Production/2024/Project_Alpha",
    "name": "Project_Alpha",
    "level1": "Production",
    "level2": "2024",
    "size_bytes": 1073741824,
    "size_human": "1.00 GB",
    "modified_at": "iso8601",
    "file_count": 42,
    "is_archived": false
  }
]
```

### 5.4 Job Management

**POST /api/jobs**
```json
Headers: Authorization: Bearer {token}
Request:
{
  "folder_path": "/mnt/qnap/CitySpace Tech Team/Production/2024/Project_Alpha"
}

Response: 201 Created
{
  "job_id": "uuid",
  "status": "queued",
  "folder_name": "Project_Alpha",
  "created_at": "iso8601"
}
```

**GET /api/jobs**
```json
Headers: Authorization: Bearer {token}
Query Parameters:
  - status: string (filter by status)
  - limit: int (default: 100)
  - offset: int (default: 0)

Response:
[
  {
    "job_id": "uuid",
    "folder_name": "string",
    "status": "queued|copying|compressing|uploading|completed|failed|cancelled",
    "progress_percent": 0-100,
    "current_operation": "string",
    "created_by": "string",
    "created_at": "iso8601",
    "started_at": "iso8601|null",
    "completed_at": "iso8601|null",
    "error_message": "string|null"
  }
]
```

**GET /api/jobs/{job_id}**
```json
Headers: Authorization: Bearer {token}
Response:
{
  "job_id": "uuid",
  "folder_name": "string",
  "source_path": "string",
  "globus_destination_path": "string",
  "status": "string",
  "progress_percent": 0-100,
  "current_operation": "string",
  "folder_size_bytes": "bigint|null",
  "archive_size_bytes": "bigint|null",
  "created_by": "string",
  "created_at": "iso8601",
  "started_at": "iso8601|null",
  "completed_at": "iso8601|null",
  "error_message": "string|null",
  "retry_count": "int",
  "globus_task_id": "string|null"
}
```

**DELETE /api/jobs/{job_id}**
```json
Headers: Authorization: Bearer {token}
Response: 204 No Content
Note: Cancels job if running, removes from queue if pending
Behavior: Source folder NOT deleted if cancelled before upload completes
```

**POST /api/jobs/{job_id}/retry**
```json
Headers: Authorization: Bearer {token}
Response: 200 OK
{
  "job_id": "uuid",
  "status": "queued",
  "retry_count": 0
}
Note: Only works for FAILED jobs
```

**GET /api/jobs/{job_id}/logs**
```json
Headers: Authorization: Bearer {token}
Query Parameters:
  - limit: int (default: 1000)
  - level: string (filter by INFO|WARNING|ERROR)

Response:
[
  {
    "timestamp": "iso8601",
    "level": "INFO|WARNING|ERROR",
    "message": "string"
  }
]
```

**DELETE /api/jobs/completed**
```json
Headers: Authorization: Bearer {token}
Response: 200 OK
{
  "deleted_count": "int"
}
Note: Bulk delete all completed jobs from history
```

### 5.5 Queue Status

**GET /api/queue**
```json
Headers: Authorization: Bearer {token}
Response:
{
  "current_copy_compress_job": {
    "job_id": "uuid",
    "folder_name": "string",
    "status": "copying|compressing|verifying",
    "progress_percent": 0-100
  } | null,
  "current_upload_job": {
    "job_id": "uuid",
    "folder_name": "string",
    "status": "uploading|upload_verifying|deleting_source",
    "progress_percent": 0-100
  } | null,
  "queued_jobs": [
    {
      "job_id": "uuid",
      "folder_name": "string",
      "position": "int"
    }
  ]
}
```

### 5.6 System Status

**GET /api/system/status**
```json
Headers: Authorization: Bearer {token}
Response:
{
  "disk_space": {
    "total_gb": "float",
    "used_gb": "float",
    "free_gb": "float",
    "percent_used": "float"
  },
  "workers": {
    "copy_compress": {
      "status": "idle|busy",
      "current_job_id": "uuid|null"
    },
    "upload": {
      "status": "idle|busy",
      "current_job_id": "uuid|null"
    }
  },
  "statistics": {
    "total_jobs": "int",
    "completed_jobs": "int",
    "failed_jobs": "int",
    "queued_jobs": "int"
  }
}
```

**GET /api/health**
```json
Response: 200 OK
{
  "status": "healthy",
  "timestamp": "iso8601"
}
```

### 5.7 WebSocket

**WS /ws/jobs**
```json
Connection: Upgrade to WebSocket
Authentication: ?token={jwt_token}

Server sends real-time updates:
{
  "type": "job_update",
  "job_id": "uuid",
  "status": "string",
  "progress_percent": 0-100,
  "current_operation": "string"
}

{
  "type": "queue_update",
  "queue_length": "int",
  "current_copy_compress_job": "uuid|null",
  "current_upload_job": "uuid|null"
}

{
  "type": "log",
  "job_id": "uuid",
  "timestamp": "iso8601",
  "level": "INFO|WARNING|ERROR",
  "message": "string"
}
```

---

## 6. Frontend Requirements

### 6.1 Pages & Routes

**Public Routes:**
- `/login` - Login page

**Protected Routes (Authenticated):**
- `/` - Dashboard (redirects to `/folders`)
- `/folders` - Folder browser
- `/queue` - Queue & current jobs
- `/history` - Job history
- `/jobs/{job_id}` - Job detail with logs
- `/settings` - User settings

**Admin-Only Routes:**
- `/admin/users` - User management

### 6.2 Folder Browser Page (`/folders`)

**Layout:**
```
┌─────────────────────────────────────────────────────────┐
│ Header: CS Archiver | User: {username} | Logout         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Search: [_____________] 🔍  [Refresh Folders]          │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │ Folder Name     | Size    | Modified   | Actions   │ │
│  ├────────────────────────────────────────────────────┤ │
│  │ Project_Alpha   | 1.2 GB  | 2024-01-10 | [Archive] │ │
│  │ Project_Beta    | 850 MB  | 2024-01-09 | [Archive] │ │
│  │ Project_Gamma   | 2.5 GB  | 2024-01-08 | [Archive] │ │
│  │ ...                                                 │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  Pagination: < 1 2 3 4 5 >                              │
└─────────────────────────────────────────────────────────┘
```

**Features:**
- Table displays all discoverable folders
- Search/filter by folder name
- Sort by name, size, or modified date
- "Archive" button per folder
  - Click → Creates job → Adds to queue → Redirects to `/queue`
- Refresh button to rescan folders (forces new scan)

### 6.3 Queue & Jobs Page (`/queue`)

**Layout:**
```
┌─────────────────────────────────────────────────────────┐
│ Header: CS Archiver | User: {username} | Logout         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Current Operations                                      │
│  ┌────────────────────────────────────────────────────┐ │
│  │ Copy/Compress:                                      │ │
│  │   Project_Alpha - Compressing...                    │ │
│  │   ████████████░░░░░░░░░░░░ 66% (Step 2/3)         │ │
│  │                                                     │ │
│  │ Upload:                                             │ │
│  │   Project_Beta - Uploading...                       │ │
│  │   ████████████████░░░░░░░░ 75%                     │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  Queue (3 jobs)                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │ Position | Folder Name     | Created By | Actions  │ │
│  ├────────────────────────────────────────────────────┤ │
│  │ 1        | Project_Gamma   | john       | [Cancel] │ │
│  │ 2        | Project_Delta   | jane       | [Cancel] │ │
│  │ 3        | Project_Epsilon | john       | [Cancel] │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  [View History]                                          │
└─────────────────────────────────────────────────────────┘
```

**Features:**
- **Current Operations Panel:**
  - Shows up to 2 active jobs (Copy/Compress + Upload)
  - Progress bars with percentage
  - Step indicators for Copy/Compress: "Step 1/3: Copying", "Step 2/3: Compressing", "Step 3/3: Verifying"
  - Upload shows single progress bar
- **Queue Panel:**
  - Lists all queued jobs in order
  - Position number
  - Created by username
  - Cancel button per job
- **Real-time Updates:**
  - WebSocket connection updates progress bars live
  - Queue updates when jobs start/complete/cancel

### 6.4 Job History Page (`/history`)

**Layout:**
```
┌─────────────────────────────────────────────────────────┐
│ Header: CS Archiver | User: {username} | Logout         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Job History                      [Clear Completed]      │
│                                                          │
│  Filter: [All ▼] [Completed ✓] [Failed ✓] [Cancelled ✓]│
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │ Folder Name  | Status  | Created By | Duration     │ │
│  ├────────────────────────────────────────────────────┤ │
│  │ Project_A    | ✓ Done  | john       | 1h 23m       │ │
│  │ Project_B    | ✗ Failed| jane       | 45m          │ │
│  │ Project_C    | ⊗ Cancel| john       | 12m          │ │
│  │ ...                                                 │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  Pagination: < 1 2 3 4 5 >                              │
└─────────────────────────────────────────────────────────┘
```

**Features:**
- Table of completed/failed/cancelled jobs
- Filter by status
- Click row → Navigate to `/jobs/{job_id}` for details
- "Clear Completed" button → Bulk delete all completed jobs
- Shows duration for completed jobs
- Color coding: green (completed), red (failed), gray (cancelled)

### 6.5 Job Detail Page (`/jobs/{job_id}`)

**Layout:**
```
┌─────────────────────────────────────────────────────────┐
│ Header: CS Archiver | User: {username} | Logout         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Job: Project_Alpha                       [Retry]        │
│                                                          │
│  Status: Failed                                          │
│  Created: 2024-01-15 14:32:01 by john                   │
│  Started: 2024-01-15 14:32:05                           │
│  Ended: 2024-01-15 15:45:23                             │
│  Duration: 1h 13m 18s                                    │
│                                                          │
│  Source: /mnt/qnap/CitySpace Tech Team/Prod/2024/...    │
│  Destination: /Prod/2024/Project_Alpha.tar.7z           │
│  Folder Size: 1.2 GB                                     │
│  Archive Size: 850 MB                                    │
│                                                          │
│  Error: Upload verification failed - size mismatch      │
│         Remote: 842 MB, Local: 850 MB                   │
│                                                          │
│  Logs:                                      [Download]   │
│  ┌────────────────────────────────────────────────────┐ │
│  │ 14:32:05 INFO  Job started                          │ │
│  │ 14:32:05 INFO  Copying from QNAP...                 │ │
│  │ 14:45:12 INFO  Copy complete (1.2 GB)               │ │
│  │ 14:45:12 INFO  Starting compression...              │ │
│  │ 15:02:34 INFO  Compression complete (850 MB)        │ │
│  │ 15:02:35 INFO  Archive integrity verified           │ │
│  │ 15:02:36 INFO  Starting Globus upload...            │ │
│  │ 15:43:12 INFO  Upload complete                      │ │
│  │ 15:43:15 ERROR Upload verification failed           │ │
│  │ 15:45:23 ERROR Job failed after 3 retries           │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Features:**
- Full job details
- Live log streaming (via WebSocket) for active jobs
- "Retry" button for failed jobs
- "Download Logs" button to download full logs as .txt
- Real-time updates if job is still running

### 6.6 User Management Page (`/admin/users`) - Admin Only

**Layout:**
```
┌─────────────────────────────────────────────────────────┐
│ Header: CS Archiver | User: admin | Logout              │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  User Management                    [+ Create User]      │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │ Username  | Admin | Created    | Last Login | Del  │ │
│  ├────────────────────────────────────────────────────┤ │
│  │ admin     | ✓     | 2024-01-01 | 2024-01-15 | -    │ │
│  │ john      | ✗     | 2024-01-02 | 2024-01-15 | [X]  │ │
│  │ jane      | ✗     | 2024-01-03 | 2024-01-14 | [X]  │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Features:**
- List all users
- Create new user (username, password, admin checkbox)
- Delete users (cannot delete self)
- Show last login timestamp

### 6.7 Progress Bar Implementation

**Problem:** Real progress is hard to track for compression and upload.

**Solution: Step-based Progress**

**Copy/Compress Worker Progress:**
```
Step 1/3: Copying... (0-33%)
├─ If copying size can be tracked: show actual percentage within 0-33%
└─ Otherwise: show indeterminate spinner or fixed 16%

Step 2/3: Compressing... (33-66%)
├─ 7z doesn't reliably report progress
└─ Show indeterminate spinner or fixed 50%

Step 3/3: Verifying... (66-100%)
├─ 7z test completes quickly
└─ Show indeterminate spinner or fixed 83%

Complete: 100%
```

**Upload Worker Progress:**
```
Uploading... (0-75%)
├─ Poll Globus task API for bytes_transferred
└─ Calculate: (bytes_transferred / total_bytes) * 75

Verifying... (75-90%)
├─ Triple verification steps
└─ Show indeterminate spinner or fixed 82%

Deleting source... (90-100%)
├─ Final cleanup
└─ Show indeterminate spinner or fixed 95%

Complete: 100%
```

**UI Implementation:**
- Use determinate progress bar when real progress available (copying, uploading)
- Use indeterminate/pulsing progress bar when no real progress (compressing, verifying)
- Show step indicator above progress bar: "Step 2/3: Compressing..."

---

## 7. Configuration & Environment

### 7.1 Environment Variables

```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost/cs_archiver
# or sqlite:///./cs_archiver.db

# JWT Authentication
JWT_SECRET_KEY=random_secret_key_here
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=1440  # 24 hours

# Storage Paths
QNAP_BASE_PATH=/mnt/qnap/CitySpace Tech Team
STORAGE_BASE_PATH=/storage
STORAGE_TEMP_PATH=/storage/temp
STORAGE_ARCHIVES_PATH=/storage/archives
STORAGE_FAILED_PATH=/storage/failed

# Globus Configuration
GLOBUS_CLIENT_ID=your_client_id
GLOBUS_CLIENT_SECRET=your_client_secret
GLOBUS_SOURCE_ENDPOINT=local_endpoint_uuid
GLOBUS_DESTINATION_ENDPOINT=destination_endpoint_uuid
GLOBUS_DESTINATION_BASE_PATH=/

# Worker Configuration
MAX_COMPRESSION_RETRIES=3
MAX_UPLOAD_RETRIES=5
MAX_CONNECTION_ERROR_RETRIES=10
RETRY_DELAY_SECONDS=30
UPLOAD_TASK_TIMEOUT_HOURS=12
UPLOAD_TASK_POLL_INTERVAL_SECONDS=60

# Disk Space
MIN_FREE_SPACE_GB=10.0
COMPRESSION_SIZE_ESTIMATE_RATIO=0.7

# Logging
LOG_LEVEL=INFO
LOG_FILE=/var/log/cs-archiver/app.log
```

### 7.2 Initial Setup

**Create Default Admin User:**
```python
# On first run, create default admin
username: admin
password: changeme  # Must change on first login
is_admin: True
```

**Database Migration:**
```bash
alembic upgrade head
```

**Start Workers:**
```bash
# Background worker process
python -m cs_archiver.workers
```

**Start API Server:**
```bash
uvicorn cs_archiver.main:app --host 0.0.0.0 --port 8000
```

---

## 8. Technology Stack Details

### 8.1 Backend Stack

**Core Framework:**
- **FastAPI** - Web framework
- **Uvicorn** - ASGI server
- **SQLAlchemy** - ORM
- **Alembic** - Database migrations
- **PostgreSQL** or **SQLite** - Database

**Authentication:**
- **python-jose[cryptography]** - JWT tokens
- **passlib[bcrypt]** - Password hashing

**Globus Integration:**
- **globus-sdk** - Globus Transfer API client

**System Utilities:**
- **psutil** - Disk space monitoring
- **subprocess** - Shell command execution (7z, rsync, dd)

**WebSocket:**
- **fastapi.WebSocket** - Real-time updates

### 8.2 Frontend Stack

**Core Framework:**
- **React 18+**
- **TypeScript**
- **Vite** - Build tool

**UI Library:**
- **Material-UI (MUI)** or **Ant Design** - Component library
- **React Router** - Routing

**State Management:**
- **TanStack Query (React Query)** - API state management
- **Zustand** or **Context API** - Client state

**WebSocket:**
- **native WebSocket API** or **Socket.io-client**

**HTTP Client:**
- **axios** or **fetch API**

**Progress Bars:**
- **MUI LinearProgress** or **Ant Design Progress**

---

## 9. Non-Functional Requirements

### 9.1 Performance

- Folder discovery scan: < 5 seconds for 1000 folders
- API response time: < 500ms (excluding long-running operations)
- WebSocket latency: < 1 second for updates
- Concurrent users: Support 10+ simultaneous users viewing UI

### 9.2 Reliability

- Jobs survive server restart (queue persisted to database)
- Failed operations retry automatically (up to configured limits)
- All state changes logged to database
- Crash recovery: Workers can resume interrupted jobs

### 9.3 Security

- All API endpoints require authentication (except /login and /health)
- Passwords hashed with bcrypt (12+ rounds)
- JWT tokens expire after 24 hours
- Admin actions restricted to admin users only
- All file operations validate paths (prevent path traversal)

### 9.4 Logging

- All job operations logged to database
- Worker errors logged to file and database
- Log levels: INFO, WARNING, ERROR
- Logs accessible via API and UI
- Log rotation (keep last 30 days or 1GB max)

### 9.5 Monitoring

- Health check endpoint: `GET /api/health`
- Disk space monitoring (warn at 20% free)
- Worker status tracking (idle vs busy)
- Failed job alerts (log and display in UI)

---

## 10. Future Enhancements (Out of Scope for v1)

- Email notifications on job completion/failure
- Bandwidth throttling for uploads
- Priority queue (high-priority jobs jump queue)
- Scheduled archiving (cron-like scheduling)
- Folder size pre-calculation before job creation
- Checkpoint-based resume for interrupted uploads
- Multi-tenant support (separate folder access per user)
- Prometheus metrics export
- Audit log (who archived what and when)
- Folder preview (show files inside before archiving)

---

## 11. Success Criteria

### 11.1 Functional Success

- ✅ User can browse folders from QNAP
- ✅ User can create archive job for a folder
- ✅ Job progresses through: Copy → Compress → Verify → Upload → Verify → Delete
- ✅ Source folder deleted only after successful verification
- ✅ Marker file created on QNAP after archiving
- ✅ Failed jobs can be manually retried
- ✅ Queue visible in UI with current operations
- ✅ Real-time progress updates via WebSocket
- ✅ Job logs accessible in UI
- ✅ Admin can manage users

### 11.2 Technical Success

- ✅ All core functionality from `wbur-archiver` migrated
- ✅ FastAPI backend with RESTful API + WebSocket
- ✅ React frontend with responsive UI
- ✅ Database-backed job queue (persistent)
- ✅ Triple verification before deletion
- ✅ Automatic retry with configurable limits
- ✅ Disk space management prevents job failures
- ✅ Authentication with JWT tokens
- ✅ Multi-user support (shared queue)

### 11.3 User Experience Success

- ✅ Intuitive folder browser
- ✅ Clear visual feedback on job progress
- ✅ Real-time updates without page refresh
- ✅ Easy job cancellation
- ✅ Clear error messages on failures
- ✅ Job history with filtering

---

## 12. Migration from wbur-archiver

### 12.1 Core Logic to Extract

**From `src/wbur/qnap/qnap.py`:**
- ✅ Folder discovery and filtering
- ✅ High-performance copy strategies (shutil, rsync, dd, parallel)
- ✅ Direct compression (7z command with options)
- ✅ Archive integrity verification (7z test)
- ✅ Source folder deletion with marker file

**From `src/wbur/glup/glup.py`:**
- ✅ Globus upload with checksum verification
- ✅ Task monitoring and polling
- ✅ Remote file existence check
- ✅ Triple verification logic

**From `src/wbur/workflow/`:**
- ✅ Queue architecture (two-stage: compress → upload)
- ✅ Worker thread pattern
- ✅ Job state management
- ✅ Error handling and retry logic

**From `src/wbur/utils/`:**
- ✅ Disk space checking
- ✅ File size formatting
- ✅ Progress monitoring

### 12.2 Changes from wbur-archiver

| Feature | wbur-archiver | cs-archiver (FastAPI) |
|---------|---------------|----------------------|
| UI | Terminal (TUI with Rich) | Web (React) |
| Queue | In-memory (threading.Queue) | Database-backed (persistent) |
| Copy Strategy | Direct compression OR copy first | Always copy first, then compress |
| Marker File | `.archived` | `{folder_name}-ARCHIVED-TO-GLOBUS.txt` |
| Authentication | None | JWT-based with user management |
| Multi-user | Single user | Multiple users (shared queue) |
| Job History | Not persisted | Database-backed history |
| Real-time Updates | Terminal refresh | WebSocket |
| Metadata Files | `.txt` with destination | Not needed (stored in DB) |
| Orphan Recovery | Automatic scanning | Not in v1 (future enhancement) |

---

## 13. Development Phases

### Phase 1: Backend Core (Week 1-2)
- Database schema and models
- Authentication (JWT, user management)
- Folder discovery API
- Job creation and queue management
- Basic worker implementation (no Globus yet)

### Phase 2: Worker Implementation (Week 3-4)
- Copy/Compress worker with retry logic
- Upload worker with Globus integration
- Triple verification implementation
- Disk space management
- Logging infrastructure

### Phase 3: Frontend Core (Week 5-6)
- Authentication UI (login)
- Folder browser page
- Queue & current jobs page
- Job history page
- Basic styling and layout

### Phase 4: Real-time Features (Week 7)
- WebSocket implementation
- Real-time progress updates
- Live log streaming
- Job cancellation

### Phase 5: Admin & Polish (Week 8)
- User management UI (admin only)
- Error handling and user feedback
- Progress bar refinements
- Documentation and deployment guide

### Phase 6: Testing & Deployment (Week 9-10)
- Integration testing
- Load testing (multiple concurrent jobs)
- Deployment setup (Docker, systemd)
- Production deployment

---

## Appendix A: Example Job Lifecycle

```
1. User browses /folders
2. User clicks "Archive" on "Project_Alpha"
3. POST /api/jobs creates job:
   - job_id: 123e4567-e89b-12d3-a456-426614174000
   - status: QUEUED
   - source_path: /mnt/qnap/CitySpace Tech Team/Production/2024/Project_Alpha
   - globus_destination_path: /Production/2024/Project_Alpha.tar.7z

4. Copy/Compress Worker picks up job:
   - status → COPYING
   - Copies to: /storage/temp/123e4567.../Project_Alpha/
   - progress: 0% → 33%

5. Copy complete:
   - status → COMPRESSING
   - Runs: 7z a -t7z -mx1 -mmt=on /storage/archives/Project_Alpha.tar.7z /storage/temp/.../Project_Alpha/
   - progress: 33% → 66%

6. Compression complete:
   - status → VERIFYING
   - Runs: 7z t /storage/archives/Project_Alpha.tar.7z
   - progress: 66% → 75%

7. Verification passed:
   - Deletes: /storage/temp/123e4567.../
   - Worker releases job

8. Upload Worker picks up job:
   - status → UPLOADING
   - Initiates Globus transfer
   - Polls task every 60s
   - progress: 75% → 85%

9. Upload complete:
   - status → UPLOAD_VERIFYING
   - Check 1: Task status = SUCCEEDED ✓
   - Check 2: File exists on Globus ✓
   - Check 3: Size match (within 1%) ✓
   - progress: 85% → 95%

10. All verifications passed:
    - status → DELETING_SOURCE
    - Deletes all files in: /mnt/qnap/.../Project_Alpha/
    - Creates: /mnt/qnap/.../Project_Alpha/Project_Alpha-ARCHIVED-TO-GLOBUS.txt
    - Deletes: /storage/archives/Project_Alpha.tar.7z
    - progress: 95% → 100%

11. Job complete:
    - status → COMPLETED
    - completed_at = now()
```

---

## Appendix B: Configuration File Example

```yaml
# config.yaml (optional, supplement to env vars)

database:
  url: "postgresql://user:pass@localhost/cs_archiver"
  pool_size: 10

storage:
  qnap_base: "/mnt/qnap/CitySpace Tech Team"
  local_base: "/storage"
  temp_subdir: "temp"
  archives_subdir: "archives"
  failed_subdir: "failed"

globus:
  client_id: "${GLOBUS_CLIENT_ID}"
  client_secret: "${GLOBUS_CLIENT_SECRET}"
  source_endpoint: "${GLOBUS_SOURCE_ENDPOINT}"
  destination_endpoint: "${GLOBUS_DESTINATION_ENDPOINT}"
  destination_base_path: "/"
  verify_checksum: true
  sync_level: "checksum"

workers:
  copy_compress:
    max_retries: 3
    retry_delay_seconds: 30
  upload:
    max_retries: 5
    retry_delay_seconds: 30
    connection_error_max_retries: 10
    task_timeout_hours: 12
    task_poll_interval_seconds: 60

disk_space:
  min_free_gb: 10.0
  compression_ratio_estimate: 0.7
  check_interval_seconds: 60

logging:
  level: "INFO"
  file: "/var/log/cs-archiver/app.log"
  max_bytes: 104857600  # 100MB
  backup_count: 5

security:
  jwt_secret_key: "${JWT_SECRET_KEY}"
  jwt_algorithm: "HS256"
  jwt_expiration_minutes: 1440
  bcrypt_rounds: 12
```

---

**END OF TECHNICAL PRD**
