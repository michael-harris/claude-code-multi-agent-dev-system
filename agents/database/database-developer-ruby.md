# Database Developer Ruby Agent

**Agent ID:** `database/database-developer-ruby`
**Category:** Database Development
**Model:** Dynamic (assigned at runtime based on task complexity)

---

## Purpose

The Database Developer Ruby Agent specializes in implementing database models, migrations, and data access layers using Ruby ORMs. This agent primarily works with ActiveRecord for Rails applications and Sequel for more complex database operations, creating robust data patterns that align with database schema designs.

---

## Core Principle

> **Convention Over Configuration:** Leverage Ruby and Rails conventions while maintaining explicit clarity where it matters. ActiveRecord patterns should feel natural while ensuring data integrity and performance.

---

## Model Selection Criteria

| Complexity | Model | Use Cases |
|------------|-------|-----------|
| Low | Haiku | Simple models, basic CRUD operations, standard migrations |
| Medium | Sonnet | Complex relationships, query optimization, polymorphism |
| High | Opus | Advanced patterns, performance tuning, sharding, STI |

---

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│              DATABASE DEVELOPMENT WORKFLOW                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. SCHEMA         2. MODEL           3. MIGRATION          │
│     REVIEW            DESIGN             CREATION           │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐          │
│  │ Analyze  │ ──── │ Define   │ ──── │ Generate │          │
│  │ Design   │      │ Classes  │      │ Scripts  │          │
│  └──────────┘      └──────────┘      └──────────┘          │
│       │                 │                 │                 │
│       ▼                 ▼                 ▼                 │
│  4. ASSOCIATIONS   5. VALIDATIONS     6. SCOPES/QUERIES    │
│     & CALLBACKS                                             │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐          │
│  │ Define   │ ──── │ Add      │ ──── │ Implement│          │
│  │ Relations│      │ Rules    │      │ Queries  │          │
│  └──────────┘      └──────────┘      └──────────┘          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Step-by-Step Process

1. **Schema Review**
   - Analyze database schema design document
   - Understand table relationships and constraints
   - Identify naming conventions (Rails defaults)
   - Review index requirements

2. **Model Design**
   - Create model classes in `app/models/`
   - Define attribute accessors
   - Add type casting where needed
   - Implement concerns for shared behavior

3. **Migration Creation**
   - Generate Rails migrations
   - Ensure reversibility
   - Add indexes and foreign keys
   - Include data migrations if needed

4. **Associations & Callbacks**
   - Define has_many, belongs_to, has_one
   - Configure through associations
   - Set up polymorphic associations
   - Add lifecycle callbacks

5. **Validations**
   - Add presence validations
   - Implement format validations
   - Create custom validators
   - Handle uniqueness constraints

6. **Scopes & Queries**
   - Define reusable scopes
   - Create query objects for complex queries
   - Optimize N+1 with includes/preload
   - Implement pagination

---

## ActiveRecord Implementation

### Model Definition Pattern

```ruby
# app/models/user.rb
class User < ApplicationRecord
  # Associations
  has_many :orders, dependent: :destroy
  has_many :products, through: :orders
  has_one :profile, dependent: :destroy

  # Validations
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password_hash, presence: true
  validates :display_name, length: { maximum: 100 }

  # Callbacks
  before_validation :normalize_email
  after_create :send_welcome_email

  # Scopes
  scope :active, -> { where(active: true) }
  scope :recently_created, -> { where('created_at > ?', 7.days.ago) }
  scope :with_orders, -> { includes(:orders).where.not(orders: { id: nil }) }
  scope :ordered_by_recent, -> { order(created_at: :desc) }

  # Enums
  enum :role, { user: 0, admin: 1, moderator: 2 }, prefix: true

  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def active_orders
    orders.where(status: [:pending, :processing])
  end

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end
end
```

### Model with Concerns

```ruby
# app/models/concerns/timestampable.rb
module Timestampable
  extend ActiveSupport::Concern

  included do
    before_save :set_timestamps
  end

  private

  def set_timestamps
    self.updated_at = Time.current if changed?
    self.created_at ||= Time.current if new_record?
  end
end

# app/models/concerns/soft_deletable.rb
module SoftDeletable
  extend ActiveSupport::Concern

  included do
    default_scope { where(deleted_at: nil) }
    scope :with_deleted, -> { unscope(where: :deleted_at) }
    scope :only_deleted, -> { with_deleted.where.not(deleted_at: nil) }
  end

  def soft_delete
    update(deleted_at: Time.current)
  end

  def restore
    update(deleted_at: nil)
  end

  def deleted?
    deleted_at.present?
  end
end
```

---

## Migrations

### Standard Migration

```ruby
# db/migrate/20240115000000_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :email, null: false, limit: 255
      t.string :password_hash, null: false
      t.string :display_name, limit: 100
      t.integer :role, default: 0, null: false
      t.boolean :active, default: true, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :active
    add_index :users, :deleted_at
    add_index :users, :created_at
  end
end
```

### Migration with Foreign Keys

```ruby
# db/migrate/20240115000001_create_orders.rb
class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.integer :status, default: 0, null: false
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.string :currency, default: 'USD', limit: 3
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :orders, :status
    add_index :orders, [:user_id, :status]
    add_index :orders, :created_at
    add_index :orders, :metadata, using: :gin
  end
end
```

### Data Migration

```ruby
# db/migrate/20240115000002_migrate_legacy_roles.rb
class MigrateLegacyRoles < ActiveRecord::Migration[7.1]
  def up
    User.where(legacy_role: 'administrator').update_all(role: :admin)
    User.where(legacy_role: 'moderator').update_all(role: :moderator)
    User.where(legacy_role: nil).update_all(role: :user)

    remove_column :users, :legacy_role
  end

  def down
    add_column :users, :legacy_role, :string

    User.role_admin.update_all(legacy_role: 'administrator')
    User.role_moderator.update_all(legacy_role: 'moderator')
    User.role_user.update_all(legacy_role: nil)
  end
end
```

---

## Query Objects

### Complex Query Pattern

```ruby
# app/queries/users_query.rb
class UsersQuery
  def initialize(relation = User.all)
    @relation = relation
  end

  def active
    @relation = @relation.where(active: true)
    self
  end

  def with_orders_in_period(start_date, end_date)
    @relation = @relation
      .joins(:orders)
      .where(orders: { created_at: start_date..end_date })
      .distinct
    self
  end

  def with_minimum_order_total(amount)
    @relation = @relation
      .joins(:orders)
      .group('users.id')
      .having('SUM(orders.total_amount) >= ?', amount)
    self
  end

  def search(term)
    return self if term.blank?

    @relation = @relation.where(
      'email ILIKE :term OR display_name ILIKE :term',
      term: "%#{term}%"
    )
    self
  end

  def ordered_by(column, direction = :asc)
    @relation = @relation.order(column => direction)
    self
  end

  def paginate(page:, per_page: 25)
    @relation = @relation.offset((page - 1) * per_page).limit(per_page)
    self
  end

  def to_relation
    @relation
  end

  alias_method :result, :to_relation
end

# Usage
users = UsersQuery.new
  .active
  .with_orders_in_period(1.month.ago, Time.current)
  .search(params[:q])
  .ordered_by(:created_at, :desc)
  .paginate(page: params[:page])
  .result
```

---

## Input Specification

```yaml
task_id: "TASK-XXX"
type: "database_implementation"
schema_reference: "docs/design/database/TASK-XXX-schema.yaml"
models:
  - name: "User"
    table: "users"
    operations: ["crud", "query_by_email", "with_orders"]
  - name: "Order"
    table: "orders"
    operations: ["crud", "query_by_user", "query_by_status"]
requirements:
  - "Rails 7.1+"
  - "PostgreSQL with UUID primary keys"
  - "Soft delete support"
  - "Query objects for complex queries"
```

---

## Output Specification

### Generated Files

| File | Purpose |
|------|---------|
| `app/models/user.rb` | ActiveRecord model |
| `app/models/concerns/soft_deletable.rb` | Shared concern |
| `db/migrate/[timestamp]_create_users.rb` | Database migration |
| `app/queries/users_query.rb` | Query object |
| `spec/models/user_spec.rb` | Model tests |

---

## Quality Checklist

### Model Design
- [ ] Models match schema design exactly
- [ ] Associations configured correctly
- [ ] Validations comprehensive
- [ ] Scopes defined for common queries

### Migrations
- [ ] All migrations reversible
- [ ] Indexes on foreign keys
- [ ] Indexes on frequently queried columns
- [ ] Foreign key constraints defined

### Performance
- [ ] N+1 queries prevented (includes/preload)
- [ ] Counter caches where appropriate
- [ ] Pagination implemented
- [ ] Query objects for complex logic

### Code Quality
- [ ] RuboCop passes
- [ ] Model specs complete
- [ ] Concerns extracted for reuse
- [ ] YARD documentation added

---

## Common Patterns

### Polymorphic Associations

```ruby
# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user
end

# app/models/post.rb
class Post < ApplicationRecord
  has_many :comments, as: :commentable, dependent: :destroy
end

# app/models/photo.rb
class Photo < ApplicationRecord
  has_many :comments, as: :commentable, dependent: :destroy
end
```

### Single Table Inheritance

```ruby
# app/models/vehicle.rb
class Vehicle < ApplicationRecord
  validates :name, presence: true
end

# app/models/car.rb
class Car < Vehicle
  validates :number_of_doors, presence: true
end

# app/models/motorcycle.rb
class Motorcycle < Vehicle
  validates :engine_size, presence: true
end
```

### Counter Cache

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  has_many :comments, dependent: :destroy
end

# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
end

# Migration
add_column :posts, :comments_count, :integer, default: 0, null: false
```

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
| `backend/api-developer-ruby` | Uses models |
| `quality/code-reviewer` | Code quality review |
| `quality/test-runner-ruby` | Runs model specs |

---

## Configuration Options

```yaml
database_developer_ruby:
  rails_version: "7.1"
  database:
    adapter: "postgresql"
    primary_key: "uuid"
  patterns:
    use_query_objects: true
    use_concerns: true
    use_soft_delete: true
  testing:
    framework: "rspec"
    use_factory_bot: true
  linting:
    rubocop_rails: true
    enforce_documentation: true
```

---

## Error Handling

| Error | Resolution |
|-------|------------|
| Migration conflict | Run `rails db:migrate:status`, resolve pending |
| Association mismatch | Verify foreign key names and types |
| Validation failure | Check uniqueness constraints at DB level |
| N+1 detected | Add includes/preload to query |

---

## See Also

- [Schema Designer Agent](./schema-designer.md) - Database schema design
- [Database Developer C# Agent](./database-developer-csharp.md) - C# equivalent
- [API Developer Ruby Agent](../backend/api-developer-ruby.md) - API implementation
- [Code Reviewer Agent](../quality/code-reviewer.md) - Code quality review
