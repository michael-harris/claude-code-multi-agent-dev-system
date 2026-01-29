# UX Design Agent Collection

A comprehensive suite of specialized UI/UX agents inspired by [ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill).

## Agent Overview

### Design Generation Agents

| Agent | Specialty | Key Data |
|-------|-----------|----------|
| **Design System Orchestrator** | Coordinates design workflow | Orchestrates all UX agents |
| **Design System Architect** | Comprehensive design generation | Full design system output |
| **UI Style Curator** | Visual style selection | 67 UI styles |
| **Color Palette Specialist** | Industry-specific colors | 96 color palettes |
| **Typography Specialist** | Font selection & pairing | 57 font pairings |
| **Data Visualization Designer** | Charts & dashboards | 25 chart types, 10 dashboard styles |

### Design Enforcement Agents (Quality Gates)

| Agent | Specialty | Trigger |
|-------|-----------|---------|
| **Design Compliance Validator** | Validates code against design tokens | Automatic on frontend changes |
| **Design Drift Detector** | Monitors for gradual deviation | Weekly + sprint completion |

## Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                  DESIGN SYSTEM GENERATION                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Request: "Design system for fintech dashboard"                  │
│                         │                                        │
│                         ▼                                        │
│            ┌─────────────────────────┐                          │
│            │ Design System           │                          │
│            │ Orchestrator            │                          │
│            └───────────┬─────────────┘                          │
│                        │                                        │
│         ┌──────────────┼──────────────┐                        │
│         │              │              │                         │
│         ▼              ▼              ▼                         │
│  ┌─────────────┐ ┌──────────┐ ┌─────────────┐                  │
│  │ Industry UX │ │ UI Style │ │ Color       │                  │
│  │ Consultant  │ │ Curator  │ │ Palette     │                  │
│  └──────┬──────┘ └────┬─────┘ └──────┬──────┘                  │
│         │             │              │                          │
│         │   Finance   │  Executive   │   Fintech                │
│         │   rules     │  Dashboard   │   palette                │
│         │             │              │                          │
│         ▼             ▼              ▼                          │
│  ┌─────────────────────────────────────────┐                   │
│  │           Parallel Processing            │                   │
│  └─────────────────────────────────────────┘                   │
│         │              │              │                         │
│         ▼              ▼              ▼                         │
│  ┌─────────────┐ ┌──────────┐ ┌─────────────┐                  │
│  │ Typography  │ │ Data Viz │ │ Component   │                  │
│  │ Specialist  │ │ Designer │ │ Architect   │                  │
│  └──────┬──────┘ └────┬─────┘ └──────┬──────┘                  │
│         │             │              │                          │
│         │  IBM Plex   │  Financial   │  Dashboard               │
│         │  family     │  charts      │  components              │
│         │             │              │                          │
│         └──────────────┴──────────────┘                         │
│                        │                                        │
│                        ▼                                        │
│            ┌─────────────────────────┐                          │
│            │   Synthesized Design    │                          │
│            │   System Output         │                          │
│            └─────────────────────────┘                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Agent Files

```
agents/ux/
├── README.md                           # This file
├── design-system-orchestrator.md       # Main orchestrator
├── design-system-architect.md          # Comprehensive design generation
├── ui-style-curator.md                 # 67 UI styles
├── color-palette-specialist.md         # 96 industry palettes
├── typography-specialist.md            # 57 font pairings
├── data-visualization-designer.md      # Charts & dashboards
├── design-compliance-validator.md      # Quality gate - validates code
└── design-drift-detector.md            # Monitors for drift over time
```

## Design Enforcement Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│              DESIGN SYSTEM ENFORCEMENT FLOW                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. DETECTION                                                    │
│     └── Task Orchestrator checks for design-system/ directory   │
│                                                                  │
│  2. INJECTION                                                    │
│     └── Design tokens prepended to frontend agent prompts       │
│                                                                  │
│  3. IMPLEMENTATION                                               │
│     └── Frontend Developer uses tokens (not hardcoded values)   │
│                                                                  │
│  4. VALIDATION                                                   │
│     └── Design Compliance Validator scans for violations        │
│                                                                  │
│  5. QUALITY GATE                                                 │
│     └── Ralph blocks completion if violations found             │
│                                                                  │
│  6. DRIFT MONITORING                                             │
│     └── Weekly checks for gradual deviation from design system  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Integration with DevTeam

These agents integrate with:
- **Frontend Developer** - Receives design tokens and implements
- **Accessibility Specialist** - Reviews for WCAG compliance
- **Ralph Quality Loop** - Design compliance validation gate
- **Task Orchestrator** - Auto-detection and token injection

## Tech Stack Support

All agents output for 13 frameworks:
- Web: React, Next.js, Vue, Nuxt, Svelte, Astro, HTML+Tailwind
- UI: shadcn/ui
- Mobile: SwiftUI, React Native, Flutter, Jetpack Compose

## Credits

Inspired by [ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) by nextlevelbuilder.
