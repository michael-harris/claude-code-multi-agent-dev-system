# Multi-Language Development Examples

This document showcases the expanded capabilities of the multi-agent dev system with examples across all 7 supported programming languages, mobile platforms, and DevOps tools.

---

## Example 1: Java Spring Boot Microservice

**Scenario**: Build a high-performance order processing microservice using Java and Spring Boot.

### Step 1: Design Database Schema

```javascript
Task(
  subagent_type="multi-agent:database:designer",
  model="opus",
  prompt="Design a database schema for an order processing system with orders, order_items, products, customers, and payments. Include proper indexes for high-read scenarios."
)
```

### Step 2: Implement with JPA/Hibernate (T1 attempt)

```javascript
Task(
  subagent_type="multi-agent:database:developer-java-t1",
  model="haiku",
  prompt="Implement the order processing schema using JPA/Hibernate with Spring Data repositories. Create entities with proper relationships and Flyway migrations."
)
```

### Step 3: Design REST API

```javascript
Task(
  subagent_type="multi-agent:backend:api-designer",
  model="opus",
  prompt="Design a RESTful API for order processing with endpoints for creating orders, listing orders, payment processing, and order status updates. Include OpenAPI specification."
)
```

### Step 4: Implement Spring Boot Controllers (T1 attempt)

```javascript
Task(
  subagent_type="multi-agent:backend:api-developer-java-t1",
  model="haiku",
  prompt="Implement the order processing API using Spring Boot with @RestController, service layer, and proper exception handling."
)
```

### Step 5: Code Review

```javascript
Task(
  subagent_type="multi-agent:backend:code-reviewer-java",
  model="sonnet",
  prompt="Review the Spring Boot implementation for best practices, security issues (SQL injection, authentication), performance optimizations, and proper exception handling."
)
```

**Result**: Production-ready Java microservice with proper architecture, security, and performance optimizations.

---

## Example 2: C# ASP.NET Core API

**Scenario**: Build a .NET Core API for a SaaS application with multi-tenancy support.

### Implementation

```javascript
// Design schema
Task(
  subagent_type="multi-agent:database:designer",
  model="opus",
  prompt="Design multi-tenant database schema for SaaS app with tenants, users, subscriptions, and features table."
)

// Implement with Entity Framework Core (T2 for multi-tenancy complexity)
Task(
  subagent_type="multi-agent:database:developer-csharp-t2",
  model="sonnet",
  prompt="Implement multi-tenant schema using EF Core with query filters for tenant isolation, migrations, and audit trails."
)

// Design API with tenant routing
Task(
  subagent_type="multi-agent:backend:api-designer",
  model="opus",
  prompt="Design multi-tenant API with tenant identification via subdomain or header, authentication with JWT, and tenant-scoped data access."
)

// Implement ASP.NET Core API (T2 for multi-tenancy)
Task(
  subagent_type="multi-agent:backend:api-developer-csharp-t2",
  model="sonnet",
  prompt="Implement multi-tenant API using ASP.NET Core with middleware for tenant resolution, scoped DbContext, and MediatR for CQRS pattern."
)

// Security audit
Task(
  subagent_type="multi-agent:quality:security-auditor",
  model="opus",
  prompt="Audit multi-tenant implementation for tenant isolation, authentication/authorization, and OWASP Top 10 vulnerabilities."
)
```

**Result**: Enterprise-grade multi-tenant SaaS API with proper isolation and security.

---

## Example 3: Go Microservice with High Concurrency

**Scenario**: Build a real-time notification service that handles thousands of concurrent WebSocket connections.

### Implementation

```javascript
// Database design
Task(
  subagent_type="multi-agent:database:designer",
  model="opus",
  prompt="Design schema for notification service with users, notifications, subscriptions, and delivery_status for tracking."
)

// Implement GORM models (T1 for basic schema)
Task(
  subagent_type="multi-agent:database:developer-go-t1",
  model="haiku",
  prompt="Implement notification schema using GORM v2 with PostgreSQL, including migrations and repository pattern."
)

// Design WebSocket API
Task(
  subagent_type="multi-agent:backend:api-designer",
  model="opus",
  prompt="Design WebSocket-based notification API with REST endpoints for sending notifications, subscription management, and health checks."
)

// Implement with Gin + goroutines (T2 for concurrency)
Task(
  subagent_type="multi-agent:backend:api-developer-go-t2",
  model="sonnet",
  prompt="Implement notification service using Gin framework with WebSocket handler, goroutine worker pools for message fanout, Redis pub/sub for horizontal scaling, and proper graceful shutdown."
)
```

**Result**: High-performance Go microservice handling thousands of concurrent connections.

---

## Example 4: Ruby on Rails API

**Scenario**: Rapidly prototype a content management API using Rails conventions.

### Implementation

```javascript
// Database design
Task(
  subagent_type="multi-agent:database:designer",
  model="opus",
  prompt="Design CMS schema with articles, authors, categories, tags (many-to-many), comments, and media attachments."
)

// Implement ActiveRecord models (T1 for standard Rails patterns)
Task(
  subagent_type="multi-agent:database:developer-ruby-t1",
  model="haiku",
  prompt="Implement CMS schema using ActiveRecord with Rails migrations, associations, validations, and scopes."
)

// Implement Rails controllers (T1 for standard CRUD)
Task(
  subagent_type="multi-agent:backend:api-developer-ruby-t1",
  model="haiku",
  prompt="Implement RESTful Rails API controllers for CMS with strong parameters, serializers, pagination, and filtering."
)

// Add background jobs (T2 for Sidekiq integration)
Task(
  subagent_type="multi-agent:backend:api-developer-ruby-t2",
  model="sonnet",
  prompt="Add Sidekiq background jobs for article publishing workflow, email notifications, and image processing with ActiveStorage."
)
```

**Result**: Rapid Rails prototype leveraging conventions for quick development.

---

## Example 5: PHP Laravel Application

**Scenario**: Build a Laravel e-commerce API with Laravel-specific features.

### Implementation

```javascript
// Database design
Task(
  subagent_type="multi-agent:database:designer",
  model="opus",
  prompt="Design e-commerce schema with products, variants, inventory, orders, payments, and shopping carts."
)

// Implement Eloquent models (T2 for polymorphic relations)
Task(
  subagent_type="multi-agent:database:developer-php-t2",
  model="sonnet",
  prompt="Implement e-commerce schema using Eloquent with polymorphic relationships for product variants, Laravel migrations, and query scopes."
)

// Implement Laravel API (T2 for payment integration)
Task(
  subagent_type="multi-agent:backend:api-developer-php-t2",
  model="sonnet",
  prompt="Implement e-commerce API using Laravel with Form Requests, API Resources, Sanctum authentication, payment gateway integration (Stripe), and Laravel Queue for order processing."
)
```

**Result**: Complete Laravel e-commerce API with modern Laravel features.

---

## Example 6: iOS Native App

**Scenario**: Build a native iOS app for a task management application.

### Step 1: Design API (Backend)

```javascript
Task(
  subagent_type="multi-agent:backend:api-designer",
  model="opus",
  prompt="Design mobile-optimized REST API for task management with endpoints for CRUD operations, offline sync, and real-time updates."
)
```

### Step 2: Implement Backend (Choose your language)

```javascript
// Option: Go for performance
Task(
  subagent_type="multi-agent:backend:api-developer-go-t1",
  model="haiku",
  prompt="Implement task management API using Go and Gin with JWT authentication, pagination, and proper error responses for mobile clients."
)
```

### Step 3: Implement iOS App (T1 for basic UI)

```javascript
Task(
  subagent_type="multi-agent:mobile:ios-developer-t1",
  model="haiku",
  prompt="Create SwiftUI iOS app for task management with list view, detail view, add/edit forms, and Core Data for offline storage. Implement REST API integration with URLSession."
)
```

### Step 4: Add Advanced Features (T2)

```javascript
Task(
  subagent_type="multi-agent:mobile:ios-developer-t2",
  model="sonnet",
  prompt="Enhance iOS app with CloudKit sync, home screen widget, push notifications, and advanced SwiftUI animations for task completion."
)
```

**Result**: Production-ready iOS app with offline support and cloud sync.

---

## Example 7: Android Native App

**Scenario**: Build a native Android app for social networking.

### Implementation

```javascript
// Design mobile API
Task(
  subagent_type="multi-agent:backend:api-designer",
  model="opus",
  prompt="Design social networking API with posts, comments, likes, following, and feed generation optimized for mobile pagination."
)

// Implement Android app (T2 for complex features)
Task(
  subagent_type="multi-agent:mobile:android-developer-t2",
  model="sonnet",
  prompt="Create Android app using Kotlin and Jetpack Compose with feed UI (lazy loading), camera integration for posts, Room database for offline caching, WorkManager for background sync, and Firebase Cloud Messaging for notifications."
)
```

**Result**: Modern Android app with Material Design 3 and production features.

---

## Example 8: DevOps Pipeline for Multi-Language Project

**Scenario**: Set up complete CI/CD pipeline for a polyglot microservices project (Java backend, TypeScript frontend, Go workers).

### Step 1: Dockerize Services

```javascript
Task(
  subagent_type="multi-agent:devops:docker-specialist",
  model="sonnet",
  prompt="Create Dockerfiles for Java Spring Boot service (multi-stage with Maven), TypeScript Next.js frontend (with Node.js), and Go worker service. Include docker-compose for local development."
)
```

### Step 2: Create Kubernetes Manifests

```javascript
Task(
  subagent_type="multi-agent:devops:kubernetes-specialist",
  model="sonnet",
  prompt="Create Kubernetes manifests for 3-service microservices architecture with Deployments, Services, Ingress, ConfigMaps for env-specific config, Secrets for database credentials, and HorizontalPodAutoscaler."
)
```

### Step 3: Setup CI/CD Pipeline

```javascript
Task(
  subagent_type="multi-agent:devops:cicd-specialist",
  model="sonnet",
  prompt="Create GitHub Actions workflow for multi-language monorepo with separate jobs for Java (Maven test + build), TypeScript (npm test + build), and Go (go test + build). Include Docker image building, security scanning with Trivy, and deployment to Kubernetes cluster."
)
```

### Step 4: Infrastructure as Code

```javascript
Task(
  subagent_type="multi-agent:devops:terraform-specialist",
  model="sonnet",
  prompt="Create Terraform configuration for AWS infrastructure including EKS cluster, RDS PostgreSQL database, ElastiCache Redis, Application Load Balancer, and VPC with proper security groups."
)
```

**Result**: Complete production infrastructure with automated deployments.

---

## Example 9: Configuration Management

**Scenario**: Manage configuration across multiple environments with secrets management.

### Basic Configuration (T1)

```javascript
Task(
  subagent_type="multi-agent:infrastructure:configuration-manager-t1",
  model="haiku",
  prompt="Create environment-specific configuration files (.env, YAML) for dev, staging, and production with database URLs, API keys placeholders, and feature flags."
)
```

### Advanced with Secrets (T2)

```javascript
Task(
  subagent_type="multi-agent:infrastructure:configuration-manager-t2",
  model="sonnet",
  prompt="Implement secrets management using HashiCorp Vault with configuration templates, dynamic secrets for database credentials, JSON Schema validation for configs, and Kubernetes ConfigMaps/Secrets generation."
)
```

**Result**: Secure, validated configuration management across environments.

---

## Example 10: Automation Scripts

**Scenario**: Create deployment and maintenance scripts for various platforms.

### PowerShell for Azure

```javascript
Task(
  subagent_type="multi-agent:scripting:powershell-developer-t2",
  model="sonnet",
  prompt="Create PowerShell script for automated Azure App Service deployment with blue-green deployment strategy, health checks, automatic rollback on failure, and Slack notifications."
)
```

### Bash for Linux Servers

```javascript
Task(
  subagent_type="multi-agent:scripting:shell-developer-t2",
  model="sonnet",
  prompt="Create Bash script for multi-server deployment using parallel SSH execution, health checks, rolling updates with zero downtime, and automated database migration."
)
```

**Result**: Production-grade automation scripts for both Windows and Linux.

---

## Full-Stack Polyglot Example

**Scenario**: Build a complete e-commerce platform using multiple languages for optimal performance.

### Architecture
- **Backend API**: Go (for high performance)
- **Admin Panel API**: Python FastAPI (for rapid development)
- **Payment Service**: Java Spring Boot (for enterprise integration)
- **Frontend**: TypeScript Next.js
- **Mobile Apps**: iOS (Swift) + Android (Kotlin)
- **Background Jobs**: Ruby (for quick scripting)
- **Infrastructure**: Terraform + Kubernetes
- **CI/CD**: GitHub Actions

### Workflow

```bash
# 1. Interactive planning (creates PRD, tasks, and sprints)
/devteam:plan "Build an e-commerce platform with web and mobile apps"
# System breaks down into tasks, identifies optimal languages per component

# 2. Autonomous execution
/devteam:auto
# Or execute specific sprint: /devteam:sprint SPRINT-001
# Orchestrator automatically routes tasks to appropriate language agents
```

### Example Task Routing

**Task**: Implement product catalog API
```javascript
// Orchestrator routes to Go T1 for performance
Task(
  subagent_type="multi-agent:backend:api-developer-go-t1",
  model="haiku",
  prompt="Implement product catalog API with search, filtering, pagination..."
)
```

**Task**: Implement admin dashboard API
```javascript
// Orchestrator routes to Python T1 for rapid development
Task(
  subagent_type="multi-agent:backend:api-developer-python-t1",
  model="haiku",
  prompt="Implement admin API for product management..."
)
```

**Task**: Implement payment processing
```javascript
// Orchestrator routes to Java T2 for enterprise patterns
Task(
  subagent_type="multi-agent:backend:api-developer-java-t2",
  model="sonnet",
  prompt="Implement payment processing with Stripe integration, webhook handling..."
)
```

**Result**: Optimized polyglot architecture using the best language for each component.

---

## Tips for Multi-Language Projects

1. **Language Selection**: Use `/devteam:plan` to specify language preferences based on:
   - Team expertise
   - Performance requirements
   - Integration needs
   - Development speed priorities

2. **T1/T2 Strategy**:
   - Start with T1 for straightforward features
   - Let validation automatically escalate to T2
   - Use T2 directly for complex features (multi-tenancy, high concurrency, etc.)

3. **Code Review**: Always use language-specific reviewers:
   - `backend:code-reviewer-java`
   - `backend:code-reviewer-csharp`
   - `backend:code-reviewer-go`
   - `backend:code-reviewer-ruby`
   - `backend:code-reviewer-php`

4. **DevOps**: Use specialists for production-grade infrastructure:
   - `devops:docker-specialist` for optimized containers
   - `devops:kubernetes-specialist` for orchestration
   - `devops:cicd-specialist` for pipelines
   - `devops:terraform-specialist` for infrastructure

5. **Mobile**: Leverage T1/T2 for complexity:
   - T1 for standard CRUD mobile apps
   - T2 for complex features (camera, sensors, background sync, widgets)

---

## Language-Specific Best Practices

### Java
- Use Spring Boot for enterprise features
- JPA/Hibernate for ORM with proper lazy loading
- JUnit 5 + Mockito for testing
- Flyway for migrations

### C#
- ASP.NET Core for modern APIs
- Entity Framework Core for ORM
- xUnit for testing
- EF migrations

### Go
- Gin/Echo for performance
- GORM for ORM with proper indexing
- goroutines for concurrency
- golang-migrate for migrations

### Ruby
- Rails for rapid development
- ActiveRecord for ORM
- RSpec for testing
- Rails migrations

### PHP
- Laravel for modern PHP
- Eloquent for ORM
- PHPUnit/Pest for testing
- Laravel migrations

---

**All examples follow the same quality standards**: security audits, code review, testing, and iterative T1→T2 escalation when needed.
