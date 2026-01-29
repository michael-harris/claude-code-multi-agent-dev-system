# Backup and Recovery Guide

This guide covers backup procedures, recovery strategies, and disaster recovery for DevTeam state data.

## Table of Contents

1. [What Gets Backed Up](#what-gets-backed-up)
2. [Automatic Backups](#automatic-backups)
3. [Manual Backups](#manual-backups)
4. [Recovery Procedures](#recovery-procedures)
5. [Disaster Recovery](#disaster-recovery)
6. [Best Practices](#best-practices)

## What Gets Backed Up

### Critical Data

| Location | Contents | Criticality |
|----------|----------|-------------|
| `.devteam/devteam.db` | Session state, events, history | High |
| `.devteam/memory/` | Session-specific data | Medium |
| `.devteam/config.yaml` | Custom configuration | Medium |

### Not Backed Up

- Agent definitions (in version control)
- Plugin configuration (in version control)
- Temporary files

## Automatic Backups

### Using Maintenance Script

```bash
# Create a backup
./scripts/db-maintenance.sh backup

# Backups are stored in .devteam/backups/
# Format: devteam-YYYYMMDD-HHMMSS.db
```

### Scheduled Backups

Add to crontab for automatic backups:

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * cd /path/to/project && ./scripts/db-maintenance.sh backup
```

### Backup Rotation

By default, the maintenance script keeps the 5 most recent backups. Configure in `db-maintenance.sh`:

```bash
MAX_BACKUPS=5
```

## Manual Backups

### SQLite Backup Command

```bash
# Using SQLite's built-in backup (consistent snapshot)
sqlite3 .devteam/devteam.db ".backup '.devteam/backup.db'"
```

### File Copy

```bash
# Simple file copy (ensure no active writes)
cp .devteam/devteam.db .devteam/devteam.db.bak
```

### Export to SQL

```bash
# Export as SQL statements (portable)
sqlite3 .devteam/devteam.db ".dump" > devteam-backup.sql
```

### Full Directory Backup

```bash
# Backup entire .devteam directory
tar -czf devteam-backup-$(date +%Y%m%d).tar.gz .devteam/
```

## Recovery Procedures

### Restore from Backup

```bash
# 1. Stop any running DevTeam sessions
/devteam:reset

# 2. Backup current (corrupted) database
mv .devteam/devteam.db .devteam/devteam.db.corrupted

# 3. Restore from backup
cp .devteam/backups/devteam-YYYYMMDD-HHMMSS.db .devteam/devteam.db

# 4. Verify integrity
./scripts/db-maintenance.sh check

# 5. Resume operations
/devteam:status
```

### Restore from SQL Dump

```bash
# 1. Remove corrupted database
rm .devteam/devteam.db

# 2. Recreate from SQL
sqlite3 .devteam/devteam.db < devteam-backup.sql

# 3. Verify
./scripts/db-maintenance.sh check
```

### Partial Recovery

If only some tables are corrupted:

```bash
# 1. Attach backup to current database
sqlite3 .devteam/devteam.db

# In SQLite shell:
ATTACH '.devteam/backups/devteam-YYYYMMDD-HHMMSS.db' AS backup;

# Copy specific table
DELETE FROM sessions WHERE id = 'corrupted-session-id';
INSERT INTO sessions SELECT * FROM backup.sessions WHERE id = 'session-to-restore';

DETACH backup;
.quit
```

## Disaster Recovery

### Complete Database Loss

```bash
# 1. Reinitialize database
./scripts/db-init.sh

# 2. Database is now empty but functional
# 3. Historical data is lost (restore from backup if available)
```

### Corrupted Database

```bash
# 1. Check what's wrong
./scripts/db-maintenance.sh check

# 2. Try to recover
sqlite3 .devteam/devteam.db ".recover" > recovered.sql

# 3. Create new database from recovered data
rm .devteam/devteam.db
sqlite3 .devteam/devteam.db < recovered.sql
```

### Integrity Check Failure

```bash
# Option 1: Restore from backup
cp .devteam/backups/latest.db .devteam/devteam.db

# Option 2: Export what you can
sqlite3 .devteam/devteam.db ".dump" > partial-backup.sql

# Option 3: Start fresh
rm .devteam/devteam.db
./scripts/db-init.sh
```

## Recovery Scenarios

### Scenario 1: Accidental Session Deletion

```bash
# Restore specific session from backup
sqlite3 .devteam/devteam.db <<EOF
ATTACH '.devteam/backups/devteam-20260129-120000.db' AS backup;

INSERT OR REPLACE INTO sessions
SELECT * FROM backup.sessions
WHERE id = 'session-20260129-100000-abcd1234';

INSERT OR REPLACE INTO events
SELECT * FROM backup.events
WHERE session_id = 'session-20260129-100000-abcd1234';

DETACH backup;
EOF
```

### Scenario 2: Schema Migration Failed

```bash
# 1. Restore pre-migration backup
cp .devteam/backups/pre-migration.db .devteam/devteam.db

# 2. Check schema version
sqlite3 .devteam/devteam.db \
  "SELECT value FROM session_state WHERE key='schema_version';"

# 3. Rerun migration carefully
./scripts/db-init.sh
```

### Scenario 3: Disk Full

```bash
# 1. Free up space
./scripts/db-maintenance.sh cleanup  # Remove old sessions
./scripts/db-maintenance.sh vacuum   # Reclaim space

# 2. If still failing, move to larger disk
mv .devteam /path/to/larger/disk/
ln -s /path/to/larger/disk/.devteam .devteam
```

## Best Practices

### Backup Schedule

| Frequency | Type | Retention |
|-----------|------|-----------|
| Daily | Automatic | 7 days |
| Weekly | Manual | 4 weeks |
| Monthly | Archive | 1 year |

### Before Major Operations

Always backup before:
- Running migrations
- Bulk cleanup
- Schema changes
- Major DevTeam updates

```bash
# Quick pre-operation backup
./scripts/db-maintenance.sh backup
```

### Verification

Regularly verify backups are restorable:

```bash
# Test restore to temporary location
sqlite3 /tmp/test-restore.db < backup.sql
sqlite3 /tmp/test-restore.db "PRAGMA integrity_check;"
rm /tmp/test-restore.db
```

### Off-Site Backups

For critical projects, copy backups off-site:

```bash
# Copy to cloud storage
aws s3 cp .devteam/backups/ s3://my-bucket/devteam-backups/ --recursive

# Or use rsync
rsync -av .devteam/backups/ user@backup-server:/backups/devteam/
```

### Documentation

Keep a recovery log:

```markdown
# Recovery Log

## 2026-01-29: Restored session-20260128-*
- Cause: Accidental cleanup
- Backup used: devteam-20260128-230000.db
- Data lost: None
- Time to recover: 5 minutes
```

## Quick Reference

### Common Commands

```bash
# Create backup
./scripts/db-maintenance.sh backup

# Check integrity
./scripts/db-maintenance.sh check

# View recent backups
ls -la .devteam/backups/

# Restore latest backup
cp .devteam/backups/$(ls -t .devteam/backups/ | head -1) .devteam/devteam.db

# Full maintenance
./scripts/db-maintenance.sh all
```

### Emergency Contacts

If you encounter unrecoverable issues:
1. Check GitHub Issues for known problems
2. Open a new issue with:
   - Error messages
   - Steps to reproduce
   - Database size and age
   - Last successful operation
