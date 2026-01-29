# Accessibility Expert Skill

**Skill ID:** `frontend:accessibility-expert`
**Category:** Frontend
**Model:** `sonnet`

## Purpose

Build accessible-first frontend components and interfaces. Ensures WCAG compliance from the start rather than retrofitting accessibility.

## Capabilities

### 1. Semantic HTML
- Proper element selection
- Document structure
- Landmark regions
- Meaningful headings

### 2. ARIA Implementation
- Proper role assignment
- State management
- Live regions
- Widget patterns

### 3. Keyboard Navigation
- Focus management
- Tab order
- Keyboard shortcuts
- Focus trapping

### 4. Assistive Technology
- Screen reader optimization
- Voice control support
- Switch device support
- Magnification support

## Activation Triggers

```yaml
triggers:
  keywords:
    - accessible
    - a11y
    - screen reader
    - keyboard
    - aria
    - wcag
    - semantic

  task_types:
    - frontend_development
    - component_creation
    - accessibility
```

## Process

### Step 1: Semantic Foundation

```html
<!-- Document structure -->
<body>
    <header role="banner">
        <nav role="navigation" aria-label="Main">
            <!-- Navigation items -->
        </nav>
    </header>

    <main role="main" id="main-content">
        <article>
            <h1>Page Title</h1>
            <!-- Content -->
        </article>
    </main>

    <aside role="complementary">
        <!-- Sidebar -->
    </aside>

    <footer role="contentinfo">
        <!-- Footer -->
    </footer>
</body>
```

### Step 2: Interactive Component Patterns

```jsx
// Accessible Button
function Button({ children, onClick, disabled, loading }) {
    return (
        <button
            onClick={onClick}
            disabled={disabled || loading}
            aria-disabled={disabled || loading}
            aria-busy={loading}
        >
            {loading && <span className="sr-only">Loading...</span>}
            {children}
        </button>
    )
}

// Accessible Modal
function Modal({ isOpen, onClose, title, children }) {
    const modalRef = useRef()

    // Focus trap
    useFocusTrap(modalRef, isOpen)

    // Close on Escape
    useEffect(() => {
        const handleEscape = (e) => {
            if (e.key === 'Escape') onClose()
        }
        if (isOpen) document.addEventListener('keydown', handleEscape)
        return () => document.removeEventListener('keydown', handleEscape)
    }, [isOpen, onClose])

    if (!isOpen) return null

    return (
        <div
            role="dialog"
            aria-modal="true"
            aria-labelledby="modal-title"
            ref={modalRef}
        >
            <h2 id="modal-title">{title}</h2>
            {children}
            <button onClick={onClose} aria-label="Close modal">
                &times;
            </button>
        </div>
    )
}

// Accessible Tabs
function Tabs({ tabs, activeTab, onChange }) {
    return (
        <div>
            <div role="tablist" aria-label="Content sections">
                {tabs.map((tab, index) => (
                    <button
                        key={tab.id}
                        role="tab"
                        id={`tab-${tab.id}`}
                        aria-selected={activeTab === tab.id}
                        aria-controls={`panel-${tab.id}`}
                        tabIndex={activeTab === tab.id ? 0 : -1}
                        onClick={() => onChange(tab.id)}
                        onKeyDown={(e) => handleTabKeyDown(e, index)}
                    >
                        {tab.label}
                    </button>
                ))}
            </div>

            {tabs.map((tab) => (
                <div
                    key={tab.id}
                    role="tabpanel"
                    id={`panel-${tab.id}`}
                    aria-labelledby={`tab-${tab.id}`}
                    hidden={activeTab !== tab.id}
                    tabIndex={0}
                >
                    {tab.content}
                </div>
            ))}
        </div>
    )
}
```

### Step 3: Form Accessibility

```jsx
function AccessibleForm() {
    return (
        <form aria-labelledby="form-title">
            <h2 id="form-title">Contact Us</h2>

            {/* Required field with validation */}
            <div>
                <label htmlFor="email">
                    Email Address
                    <span aria-hidden="true">*</span>
                </label>
                <input
                    type="email"
                    id="email"
                    name="email"
                    required
                    aria-required="true"
                    aria-describedby="email-hint email-error"
                    aria-invalid={hasError}
                />
                <span id="email-hint" className="hint">
                    We'll never share your email
                </span>
                {hasError && (
                    <span id="email-error" className="error" role="alert">
                        Please enter a valid email address
                    </span>
                )}
            </div>

            {/* Fieldset for related inputs */}
            <fieldset>
                <legend>Preferred contact method</legend>
                <label>
                    <input type="radio" name="contact" value="email" />
                    Email
                </label>
                <label>
                    <input type="radio" name="contact" value="phone" />
                    Phone
                </label>
            </fieldset>

            <button type="submit">Submit</button>
        </form>
    )
}
```

### Step 4: Dynamic Content

```jsx
// Live region for status updates
function StatusMessage({ message, type }) {
    return (
        <div
            role="status"
            aria-live="polite"
            aria-atomic="true"
            className={`status status--${type}`}
        >
            {message}
        </div>
    )
}

// Alert for important messages
function Alert({ message }) {
    return (
        <div role="alert" className="alert">
            {message}
        </div>
    )
}

// Progress indicator
function LoadingProgress({ current, total }) {
    const percentage = Math.round((current / total) * 100)

    return (
        <div
            role="progressbar"
            aria-valuenow={percentage}
            aria-valuemin={0}
            aria-valuemax={100}
            aria-label={`Loading: ${percentage}% complete`}
        >
            <div style={{ width: `${percentage}%` }} />
        </div>
    )
}
```

## Accessibility Utilities

```css
/* Screen reader only */
.sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border: 0;
}

/* Skip link */
.skip-link {
    position: absolute;
    top: -40px;
    left: 0;
    padding: 8px;
    background: #000;
    color: #fff;
    z-index: 100;
}

.skip-link:focus {
    top: 0;
}

/* Focus visible */
:focus-visible {
    outline: 2px solid #005fcc;
    outline-offset: 2px;
}

/* Reduced motion */
@media (prefers-reduced-motion: reduce) {
    *,
    *::before,
    *::after {
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
    }
}
```

## Output Format

```yaml
accessibility_implementation:
  components_created:
    - name: "Modal"
      features:
        - "Focus trap"
        - "Escape to close"
        - "aria-modal"
        - "aria-labelledby"

    - name: "Tabs"
      features:
        - "Arrow key navigation"
        - "Proper ARIA roles"
        - "Focus management"

  wcag_compliance:
    level_a: "100%"
    level_aa: "100%"

  testing_performed:
    - "VoiceOver (macOS)"
    - "NVDA (Windows)"
    - "Keyboard-only navigation"
    - "200% zoom"
```

## See Also

- `skills/quality/accessibility-checker.md` - Accessibility auditing
- `skills/testing/e2e-tester.md` - Automated a11y testing
- `agents/frontend/frontend-code-reviewer.md` - Accessibility code review
