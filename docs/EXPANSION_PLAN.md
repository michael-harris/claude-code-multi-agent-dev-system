# Multi-Agent System Expansion Plan

> **Note:** This is a historical planning document. The T1/T2 tier system described here has been replaced with explicit model assignments (haiku/sonnet/opus) in agent YAML frontmatter and plugin.json. Escalation is now handled by orchestrator agents (task-loop, sprint-orchestrator) via LLM instructions, not by T1/T2 agent pairs.

**Date**: 2025-10-30
**Goal**: Expand from 27 to 66 agents covering top dev stacks and programming languages

---

## ULTRATHINK Analysis

### Current State
- **27 agents** supporting Python and TypeScript ecosystems
- **Coverage**: FastAPI, Django, Express, NestJS, React, Vue
- **Gaps**: Java, C#, Go, Ruby, PHP, utilities, mobile, DevOps

### Top 10 Development Stacks (2025 Market Analysis)

1. **Python Full-Stack** (Django/FastAPI + PostgreSQL + React) ✅ **COVERED**
2. **MERN/MEAN** (MongoDB + Express + React/Angular + Node.js) ✅ **COVERED**
3. **Spring Boot** (Java + PostgreSQL + React) ❌ **NEED JAVA**
4. **ASP.NET Core** (C# + SQL Server + React/Blazor) ❌ **NEED C#**
5. **Go Microservices** (Go + PostgreSQL + React) ❌ **NEED GO**
6. **Ruby on Rails** (Rails + PostgreSQL + React/Hotwire) ❌ **NEED RUBY**
7. **Laravel** (PHP + MySQL + Vue) ❌ **NEED PHP**
8. **Next.js Full-Stack** (TypeScript + Prisma + Next.js) ✅ **COVERED**
9. **Mobile Native** (Swift/Kotlin) ❌ **NEED MOBILE**
10. **Cloud Native** (Kubernetes + Terraform + CI/CD) ❌ **NEED DEVOPS**

### Top 5 Programming Languages Beyond Current

Based on TIOBE Index, Stack Overflow Survey, and GitHub trends:

1. **Java** - Enterprise standard, Spring Boot ecosystem
2. **C#** - Microsoft stack, .NET Core, Azure integration
3. **Go** - Modern microservices, cloud-native, performance
4. **Ruby** - Rapid development, Rails ecosystem
5. **PHP** - Still powering 77% of web (WordPress, Laravel)

---

## Expansion Design

### Phase 1: Backend Language Expansion (25 agents)

For each of 5 new languages, create:

#### Backend API Developers (10 agents)
- `backend:api-developer-java-t1` (Haiku) - Spring Boot REST APIs
- `backend:api-developer-java-t2` (Sonnet) - Complex Spring features
- `backend:api-developer-csharp-t1` (Haiku) - ASP.NET Core APIs
- `backend:api-developer-csharp-t2` (Sonnet) - Advanced .NET patterns
- `backend:api-developer-go-t1` (Haiku) - Gin/Fiber APIs
- `backend:api-developer-go-t2` (Sonnet) - Concurrent patterns
- `backend:api-developer-ruby-t1` (Haiku) - Rails controllers
- `backend:api-developer-ruby-t2` (Sonnet) - Rails advanced patterns
- `backend:api-developer-php-t1` (Haiku) - Laravel APIs
- `backend:api-developer-php-t2` (Sonnet) - Laravel advanced features

#### Database Developers (10 agents)
- `database:developer-java-t1` (Haiku) - JPA/Hibernate basics
- `database:developer-java-t2` (Sonnet) - Complex JPA queries
- `database:developer-csharp-t1` (Haiku) - Entity Framework basics
- `database:developer-csharp-t2` (Sonnet) - EF migrations & optimization
- `database:developer-go-t1` (Haiku) - GORM basics
- `database:developer-go-t2` (Sonnet) - Advanced GORM patterns
- `database:developer-ruby-t1` (Haiku) - ActiveRecord basics
- `database:developer-ruby-t2` (Sonnet) - Complex AR queries
- `database:developer-php-t1` (Haiku) - Eloquent basics
- `database:developer-php-t2` (Sonnet) - Eloquent advanced features

#### Code Reviewers (5 agents)
- `backend:code-reviewer-java` (Sonnet) - Spring Boot best practices
- `backend:code-reviewer-csharp` (Sonnet) - .NET Core best practices
- `backend:code-reviewer-go` (Sonnet) - Go idioms and patterns
- `backend:code-reviewer-ruby` (Sonnet) - Rails conventions
- `backend:code-reviewer-php` (Sonnet) - Laravel best practices

**Total: 25 agents for language expansion**

### Phase 2: Utility & Infrastructure Agents (14 agents)

#### Scripting Category (4 agents)
- `scripting:powershell-developer-t1` (Haiku) - Windows automation basics
- `scripting:powershell-developer-t2` (Sonnet) - Azure, DSC, advanced
- `scripting:shell-developer-t1` (Haiku) - Bash/Shell basics
- `scripting:shell-developer-t2` (Sonnet) - Complex shell patterns

#### DevOps Category (4 agents)
- `devops:docker-specialist` (Sonnet) - Dockerfiles, compose, optimization
- `devops:kubernetes-specialist` (Sonnet) - K8s manifests, Helm, operators
- `devops:cicd-specialist` (Sonnet) - GitHub Actions, GitLab CI, Jenkins
- `devops:terraform-specialist` (Sonnet) - IaC for AWS, Azure, GCP

#### Infrastructure Category (2 agents)
- `infrastructure:configuration-manager-t1` (Haiku) - env, YAML, JSON basics
- `infrastructure:configuration-manager-t2` (Sonnet) - Complex configs, secrets

#### Mobile Category (4 agents)
- `mobile:ios-developer-t1` (Haiku) - Swift/SwiftUI basics
- `mobile:ios-developer-t2` (Sonnet) - Complex iOS patterns
- `mobile:android-developer-t1` (Haiku) - Kotlin/Jetpack Compose basics
- `mobile:android-developer-t2` (Sonnet) - Complex Android patterns

**Total: 14 utility agents**

---

## Total Expansion

**Before**: 27 agents
**New Backend/Database**: 25 agents
**New Utilities**: 14 agents
**After**: 66 agents

---

## Agent Distribution by Model

### Before Expansion
- Opus: 6 agents (22%)
- Sonnet: 15 agents (56%)
- Haiku: 6 agents (22%)

### Current State (post-migration)
- Opus: 38 agents - Architecture, security, complex reasoning tasks
- Sonnet: 84 agents - Default for most development and review operations
- Haiku: 5 agents - Cost-optimized for straightforward tasks

**Cost optimization maintained**: Sonnet handles most work, opus for complex tasks, haiku for simple ones. Orchestrators escalate automatically (sonnet -> opus after 2 failures, opus -> Bug Council after 3 failures).

---

## Technology Stack Coverage

### Backend Frameworks
- ✅ Python: FastAPI, Django
- ✅ TypeScript: Express, NestJS
- ✅ Java: Spring Boot
- ✅ C#: ASP.NET Core
- ✅ Go: Gin, Fiber, Echo
- ✅ Ruby: Rails
- ✅ PHP: Laravel

### Database ORMs
- ✅ Python: SQLAlchemy
- ✅ TypeScript: Prisma, TypeORM
- ✅ Java: JPA, Hibernate
- ✅ C#: Entity Framework Core
- ✅ Go: GORM
- ✅ Ruby: ActiveRecord
- ✅ PHP: Eloquent

### Frontend Frameworks
- ✅ React, Vue, Next.js (existing)
- ✅ Angular (TypeScript developers can handle)
- ✅ Svelte (TypeScript developers can handle)

### Mobile Platforms
- ✅ iOS (Swift/SwiftUI)
- ✅ Android (Kotlin/Jetpack Compose)
- ✅ React Native (TypeScript developers)

### DevOps & Infrastructure
- ✅ Docker
- ✅ Kubernetes
- ✅ Terraform
- ✅ CI/CD (GitHub Actions, GitLab CI, Jenkins)
- ✅ Configuration management

### Scripting
- ✅ PowerShell (Windows, Azure)
- ✅ Bash/Shell (Linux, deployment)

---

## New Directory Structure

```
agents/
├── planning/ (3) - unchanged
├── orchestration/ (3) - unchanged
├── database/ (15) - 5 → 15 (+10 new languages)
│   ├── database-designer.md
│   ├── database-developer-python-t1/t2.md
│   ├── database-developer-typescript-t1/t2.md
│   ├── database-developer-java-t1/t2.md
│   ├── database-developer-csharp-t1/t2.md
│   ├── database-developer-go-t1/t2.md
│   ├── database-developer-ruby-t1/t2.md
│   └── database-developer-php-t1/t2.md
├── backend/ (17) - 7 → 17 (+10 new)
│   ├── api-designer.md
│   ├── api-developer-{python,typescript,java,csharp,go,ruby,php}-t1/t2.md
│   └── backend-code-reviewer-{python,typescript,java,csharp,go,ruby,php}.md
├── frontend/ (4) - unchanged
├── python/ (2) - unchanged
├── quality/ (3) - unchanged
├── scripting/ (4) - NEW CATEGORY
│   ├── powershell-developer-t1/t2.md
│   └── shell-developer-t1/t2.md
├── devops/ (4) - NEW CATEGORY
│   ├── docker-specialist.md
│   ├── kubernetes-specialist.md
│   ├── cicd-specialist.md
│   └── terraform-specialist.md
├── infrastructure/ (2) - NEW CATEGORY
│   └── configuration-manager-t1/t2.md
└── mobile/ (4) - NEW CATEGORY
    ├── ios-developer-t1/t2.md
    └── android-developer-t1/t2.md
```

---

## Implementation Phases

### Phase 1: Java Ecosystem (5 agents)
- Backend T1/T2
- Database T1/T2
- Reviewer

### Phase 2: C# Ecosystem (5 agents)
- Backend T1/T2
- Database T1/T2
- Reviewer

### Phase 3: Go Ecosystem (5 agents)
- Backend T1/T2
- Database T1/T2
- Reviewer

### Phase 4: Ruby Ecosystem (5 agents)
- Backend T1/T2
- Database T1/T2
- Reviewer

### Phase 5: PHP Ecosystem (5 agents)
- Backend T1/T2
- Database T1/T2
- Reviewer

### Phase 6: Scripting (4 agents)
- PowerShell T1/T2
- Shell T1/T2

### Phase 7: DevOps (4 agents)
- Docker, K8s, CI/CD, Terraform

### Phase 8: Infrastructure (2 agents)
- Configuration manager T1/T2

### Phase 9: Mobile (4 agents)
- iOS T1/T2
- Android T1/T2

---

## Documentation Updates Required

1. **README.md**:
   - Update agent count (27 → 66)
   - Add all new language support
   - Add utility agent descriptions
   - Update technology stack section
   - Update model distribution table

2. **plugin.json**:
   - Add all 39 new agent definitions
   - Update description (27 → 66 agents)
   - Update version (1.0.0 → 2.0.0)

3. **examples/**:
   - Add Java usage example
   - Add C# usage example
   - Add Go usage example
   - Add DevOps workflow example
   - Add mobile development example

4. **New Documentation**:
   - `docs/LANGUAGE_SUPPORT.md` - Detailed language guides
   - `docs/DEVOPS_GUIDE.md` - DevOps workflow guide
   - `docs/MOBILE_GUIDE.md` - Mobile development guide

---

## Quality Assurance

### For Each New Agent:
- ✅ Clear model specification (opus/sonnet/haiku)
- ✅ Tier designation where applicable (t1/t2)
- ✅ Framework-specific guidelines
- ✅ Best practices for that ecosystem
- ✅ Quality checks
- ✅ Output specifications
- ✅ Example use cases

### Testing Checklist:
- [ ] All 66 agents appear in plugin.json
- [ ] JSON validation passes
- [ ] All agent files exist
- [ ] README accurately describes all agents
- [ ] Examples cover major use cases
- [ ] Installation script works
- [ ] Agent namespace format correct

---

## Expected Impact

### Coverage Increase
- **Languages**: 2 → 7 (250% increase)
- **Total Agents**: 27 → 66 (144% increase)
- **Stack Support**: 3-4 → 10+ complete stacks

### Use Cases Enabled
- Enterprise Java applications
- Microsoft/.NET applications
- Cloud-native Go services
- Rapid Ruby prototypes
- PHP web applications
- Windows automation (PowerShell)
- Linux DevOps (Shell)
- Kubernetes deployments
- CI/CD pipelines
- iOS mobile apps
- Android mobile apps

### Cost Optimization
- Maintained 60-70% savings vs all-Opus
- T1/T2 escalation for all new languages
- Opus only for design (still 6 agents)

---

## Timeline Estimate

- **Planning & Design**: ✅ Complete
- **Implementation**: ~2-3 hours (39 agent files)
- **Documentation**: ~1 hour (README, examples)
- **Testing**: ~30 minutes
- **Commit & PR**: ~15 minutes

**Total**: ~4 hours for complete expansion

---

## Success Criteria

✅ 66 total agents (39 new)
✅ Support for Java, C#, Go, Ruby, PHP
✅ Full T1/T2 coverage for new languages
✅ DevOps/infrastructure agents
✅ Mobile development agents
✅ Scripting agents (PowerShell, Shell)
✅ All documentation updated
✅ Examples for new capabilities
✅ Valid plugin.json
✅ Successful PR merge

---

**Status**: Planning Complete - Ready for Implementation
**Next**: Begin Phase 1 (Java Ecosystem)
