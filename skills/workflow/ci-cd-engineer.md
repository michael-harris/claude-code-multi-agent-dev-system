# CI/CD Engineer Skill

Design and implement continuous integration and deployment pipelines.

## Activation

This skill activates when:
- Pipeline setup needed
- Deployment automation required
- Build optimization requested
- Release management needed

## GitHub Actions

### Basic Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [18, 20, 22]

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run tests
        run: npm test

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}

  build:
    needs: test
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: build
          path: dist/
```

### Deployment Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment: staging

    steps:
      - uses: actions/checkout@v4

      - name: Deploy to staging
        run: |
          echo "Deploying to staging..."
          # Deploy commands here

      - name: Run E2E tests
        run: npm run test:e2e

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production

    steps:
      - uses: actions/checkout@v4

      - name: Deploy to production
        run: |
          echo "Deploying to production..."
          # Deploy commands here
```

### Docker Build & Push

```yaml
# .github/workflows/docker.yml
name: Docker

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: myapp/myimage
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

## GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  NODE_VERSION: "20"

test:
  stage: test
  image: node:${NODE_VERSION}
  cache:
    paths:
      - node_modules/
  script:
    - npm ci
    - npm run lint
    - npm test
  coverage: '/Lines\s*:\s*(\d+\.\d+)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

build:
  stage: build
  image: node:${NODE_VERSION}
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week

deploy_staging:
  stage: deploy
  environment:
    name: staging
    url: https://staging.example.com
  script:
    - echo "Deploy to staging"
  only:
    - develop

deploy_production:
  stage: deploy
  environment:
    name: production
    url: https://example.com
  script:
    - echo "Deploy to production"
  only:
    - main
  when: manual
```

## Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any

    environment {
        NODE_VERSION = '20'
        DOCKER_REGISTRY = 'registry.example.com'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'npm run test:unit'
                    }
                }
                stage('Integration Tests') {
                    steps {
                        sh 'npm run test:integration'
                    }
                }
                stage('Lint') {
                    steps {
                        sh 'npm run lint'
                    }
                }
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    docker.build("${DOCKER_REGISTRY}/myapp:${env.BUILD_NUMBER}")
                }
            }
        }

        stage('Deploy Staging') {
            when {
                branch 'develop'
            }
            steps {
                sh './deploy.sh staging'
            }
        }

        stage('Deploy Production') {
            when {
                branch 'main'
            }
            input {
                message "Deploy to production?"
                ok "Deploy"
            }
            steps {
                sh './deploy.sh production'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        failure {
            slackSend channel: '#alerts', message: "Build failed: ${env.BUILD_URL}"
        }
    }
}
```

## Best Practices

### Caching

```yaml
# Node.js caching
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-

# Python caching
- uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
```

### Parallel Jobs

```yaml
jobs:
  test:
    strategy:
      fail-fast: false
      matrix:
        test-suite: [unit, integration, e2e]
    steps:
      - run: npm run test:${{ matrix.test-suite }}
```

### Environment Protection

```yaml
jobs:
  deploy:
    environment:
      name: production
      url: https://example.com
    # Requires manual approval and passes environment secrets
```

### Secrets Management

```yaml
steps:
  - name: Deploy
    env:
      API_KEY: ${{ secrets.API_KEY }}
      DATABASE_URL: ${{ secrets.DATABASE_URL }}
    run: ./deploy.sh
```

## Quality Checks

- [ ] Tests run on every PR
- [ ] Build artifacts cached
- [ ] Parallel jobs where possible
- [ ] Proper environment separation
- [ ] Secrets not exposed
- [ ] Notifications configured
- [ ] Rollback procedure documented
