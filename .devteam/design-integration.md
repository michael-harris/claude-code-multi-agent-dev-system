# Design System Integration with DevTeam Workflow

This document describes how UX design agents integrate with the DevTeam workflow to automatically generate design systems before frontend implementation.

## Trigger Detection

The Task Loop detects when design system generation is needed:

```yaml
design_triggers:
  # Explicit triggers
  explicit_keywords:
    - "design system"
    - "ui design"
    - "visual design"
    - "branding"
    - "style guide"

  # Implicit triggers (frontend without existing design)
  implicit_conditions:
    - frontend_task: true
      existing_design_system: false

    - project_type: ["landing page", "website", "web app", "mobile app"]
      design_system_dir_exists: false

    - files_to_create:
        patterns: ["*.tsx", "*.vue", "*.svelte", "*.css", "*.scss"]
      no_design_tokens: true

  # Project types that always need design
  always_design_first:
    - landing_page
    - marketing_site
    - consumer_app
    - e-commerce
    - portfolio
```

## Complete Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER REQUEST                                  │
│  "Build a landing page for my beauty spa with booking"          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      TASK LOOP                                   │
│  1. Parse request                                                │
│  2. Detect: frontend + no design system = DESIGN FIRST          │
│  3. Extract: industry=beauty/spa, type=landing+booking          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│            PHASE 1: DESIGN SYSTEM GENERATION                     │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         Design System Orchestrator                        │   │
│  │         Coordinates 5 parallel searches                   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│         ┌────────────────────┼────────────────────┐             │
│         │                    │                    │             │
│         ▼                    ▼                    ▼             │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│  │ Industry UX │     │ UI Style    │     │ Color       │       │
│  │ Consultant  │     │ Curator     │     │ Palette     │       │
│  │             │     │             │     │ Specialist  │       │
│  │ → Beauty/   │     │ → Soft UI   │     │ → Spa       │       │
│  │   Wellness  │     │   Minimal   │     │   palette   │       │
│  │   rules     │     │   Organic   │     │   calming   │       │
│  └─────────────┘     └─────────────┘     └─────────────┘       │
│         │                    │                    │             │
│         └────────────────────┼────────────────────┘             │
│                              │                                   │
│         ┌────────────────────┼────────────────────┐             │
│         │                    │                    │             │
│         ▼                    ▼                    ▼             │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│  │ Typography  │     │ Component   │     │ Landing     │       │
│  │ Specialist  │     │ Architect   │     │ Page        │       │
│  │             │     │             │     │ Patterns    │       │
│  │ → Elegant   │     │ → Booking   │     │ → Social    │       │
│  │   readable  │     │   card,     │     │   proof +   │       │
│  │   pairing   │     │   forms     │     │   booking   │       │
│  └─────────────┘     └─────────────┘     └─────────────┘       │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              DESIGN SYSTEM OUTPUT                         │   │
│  │  design-system/                                           │   │
│  │  ├── MASTER.md         (global tokens & rules)           │   │
│  │  ├── tokens/colors.json                                   │   │
│  │  ├── tokens/typography.json                               │   │
│  │  ├── components/booking-card.md                           │   │
│  │  └── tailwind.config.js                                   │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│            PHASE 2: IMPLEMENTATION                               │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         Frontend Developer                                │   │
│  │         (receives design system)                          │   │
│  │                                                           │   │
│  │  Inputs:                                                  │   │
│  │  - design-system/MASTER.md                               │   │
│  │  - design-system/tokens/*                                │   │
│  │  - Component specifications                               │   │
│  │                                                           │   │
│  │  Creates:                                                 │   │
│  │  - src/components/BookingCard.tsx                        │   │
│  │  - src/pages/LandingPage.tsx                             │   │
│  │  - src/styles/theme.ts                                   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         Accessibility Specialist                          │   │
│  │         (reviews implementation)                          │   │
│  │                                                           │   │
│  │  Checks:                                                  │   │
│  │  - Color contrast ratios                                  │   │
│  │  - Keyboard navigation                                    │   │
│  │  - Screen reader compatibility                            │   │
│  │  - Focus states                                           │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│            PHASE 3: TASK LOOP QUALITY LOOP                       │
│                                                                  │
│  Quality Gates:                                                  │
│  ✓ Design tokens applied correctly                              │
│  ✓ Components match specifications                               │
│  ✓ Accessibility audit passed                                    │
│  ✓ Responsive breakpoints work                                   │
│  ✓ Pre-delivery checklist complete                              │
└─────────────────────────────────────────────────────────────────┘
```

## Agent Selection Updates

Add to `.devteam/agent-capabilities.yaml`:

```yaml
categories:
  ux_design:
    description: "UI/UX design system generation"
    agents:
      - id: design_system_orchestrator
        capabilities:
          - design_system_generation
          - style_coordination
          - component_specification
        triggers:
          keywords: [design system, ui design, visual design, branding]
          task_types: [design, frontend_new]
          conditions:
            - frontend_task AND no_existing_design

      - id: ui_style_curator
        capabilities:
          - style_selection
          - visual_direction
        complexity_range: [3, 8]
        parent: design_system_orchestrator

      - id: color_palette_specialist
        capabilities:
          - color_system
          - industry_palettes
          - accessibility_colors
        complexity_range: [2, 6]
        parent: design_system_orchestrator

      - id: typography_specialist
        capabilities:
          - font_pairing
          - type_scale
          - readability
        complexity_range: [2, 6]
        parent: design_system_orchestrator

      - id: data_visualization_designer
        capabilities:
          - chart_design
          - dashboard_layout
          - data_storytelling
        triggers:
          keywords: [dashboard, analytics, charts, data visualization]
        complexity_range: [4, 10]

      - id: industry_ux_consultant
        capabilities:
          - industry_rules
          - ux_patterns
          - anti_patterns
        complexity_range: [3, 8]
        parent: design_system_orchestrator
```

## Task Loop Integration

```yaml
# In task decomposition
frontend_task_flow:
  check_design_system:
    condition: "is_frontend_task AND NOT design_system_exists"
    action: "prepend_design_phase"

  design_phase:
    agents:
      - design_system_orchestrator
    outputs:
      - design-system/MASTER.md
      - design-system/tokens/*.json
    must_complete_before:
      - frontend_developer
      - api_developer_*

  implementation_phase:
    agents:
      - frontend_developer
    inputs:
      - design-system/*
    scope:
      must_use:
        - design_system_tokens
        - component_specifications
```

## Design System Handoff Protocol

```yaml
handoff_to_frontend:
  files_provided:
    - path: "design-system/MASTER.md"
      contains: "Global rules, anti-patterns"

    - path: "design-system/tokens/colors.json"
      contains: "Complete color system"

    - path: "design-system/tokens/typography.json"
      contains: "Font families, scale, weights"

    - path: "design-system/tokens/spacing.json"
      contains: "Spacing scale (4px base)"

    - path: "design-system/tailwind.config.js"
      contains: "Ready-to-use Tailwind extension"

  frontend_developer_must:
    - Read MASTER.md first
    - Import tokens into project
    - Follow component specifications
    - Not deviate from color palette
    - Use defined typography scale
    - Apply spacing system consistently

  validation:
    - Accessibility Specialist reviews colors
    - Design System Orchestrator validates implementation
```

## Pre-Delivery Checklist Integration

Add to Task Loop quality gates:

```yaml
quality_gates:
  design_compliance:
    enabled: true
    when: "design_system_exists"

    checks:
      - name: "color_tokens_used"
        verify: "No hardcoded colors outside design system"

      - name: "typography_scale_followed"
        verify: "Font sizes match design system scale"

      - name: "spacing_consistent"
        verify: "Spacing uses design system values"

      - name: "component_specs_matched"
        verify: "Components match design specifications"

      - name: "accessibility_passed"
        verify: "Contrast ratios, focus states, ARIA"

      - name: "responsive_breakpoints"
        verify: "375px, 768px, 1024px, 1440px"

    on_failure:
      action: create_fix_task
      assign: frontend_developer
```

## Example: Complete Flow

### User Request
```
/devteam:implement "Create a landing page for my beauty spa with online booking"
```

### Phase 1: Design (Auto-triggered)

```yaml
design_system_generated:
  style: "Soft UI Evolution + Organic Biophilic"

  colors:
    primary: "#7C3AED"      # Calming purple
    secondary: "#10B981"    # Nature green
    accent: "#F59E0B"       # Warm amber
    background: "#FDF4FF"   # Soft lavender

  typography:
    heading: "Cormorant Garamond"
    body: "Lato"

  components_specified:
    - hero_section
    - service_cards
    - booking_form
    - testimonials
    - gallery
    - footer

  industry_rules_applied:
    - "Calming color palette for relaxation"
    - "Large imagery of spa environment"
    - "Easy booking flow (3 steps max)"
    - "Social proof near booking CTA"
```

### Phase 2: Implementation

Frontend developer receives design system and creates:
- `src/components/Hero.tsx` (using design tokens)
- `src/components/ServiceCard.tsx` (matching spec)
- `src/components/BookingForm.tsx` (3-step flow)
- `tailwind.config.js` (extended with tokens)

### Phase 3: Quality Loop

Task Loop validates:
- ✅ Colors match design system
- ✅ Typography scale followed
- ✅ Booking flow is 3 steps
- ✅ Accessibility passes (4.5:1 contrast)
- ✅ Mobile responsive (375px works)

### Final Output

Complete, production-ready landing page with:
- Consistent design system
- Accessibility compliant
- Industry-appropriate UX
- Responsive across devices
