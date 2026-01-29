# E2E Tester Skill

**Skill ID:** `testing:e2e-tester`
**Category:** Testing
**Model:** `sonnet`

## Purpose

Create end-to-end tests that verify complete user workflows from frontend to backend. Tests the entire application stack as a user would experience it.

## Capabilities

### 1. User Flow Testing
- Complete user journeys
- Multi-step workflows
- Cross-page navigation
- Session persistence

### 2. Browser Automation
- Playwright/Cypress test creation
- Cross-browser testing
- Mobile viewport testing
- Screenshot/video capture

### 3. Visual Regression
- Screenshot comparison
- Layout verification
- Responsive design testing
- Theme/style consistency

### 4. Performance Validation
- Page load times
- Interaction responsiveness
- Core Web Vitals
- Network waterfall analysis

## Activation Triggers

```yaml
triggers:
  keywords:
    - e2e test
    - end-to-end
    - playwright
    - cypress
    - browser test
    - user flow
    - journey test

  task_types:
    - e2e_testing
    - browser_testing
    - user_flow_testing
```

## Process

### Step 1: Identify User Journeys

```yaml
critical_user_journeys:
  - name: "New User Registration"
    steps:
      - Visit homepage
      - Click "Sign Up"
      - Fill registration form
      - Submit and verify email
      - Complete profile
      - Access dashboard

  - name: "Purchase Flow"
    steps:
      - Browse products
      - Add to cart
      - Proceed to checkout
      - Enter payment details
      - Confirm order
      - Receive confirmation
```

### Step 2: Set Up Test Infrastructure

```javascript
// playwright.config.ts
export default defineConfig({
    testDir: './tests/e2e',
    timeout: 30000,
    retries: 2,
    use: {
        baseURL: process.env.TEST_URL || 'http://localhost:3000',
        screenshot: 'only-on-failure',
        video: 'retain-on-failure',
        trace: 'retain-on-failure'
    },
    projects: [
        { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
        { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
        { name: 'mobile', use: { ...devices['iPhone 13'] } }
    ]
})
```

### Step 3: Create Page Objects

```javascript
// pages/LoginPage.ts
export class LoginPage {
    constructor(private page: Page) {}

    async goto() {
        await this.page.goto('/login')
    }

    async login(email: string, password: string) {
        await this.page.fill('[data-testid="email"]', email)
        await this.page.fill('[data-testid="password"]', password)
        await this.page.click('[data-testid="login-button"]')
        await this.page.waitForURL('/dashboard')
    }

    async expectError(message: string) {
        await expect(this.page.locator('.error-message')).toContainText(message)
    }
}
```

### Step 4: Write E2E Tests

```javascript
// tests/e2e/auth.spec.ts
import { test, expect } from '@playwright/test'
import { LoginPage } from '../pages/LoginPage'
import { DashboardPage } from '../pages/DashboardPage'

test.describe('Authentication Flow', () => {
    test('user can login and access dashboard', async ({ page }) => {
        const loginPage = new LoginPage(page)
        const dashboard = new DashboardPage(page)

        await loginPage.goto()
        await loginPage.login('user@example.com', 'password123')

        await expect(dashboard.welcomeMessage).toBeVisible()
        await expect(dashboard.welcomeMessage).toContainText('Welcome')
    })

    test('invalid credentials show error', async ({ page }) => {
        const loginPage = new LoginPage(page)

        await loginPage.goto()
        await loginPage.login('wrong@email.com', 'wrongpassword')

        await loginPage.expectError('Invalid credentials')
    })

    test('session persists across page refresh', async ({ page }) => {
        const loginPage = new LoginPage(page)
        const dashboard = new DashboardPage(page)

        await loginPage.goto()
        await loginPage.login('user@example.com', 'password123')

        await page.reload()

        // Should still be logged in
        await expect(dashboard.welcomeMessage).toBeVisible()
    })
})
```

## Test Patterns

### Visual Regression
```javascript
test('homepage matches snapshot', async ({ page }) => {
    await page.goto('/')
    await expect(page).toHaveScreenshot('homepage.png', {
        maxDiffPixels: 100
    })
})
```

### Mobile Responsive
```javascript
test.describe('Mobile Experience', () => {
    test.use({ viewport: { width: 375, height: 667 } })

    test('navigation menu collapses', async ({ page }) => {
        await page.goto('/')
        await expect(page.locator('.mobile-menu-button')).toBeVisible()
        await expect(page.locator('.desktop-nav')).toBeHidden()
    })
})
```

### Performance Validation
```javascript
test('page loads within performance budget', async ({ page }) => {
    await page.goto('/')

    const metrics = await page.evaluate(() => ({
        lcp: performance.getEntriesByName('largest-contentful-paint')[0]?.startTime,
        fid: performance.getEntriesByName('first-input')[0]?.processingStart,
        cls: performance.getEntriesByName('layout-shift').reduce((a, e) => a + e.value, 0)
    }))

    expect(metrics.lcp).toBeLessThan(2500) // LCP < 2.5s
    expect(metrics.cls).toBeLessThan(0.1)  // CLS < 0.1
})
```

## Output Format

```yaml
e2e_test_report:
  summary:
    tests_created: 24
    user_journeys_covered: 5
    pages_tested: 12

  coverage:
    critical_flows: "100% (5/5)"
    pages: "85% (12/14)"
    viewports: "desktop, tablet, mobile"
    browsers: "chromium, firefox, webkit"

  files_created:
    - tests/e2e/auth.spec.ts
    - tests/e2e/checkout.spec.ts
    - tests/pages/LoginPage.ts
    - tests/pages/DashboardPage.ts

  visual_baselines:
    - screenshots/homepage.png
    - screenshots/dashboard.png
```

## See Also

- `skills/testing/integration-tester.md` - API integration testing
- `skills/frontend/accessibility-expert.md` - Accessibility testing
- `agents/quality/test-writer.md` - Comprehensive test writing
