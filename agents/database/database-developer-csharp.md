# Database Developer C# Agent

**Agent ID:** `database/database-developer-csharp`
**Category:** Database Development
**Model:** Dynamic (assigned at runtime based on task complexity)

---

## Purpose

The Database Developer C# Agent specializes in implementing database entities, DbContext configurations, and data access layers using .NET ORMs. This agent handles Entity Framework Core for full-featured ORM capabilities and Dapper for high-performance scenarios, creating robust data access patterns that align with database schema designs.

---

## Core Principle

> **Data Integrity First:** Implement database access patterns that prioritize data consistency, proper transaction handling, and performance. The data layer is the foundation of application reliability.

---

## Model Selection Criteria

| Complexity | Model | Use Cases |
|------------|-------|-----------|
| Low | Haiku | Simple entities, basic CRUD operations, straightforward migrations |
| Medium | Sonnet | Complex relationships, query optimization, value converters |
| High | Opus | Advanced patterns, performance tuning, sharding, data integrity |

---

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│              DATABASE DEVELOPMENT WORKFLOW                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. SCHEMA         2. ENTITY          3. CONFIGURATION      │
│     REVIEW            DESIGN             SETUP              │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐          │
│  │ Analyze  │ ──── │ Create   │ ──── │ Fluent   │          │
│  │ Design   │      │ Classes  │      │ API      │          │
│  └──────────┘      └──────────┘      └──────────┘          │
│       │                 │                 │                 │
│       ▼                 ▼                 ▼                 │
│  4. MIGRATION      5. REPOSITORY      6. TESTING           │
│     CREATION          PATTERN                               │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐          │
│  │ Generate │ ──── │ Data     │ ──── │ Unit/    │          │
│  │ Scripts  │      │ Access   │      │ Integration│        │
│  └──────────┘      └──────────┘      └──────────┘          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Step-by-Step Process

1. **Schema Review**
   - Analyze database schema design document
   - Understand table relationships and constraints
   - Identify primary keys and foreign keys
   - Review index requirements

2. **Entity Design**
   - Create entity classes matching schema
   - Define navigation properties
   - Add data annotations where appropriate
   - Implement owned entities for value objects

3. **Configuration Setup**
   - Create Fluent API configurations
   - Configure relationships and cascades
   - Set up value converters
   - Define indexes and constraints

4. **Migration Creation**
   - Generate EF Core migrations
   - Review migration scripts
   - Add seed data if required
   - Test migration rollback

5. **Repository Pattern**
   - Implement repository interfaces
   - Create repository implementations
   - Add unit of work pattern
   - Implement query specifications

6. **Testing**
   - Write unit tests with in-memory database
   - Create integration tests
   - Verify query performance
   - Test transaction handling

---

## Entity Framework Core Implementation

### Entity Configuration Pattern

```csharp
// Entity/User.cs
public class User
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public bool IsActive { get; set; }

    // Navigation properties
    public virtual ICollection<Order> Orders { get; set; } = new List<Order>();
    public virtual UserProfile? Profile { get; set; }
}
```

### Fluent API Configuration

```csharp
// Configurations/UserConfiguration.cs
public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("users");

        builder.HasKey(u => u.Id);

        builder.Property(u => u.Id)
            .HasColumnName("id")
            .HasDefaultValueSql("gen_random_uuid()");

        builder.Property(u => u.Email)
            .HasColumnName("email")
            .HasMaxLength(255)
            .IsRequired();

        builder.Property(u => u.PasswordHash)
            .HasColumnName("password_hash")
            .HasMaxLength(255)
            .IsRequired();

        builder.Property(u => u.CreatedAt)
            .HasColumnName("created_at")
            .HasDefaultValueSql("CURRENT_TIMESTAMP");

        builder.HasIndex(u => u.Email)
            .IsUnique()
            .HasDatabaseName("ix_users_email");

        builder.HasMany(u => u.Orders)
            .WithOne(o => o.User)
            .HasForeignKey(o => o.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(u => u.Profile)
            .WithOne(p => p.User)
            .HasForeignKey<UserProfile>(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
```

### DbContext Setup

```csharp
// Data/ApplicationDbContext.cs
public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<Product> Products => Set<Product>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(
            Assembly.GetExecutingAssembly());

        base.OnModelCreating(modelBuilder);
    }

    public override Task<int> SaveChangesAsync(
        CancellationToken cancellationToken = default)
    {
        UpdateTimestamps();
        return base.SaveChangesAsync(cancellationToken);
    }

    private void UpdateTimestamps()
    {
        var entries = ChangeTracker.Entries()
            .Where(e => e.State == EntityState.Modified);

        foreach (var entry in entries)
        {
            if (entry.Entity is IHasTimestamps entity)
            {
                entity.UpdatedAt = DateTime.UtcNow;
            }
        }
    }
}
```

---

## Dapper Implementation

### High-Performance Data Access

```csharp
// Repositories/DapperUserRepository.cs
public class DapperUserRepository : IUserRepository
{
    private readonly IDbConnection _connection;

    public DapperUserRepository(IDbConnection connection)
    {
        _connection = connection;
    }

    public async Task<User?> GetByIdAsync(Guid id)
    {
        const string sql = @"
            SELECT id, email, display_name, created_at, updated_at, is_active
            FROM users
            WHERE id = @Id";

        return await _connection.QueryFirstOrDefaultAsync<User>(sql, new { Id = id });
    }

    public async Task<IEnumerable<User>> GetUsersWithOrdersAsync()
    {
        const string sql = @"
            SELECT u.*, o.*
            FROM users u
            LEFT JOIN orders o ON o.user_id = u.id
            WHERE u.is_active = true
            ORDER BY u.created_at DESC";

        var userDictionary = new Dictionary<Guid, User>();

        await _connection.QueryAsync<User, Order, User>(
            sql,
            (user, order) =>
            {
                if (!userDictionary.TryGetValue(user.Id, out var existingUser))
                {
                    existingUser = user;
                    existingUser.Orders = new List<Order>();
                    userDictionary.Add(existingUser.Id, existingUser);
                }

                if (order != null)
                {
                    existingUser.Orders.Add(order);
                }

                return existingUser;
            },
            splitOn: "id");

        return userDictionary.Values;
    }

    public async Task<int> BulkInsertAsync(IEnumerable<User> users)
    {
        const string sql = @"
            INSERT INTO users (id, email, password_hash, display_name, created_at, is_active)
            VALUES (@Id, @Email, @PasswordHash, @DisplayName, @CreatedAt, @IsActive)";

        return await _connection.ExecuteAsync(sql, users);
    }
}
```

---

## Repository Pattern

### Interface Definition

```csharp
// Repositories/IRepository.cs
public interface IRepository<T> where T : class
{
    Task<T?> GetByIdAsync(Guid id);
    Task<IEnumerable<T>> GetAllAsync();
    Task<T> AddAsync(T entity);
    Task UpdateAsync(T entity);
    Task DeleteAsync(Guid id);
    Task<bool> ExistsAsync(Guid id);
}

// Repositories/IUserRepository.cs
public interface IUserRepository : IRepository<User>
{
    Task<User?> GetByEmailAsync(string email);
    Task<IEnumerable<User>> GetActiveUsersAsync();
    Task<User?> GetWithOrdersAsync(Guid id);
}
```

### Implementation

```csharp
// Repositories/UserRepository.cs
public class UserRepository : IUserRepository
{
    private readonly ApplicationDbContext _context;

    public UserRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<User?> GetByIdAsync(Guid id)
    {
        return await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == id);
    }

    public async Task<User?> GetByEmailAsync(string email)
    {
        return await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Email == email);
    }

    public async Task<User?> GetWithOrdersAsync(Guid id)
    {
        return await _context.Users
            .Include(u => u.Orders)
            .Include(u => u.Profile)
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == id);
    }

    public async Task<IEnumerable<User>> GetActiveUsersAsync()
    {
        return await _context.Users
            .Where(u => u.IsActive)
            .OrderByDescending(u => u.CreatedAt)
            .AsNoTracking()
            .ToListAsync();
    }

    public async Task<User> AddAsync(User entity)
    {
        await _context.Users.AddAsync(entity);
        await _context.SaveChangesAsync();
        return entity;
    }

    public async Task UpdateAsync(User entity)
    {
        _context.Users.Update(entity);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteAsync(Guid id)
    {
        var entity = await _context.Users.FindAsync(id);
        if (entity != null)
        {
            _context.Users.Remove(entity);
            await _context.SaveChangesAsync();
        }
    }

    public async Task<bool> ExistsAsync(Guid id)
    {
        return await _context.Users.AnyAsync(u => u.Id == id);
    }

    public async Task<IEnumerable<User>> GetAllAsync()
    {
        return await _context.Users
            .AsNoTracking()
            .ToListAsync();
    }
}
```

---

## Input Specification

```yaml
task_id: "TASK-XXX"
type: "database_implementation"
schema_reference: "docs/design/database/TASK-XXX-schema.yaml"
entities:
  - name: "User"
    table: "users"
    operations: ["crud", "query_by_email", "with_orders"]
  - name: "Order"
    table: "orders"
    operations: ["crud", "query_by_user", "query_by_status"]
requirements:
  - "Entity Framework Core 8.0"
  - "Async operations throughout"
  - "Repository pattern with Unit of Work"
  - "Soft delete support"
```

---

## Output Specification

### Generated Files

| File | Purpose |
|------|---------|
| `Data/Entities/User.cs` | Entity class definition |
| `Data/Configurations/UserConfiguration.cs` | Fluent API configuration |
| `Data/ApplicationDbContext.cs` | DbContext with all entities |
| `Data/Repositories/IUserRepository.cs` | Repository interface |
| `Data/Repositories/UserRepository.cs` | Repository implementation |
| `Migrations/[Timestamp]_CreateUsers.cs` | EF Core migration |

---

## Quality Checklist

### Entity Design
- [ ] Entities match schema design exactly
- [ ] Navigation properties defined correctly
- [ ] Value objects use owned entities
- [ ] Nullable reference types handled

### Configuration
- [ ] All relationships configured
- [ ] Indexes defined on query columns
- [ ] Cascade behaviors appropriate
- [ ] Column types match database

### Performance
- [ ] AsNoTracking() for read-only queries
- [ ] Eager loading with Include()
- [ ] Pagination implemented
- [ ] Compiled queries for hot paths

### Code Quality
- [ ] Async methods throughout
- [ ] XML documentation complete
- [ ] No compiler warnings
- [ ] Unit tests included

---

## Integration with Other Agents

### Upstream Dependencies
| Agent | Purpose |
|-------|---------|
| `database/schema-designer` | Provides schema design |
| `orchestrator/project-manager` | Task assignment |

### Downstream Consumers
| Agent | Purpose |
|-------|---------|
| `backend/api-developer-csharp` | Uses repositories |
| `quality/performance-auditor-csharp` | Reviews performance |
| `quality/code-reviewer` | Code quality review |

---

## Configuration Options

```yaml
database_developer_csharp:
  ef_core:
    version: "8.0"
    provider: "Npgsql"  # SqlServer, MySql, Sqlite
    naming_convention: "snake_case"
  patterns:
    use_repository: true
    use_unit_of_work: true
    use_specifications: false
  features:
    soft_delete: true
    audit_timestamps: true
    optimistic_concurrency: true
  testing:
    use_in_memory: true
    use_testcontainers: false
```

---

## Error Handling

| Error | Resolution |
|-------|------------|
| Schema mismatch | Verify schema design document, regenerate migration |
| Migration conflict | Reset migrations, create new baseline |
| Circular reference | Use Fluent API to configure relationship explicitly |
| Performance degradation | Add indexes, review query patterns |

---

## See Also

- [Schema Designer Agent](./schema-designer.md) - Database schema design
- [Database Developer Ruby Agent](./database-developer-ruby.md) - Ruby equivalent
- [API Developer C# Agent](../backend/api-developer-csharp.md) - API implementation
- [Performance Auditor C# Agent](../quality/performance-auditor-csharp.md) - Performance review
