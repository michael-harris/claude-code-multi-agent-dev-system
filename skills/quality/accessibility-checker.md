# Accessibility Checker Skill

**Skill ID:** `quality:accessibility-checker`
**Category:** Quality
**Model:** `sonnet`

## Purpose

Audit and improve web accessibility to ensure applications are usable by people with disabilities. Validates WCAG compliance and provides remediation guidance.

## Capabilities

### 1. WCAG Compliance Audit
- Level A requirements
- Level AA requirements
- Level AAA recommendations
- Section 508 compliance

### 2. Automated Testing
- axe-core integration
- Lighthouse accessibility audit
- pa11y automated checks
- WAVE tool analysis

### 3. Manual Audit Guidance
- Keyboard navigation testing
- Screen reader compatibility
- Color contrast verification
- Focus management review

### 4. Remediation
- Fix common issues
- Add ARIA attributes
- Improve semantic HTML
- Enhance focus indicators

## Activation Triggers

```yaml
triggers:
  keywords:
    - accessibility
    - a11y
    - wcag
    - aria
    - screen reader
    - keyboard navigation
    - color contrast

  task_types:
    - accessibility_audit
    - wcag_compliance
    - a11y_testing
```

## Process

### Step 1: Automated Audit

```javascript
// Run automated accessibility tests
const axeResults = await axe.run(document, {
    runOnly: ['wcag2a', 'wcag2aa', 'best-practice']
})

const lighthouseResults = await lighthouse(url, {
    onlyCategories: ['accessibility']
})

const issues = {
    critical: axeResults.violations.filter(v => v.impact === 'critical'),
    serious: axeResults.violations.filter(v => v.impact === 'serious'),
    moderate: axeResults.violations.filter(v => v.impact === 'moderate'),
    minor: axeResults.violations.filter(v => v.impact === 'minor')
}
```

### Step 2: Manual Audit Checklist

```yaml
manual_checks:
  keyboard_navigation:
    - All interactive elements are focusable
    - Focus order is logical
    - Focus is visible at all times
    - No keyboard traps
    - Skip links are provided

  screen_reader:
    - Page has meaningful title
    - Headings are properly nested
    - Images have alt text
    - Form fields have labels
    - Dynamic content announced

  visual:
    - Color contrast meets 4.5:1 minimum
    - Text is resizable to 200%
    - Content reflows at 320px
    - No information conveyed by color alone
```

### Step 3: Issue Categorization

```yaml
issue_categories:
  perceivable:
    - Missing alt text
    - Poor color contrast
    - Missing captions
    - No text alternatives

  operable:
    - Not keyboard accessible
    - No skip links
    - Insufficient time limits
    - Seizure-inducing content

  understandable:
    - Missing labels
    - Inconsistent navigation
    - No error identification
    - Missing instructions

  robust:
    - Invalid HTML
    - Missing ARIA attributes
    - Improper role usage
    - Name/role/value issues
```

### Step 4: Remediation

```javascript
// Fix missing alt text
// Before
<img src="hero.jpg">

// After
<img src="hero.jpg" alt="Team collaboration in modern office">

// Fix missing form labels
// Before
<input type="email" placeholder="Email">

// After
<label for="email">Email Address</label>
<input type="email" id="email" placeholder="Email">

// Fix color contrast
// Before
.text { color: #999; } // 2.8:1 contrast

// After
.text { color: #595959; } // 7:1 contrast

// Add skip link
<a href="#main-content" class="skip-link">
    Skip to main content
</a>

// Add ARIA for dynamic content
<div role="status" aria-live="polite" aria-atomic="true">
    {statusMessage}
</div>
```

## Common Fixes

### Missing Alt Text
```html
<!-- Decorative image -->
<img src="decoration.svg" alt="" role="presentation">

<!-- Informative image -->
<img src="chart.png" alt="Sales increased 25% from Q1 to Q2">

<!-- Linked image -->
<a href="/home"><img src="logo.png" alt="Company Name - Home"></a>
```

### Keyboard Accessibility
```javascript
// Make custom component keyboard accessible
<div
    role="button"
    tabindex="0"
    onClick={handleClick}
    onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
            handleClick()
        }
    }}
>
    Custom Button
</div>
```

### Focus Management
```css
/* Visible focus indicator */
:focus {
    outline: 2px solid #005fcc;
    outline-offset: 2px;
}

/* Focus visible for keyboard only */
:focus:not(:focus-visible) {
    outline: none;
}

:focus-visible {
    outline: 2px solid #005fcc;
    outline-offset: 2px;
}
```

## Output Format

```yaml
accessibility_report:
  summary:
    wcag_level: "AA"
    score: 87
    issues_found: 12
    issues_fixed: 10

  by_impact:
    critical: 0
    serious: 2
    moderate: 5
    minor: 5

  by_principle:
    perceivable: 4
    operable: 3
    understandable: 3
    robust: 2

  fixes_applied:
    - "Added alt text to 15 images"
    - "Fixed color contrast on 3 elements"
    - "Added skip link to header"
    - "Added ARIA labels to 8 form fields"

  remaining_issues:
    - issue: "Video missing captions"
      location: "/about"
      wcag: "1.2.2"
      recommendation: "Add closed captions to video content"
```

## See Also

- `skills/frontend/accessibility-expert.md` - Accessibility-first development
- `skills/testing/e2e-tester.md` - Automated accessibility testing
- `agents/frontend/frontend-code-reviewer.md` - Accessibility in code review
