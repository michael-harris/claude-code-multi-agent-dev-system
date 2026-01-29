# Responsive Design Skill

**Skill ID:** `frontend:responsive-design`
**Category:** Frontend
**Model:** `sonnet`

## Purpose

Create responsive, mobile-first designs that work across all device sizes. Implements fluid layouts, flexible images, and media queries for optimal user experience.

## Capabilities

### 1. Mobile-First Development
- Progressive enhancement
- Touch-friendly interfaces
- Performance optimization
- Offline considerations

### 2. Fluid Layouts
- CSS Grid systems
- Flexbox layouts
- Container queries
- Fluid typography

### 3. Responsive Images
- srcset and sizes
- Art direction with picture
- Lazy loading
- WebP/AVIF optimization

### 4. Breakpoint Strategy
- Device-agnostic breakpoints
- Content-driven breakpoints
- Feature detection
- Viewport units

## Activation Triggers

```yaml
triggers:
  keywords:
    - responsive
    - mobile-first
    - breakpoint
    - viewport
    - fluid
    - adaptive
    - media query

  task_types:
    - responsive_design
    - mobile_optimization
    - layout
```

## Process

### Step 1: Define Breakpoint Strategy

```css
/* Content-driven breakpoints */
:root {
    --bp-small: 320px;   /* Small phones */
    --bp-medium: 768px;  /* Tablets */
    --bp-large: 1024px;  /* Laptops */
    --bp-xlarge: 1440px; /* Desktops */
}

/* Mobile-first media queries */
@media (min-width: 768px) { /* Tablet and up */ }
@media (min-width: 1024px) { /* Laptop and up */ }
@media (min-width: 1440px) { /* Desktop */ }
```

### Step 2: Implement Fluid Typography

```css
/* Fluid typography with clamp */
:root {
    --font-size-sm: clamp(0.875rem, 0.8rem + 0.25vw, 1rem);
    --font-size-base: clamp(1rem, 0.9rem + 0.5vw, 1.125rem);
    --font-size-lg: clamp(1.25rem, 1rem + 1vw, 1.5rem);
    --font-size-xl: clamp(1.5rem, 1.2rem + 1.5vw, 2rem);
    --font-size-2xl: clamp(2rem, 1.5rem + 2.5vw, 3rem);
}

body {
    font-size: var(--font-size-base);
    line-height: 1.6;
}

h1 { font-size: var(--font-size-2xl); }
h2 { font-size: var(--font-size-xl); }
h3 { font-size: var(--font-size-lg); }
```

### Step 3: Create Responsive Grid

```css
/* CSS Grid with auto-fit */
.card-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 1.5rem;
}

/* Responsive sidebar layout */
.layout {
    display: grid;
    grid-template-columns: 1fr;
}

@media (min-width: 768px) {
    .layout {
        grid-template-columns: 250px 1fr;
    }
}

/* Container queries for components */
@container (min-width: 400px) {
    .card {
        display: flex;
        flex-direction: row;
    }
}
```

### Step 4: Responsive Images

```html
<!-- Responsive image with srcset -->
<img
    src="image-800.jpg"
    srcset="
        image-400.jpg 400w,
        image-800.jpg 800w,
        image-1200.jpg 1200w
    "
    sizes="
        (max-width: 600px) 100vw,
        (max-width: 1200px) 50vw,
        800px
    "
    alt="Description"
    loading="lazy"
>

<!-- Art direction with picture -->
<picture>
    <source
        media="(min-width: 1024px)"
        srcset="hero-desktop.webp"
        type="image/webp"
    >
    <source
        media="(min-width: 768px)"
        srcset="hero-tablet.webp"
        type="image/webp"
    >
    <img
        src="hero-mobile.jpg"
        alt="Hero image"
    >
</picture>
```

## Responsive Patterns

### Navigation
```css
/* Mobile: hamburger menu */
.nav {
    display: none;
}

.nav.open {
    display: flex;
    flex-direction: column;
    position: fixed;
    inset: 0;
    background: white;
}

/* Desktop: horizontal nav */
@media (min-width: 768px) {
    .nav {
        display: flex;
        flex-direction: row;
        position: static;
    }

    .hamburger {
        display: none;
    }
}
```

### Tables
```css
/* Responsive table */
@media (max-width: 600px) {
    table, thead, tbody, th, td, tr {
        display: block;
    }

    tr {
        margin-bottom: 1rem;
        border: 1px solid #ddd;
    }

    td {
        position: relative;
        padding-left: 50%;
    }

    td::before {
        content: attr(data-label);
        position: absolute;
        left: 0.5rem;
        font-weight: bold;
    }
}
```

### Touch Targets
```css
/* Minimum touch target size */
.button,
.link,
.interactive {
    min-height: 44px;
    min-width: 44px;
    padding: 0.75rem 1rem;
}

/* Adequate spacing for touch */
.nav-item + .nav-item {
    margin-top: 0.5rem;
}

@media (min-width: 768px) {
    .nav-item + .nav-item {
        margin-top: 0;
        margin-left: 1rem;
    }
}
```

## Output Format

```yaml
responsive_implementation:
  breakpoints:
    - name: "small"
      width: "320px"
      changes: ["Single column", "Stacked nav"]
    - name: "medium"
      width: "768px"
      changes: ["2-column grid", "Horizontal nav"]
    - name: "large"
      width: "1024px"
      changes: ["Sidebar visible", "Larger typography"]

  components_updated:
    - name: "Header"
      mobile: "Hamburger menu, logo centered"
      desktop: "Full nav, logo left"
    - name: "Card Grid"
      mobile: "Single column"
      desktop: "3-column auto-fit grid"

  images_optimized:
    - file: "hero.jpg"
      sizes: ["400w", "800w", "1200w"]
      formats: ["webp", "jpg"]

  performance:
    mobile_score: 95
    desktop_score: 98
```

## See Also

- `skills/frontend/accessibility-expert.md` - Accessible responsive design
- `skills/quality/performance-optimizer.md` - Performance optimization
- `agents/frontend/frontend-designer.md` - UI/UX design
