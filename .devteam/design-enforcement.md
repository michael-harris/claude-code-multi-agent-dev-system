# Design System Enforcement

This system ensures that once a design system exists, ALL frontend implementations honor it throughout the entire development lifecycle.

## Enforcement Layers

```
┌─────────────────────────────────────────────────────────────────┐
│              DESIGN SYSTEM ENFORCEMENT STACK                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Layer 1: DETECTION                                              │
│  ├── Scan for design-system/ directory                          │
│  ├── Check for MASTER.md, tokens/*.json                         │
│  └── Load design context into all frontend tasks                │
│                                                                  │
│  Layer 2: INJECTION                                              │
│  ├── Prepend design system to frontend agent prompts            │
│  ├── Include token values in scope definition                   │
│  └── Add "must use design tokens" to agent rules                │
│                                                                  │
│  Layer 3: VALIDATION                                             │
│  ├── Static analysis of generated code                          │
│  ├── Check for hardcoded colors/fonts/spacing                   │
│  └── Verify component structure matches specs                   │
│                                                                  │
│  Layer 4: QUALITY GATE                                           │
│  ├── Task Loop checks design compliance before completion       │
│  ├── Block EXIT_SIGNAL if violations found                      │
│  └── Create fix tasks for violations                            │
│                                                                  │
│  Layer 5: DRIFT DETECTION                                        │
│  ├── Monitor for gradual deviation over time                    │
│  ├── Flag inconsistencies across components                     │
│  └── Suggest design system updates when patterns emerge         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Layer 1: Detection

### Design System Detection Logic

```yaml
detection:
  trigger: "on_every_frontend_task"

  check_locations:
    - "design-system/"
    - ".design-system/"
    - "src/design-system/"
    - "styles/design-system/"

  required_files:
    minimal:
      - "MASTER.md"
    standard:
      - "MASTER.md"
      - "tokens/colors.json"
      - "tokens/typography.json"
    complete:
      - "MASTER.md"
      - "tokens/colors.json"
      - "tokens/typography.json"
      - "tokens/spacing.json"
      - "components/*.md"

  detection_result:
    found: true
    location: "design-system/"
    completeness: "standard"  # minimal | standard | complete
    tokens_loaded:
      colors: 24
      typography: 12
      spacing: 16
```

### Task Loop Integration

```yaml
# Added to task loop logic
on_frontend_task:
  step_1_detect_design_system:
    action: scan_for_design_system
    result: design_system_context

  step_2_inject_context:
    if: design_system_context.found
    then:
      - load_design_tokens
      - prepend_to_agent_prompt
      - add_to_scope_constraints
      - enable_design_quality_gate

  step_3_no_design_system:
    if: NOT design_system_context.found
    then:
      - check_if_design_needed
      - if_needed: trigger_design_generation
      - if_not_needed: proceed_without_design
```

## Layer 2: Injection

### Frontend Agent Prompt Injection

When a design system exists, ALL frontend agents receive this prepended context:

```markdown
## MANDATORY: Design System Compliance

A design system exists for this project. You MUST use it.

### Design System Location
`design-system/`

### Loaded Tokens

**Colors** (USE THESE, NO HARDCODING):
```css
--color-primary: #6366F1;
--color-primary-hover: #4F46E5;
--color-secondary: #10B981;
--color-background: #FFFFFF;
--color-foreground: #111827;
--color-error: #EF4444;
--color-warning: #F59E0B;
--color-success: #10B981;
```

**Typography** (USE THESE, NO CUSTOM FONTS):
```css
--font-heading: 'Inter', system-ui, sans-serif;
--font-body: 'Inter', system-ui, sans-serif;
--font-code: 'JetBrains Mono', monospace;
--text-base: 1rem;
--text-lg: 1.25rem;
--text-xl: 1.563rem;
```

**Spacing** (USE THESE, NO MAGIC NUMBERS):
```css
--space-1: 0.25rem;  /* 4px */
--space-2: 0.5rem;   /* 8px */
--space-3: 0.75rem;  /* 12px */
--space-4: 1rem;     /* 16px */
--space-6: 1.5rem;   /* 24px */
--space-8: 2rem;     /* 32px */
```

### RULES (VIOLATIONS WILL BE REJECTED)

1. **NO HARDCODED COLORS** - Use CSS variables or Tailwind theme
2. **NO CUSTOM FONTS** - Use only defined font families
3. **NO MAGIC NUMBERS** - Use spacing scale
4. **MATCH COMPONENT SPECS** - Check design-system/components/

### Anti-Patterns (WILL FAIL QUALITY GATE)

```typescript
// ❌ WRONG - Hardcoded color
<div style={{ color: '#6366F1' }}>

// ✅ CORRECT - Using token
<div className="text-primary">

// ❌ WRONG - Magic number spacing
<div className="p-[13px]">

// ✅ CORRECT - Using spacing scale
<div className="p-4">

// ❌ WRONG - Custom font
<p style={{ fontFamily: 'Arial' }}>

// ✅ CORRECT - Using design system font
<p className="font-body">
```
```

### Scope Constraints Addition

```yaml
# Added to every frontend task scope
scope:
  design_system_constraints:
    must_use:
      - design_tokens_for_colors
      - design_tokens_for_typography
      - design_tokens_for_spacing

    forbidden:
      - hardcoded_hex_colors
      - hardcoded_font_families
      - hardcoded_pixel_values_for_spacing
      - inline_styles_with_design_values

    component_specs:
      check_against: "design-system/components/"
      must_match: true
```

## Layer 3: Validation

### Static Analysis Rules

```yaml
validation_rules:
  colors:
    # Detect hardcoded colors
    patterns_to_flag:
      - regex: '#[0-9A-Fa-f]{3,8}'
        except_in: [design-system/, *.config.*, theme.*]
        message: "Hardcoded color found. Use design token instead."

      - regex: 'rgb\(|rgba\(|hsl\('
        except_in: [design-system/, *.config.*]
        message: "Hardcoded color function. Use design token."

      - regex: 'color:\s*[^v]'  # color: not followed by var(
        in_files: [*.css, *.scss]
        message: "Direct color value. Use var(--color-*)."

  typography:
    patterns_to_flag:
      - regex: "font-family:\s*['\"](?!var)"
        message: "Hardcoded font family. Use design token."

      - regex: 'font-size:\s*\d+px'
        except_in: [design-system/]
        message: "Hardcoded font size. Use typography scale."

  spacing:
    patterns_to_flag:
      - regex: '(padding|margin|gap):\s*\d+px'
        except_values: [0, 1]  # 0 and 1px are ok
        message: "Hardcoded spacing. Use spacing scale."

      - regex: 'p-\[\d+px\]|m-\[\d+px\]'  # Tailwind arbitrary values
        message: "Arbitrary Tailwind spacing. Use scale."

  components:
    check_structure:
      - component_name_matches_spec
      - props_match_spec
      - variants_match_spec
```

### Design Compliance Validator Agent

```yaml
agent: design_compliance_validator
role: "Validate all frontend code against design system"

triggers:
  - after_frontend_developer_completes
  - before_quality_gates
  - on_commit_with_frontend_files

process:
  1. Load design system tokens
  2. Scan all changed frontend files
  3. Apply validation rules
  4. Generate compliance report

output:
  compliance_report:
    status: pass | fail
    violations:
      - file: "src/components/Button.tsx"
        line: 45
        type: "hardcoded_color"
        found: "#6366F1"
        should_use: "var(--color-primary) or text-primary"

      - file: "src/pages/Home.tsx"
        line: 23
        type: "arbitrary_spacing"
        found: "p-[13px]"
        should_use: "p-3 (12px) or p-4 (16px)"

    summary:
      total_violations: 2
      by_type:
        hardcoded_color: 1
        arbitrary_spacing: 1
```

## Layer 4: Quality Gate

### Task Loop Design Compliance Gate

```yaml
# Added to task-loop-config.yaml
quality_gates:
  design_compliance:
    enabled: true
    trigger: "when design_system_exists"
    priority: high  # Run before other gates

    checks:
      - id: no_hardcoded_colors
        severity: error
        auto_fix: false

      - id: no_hardcoded_fonts
        severity: error
        auto_fix: false

      - id: no_arbitrary_spacing
        severity: warning
        auto_fix: true
        fix_action: "suggest_nearest_scale_value"

      - id: component_spec_match
        severity: error
        auto_fix: false

    on_violation:
      error:
        action: block_completion
        create_fix_task: true
        assign_to: frontend_developer
        message: "Design system violations must be fixed"

      warning:
        action: log_and_suggest
        create_fix_task: false
        message: "Consider using design system value"

    in_report:
      show_violations: true
      show_suggestions: true
      link_to_design_docs: true
```

### Quality Gate Flow

```
Frontend Developer completes
            │
            ▼
┌─────────────────────────────┐
│  Design Compliance Gate     │
│  (runs first)               │
└─────────────┬───────────────┘
              │
      ┌───────┴───────┐
      │               │
   PASS            FAIL
      │               │
      ▼               ▼
┌─────────────┐  ┌─────────────┐
│ Continue to │  │ Block       │
│ other gates │  │ completion  │
└─────────────┘  └──────┬──────┘
                        │
                        ▼
               ┌─────────────┐
               │ Create fix  │
               │ task        │
               └─────────────┘
                        │
                        ▼
               Frontend Developer
               fixes violations
                        │
                        ▼
               Re-run quality gate
```

## Layer 5: Drift Detection

### Design Drift Detector Agent

```yaml
agent: design_drift_detector
role: "Monitor for gradual design system deviation"

schedule:
  - on_sprint_completion
  - on_manual_trigger
  - weekly_automated

analysis:
  scan_entire_codebase:
    include: ["src/**/*.tsx", "src/**/*.vue", "src/**/*.css"]
    exclude: ["node_modules", "dist", "design-system"]

  detect_patterns:
    # Find repeated values not in design system
    color_drift:
      find: "Colors used 3+ times not in tokens"
      action: "Suggest adding to design system"

    spacing_drift:
      find: "Spacing values used 3+ times not in scale"
      action: "Suggest adding to spacing scale"

    component_drift:
      find: "Similar component patterns not unified"
      action: "Suggest creating shared component"

    inconsistency_drift:
      find: "Same component styled differently in different places"
      action: "Flag for standardization"

output:
  drift_report:
    new_patterns_detected:
      - pattern: "#8B5CF6 used 5 times"
        suggestion: "Add as --color-accent-purple to design system"
        files: [Button.tsx, Card.tsx, Header.tsx]

      - pattern: "gap-5 (20px) used 8 times"
        suggestion: "Add --space-5 to spacing scale"
        files: [...]

    inconsistencies:
      - component: "Button"
        variations_found: 3
        recommendation: "Unify to single Button component with variants"

    overall_health:
      compliance_score: 87%
      drift_risk: "medium"
      recommendation: "Review color palette additions"
```

## Configuration

### Enable Design Enforcement

```yaml
# .devteam/design-enforcement.yaml
design_enforcement:
  enabled: true

  detection:
    auto_detect: true
    locations:
      - "design-system/"

  injection:
    prepend_to_prompts: true
    include_full_tokens: true

  validation:
    on_every_commit: true
    severity_levels:
      hardcoded_colors: error
      hardcoded_fonts: error
      arbitrary_spacing: warning
      component_mismatch: error

  quality_gate:
    block_on_violations: true
    max_warnings: 5

  drift_detection:
    enabled: true
    schedule: weekly
    alert_threshold: 3  # patterns used 3+ times
```

## Lifecycle Integration

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEVELOPMENT LIFECYCLE                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Sprint 1: Initial Development                                   │
│  ├── Design system generated (if needed)                        │
│  ├── Frontend devs receive design context                       │
│  ├── Implementation uses design tokens                          │
│  ├── Quality gate validates compliance                          │
│  └── ✅ Release with consistent design                          │
│                                                                  │
│  Sprint 2: Feature Addition                                      │
│  ├── Design system detected automatically                       │
│  ├── New feature dev receives existing tokens                   │
│  ├── Validation catches any hardcoded values                    │
│  ├── Quality gate ensures compliance                            │
│  └── ✅ Feature matches existing design                         │
│                                                                  │
│  Sprint 3: Another Developer Joins                               │
│  ├── Design system injected into their prompts                  │
│  ├── They use tokens without explicit instruction               │
│  ├── Any violations caught immediately                          │
│  └── ✅ Consistent regardless of who implements                 │
│                                                                  │
│  Sprint N: Drift Detection                                       │
│  ├── Weekly drift analysis runs                                 │
│  ├── New patterns detected (used 3+ times)                      │
│  ├── Suggestion: Add to design system                           │
│  ├── Design system evolves intentionally                        │
│  └── ✅ Controlled evolution, not chaos                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Summary

The design system is honored through:

1. **Automatic Detection** - Every frontend task checks for design system
2. **Prompt Injection** - Agents receive tokens and rules automatically
3. **Static Validation** - Code scanned for violations
4. **Quality Gate** - Task Loop blocks completion if violations found
5. **Drift Detection** - Catches gradual deviation over time

**Once a design system exists, it is IMPOSSIBLE to bypass without explicit override.**
