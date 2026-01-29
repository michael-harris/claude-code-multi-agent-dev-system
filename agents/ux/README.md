# UX Design Agent Collection

A comprehensive suite of specialized UI/UX agents inspired by [ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill).

## Agent Overview

| Agent | Specialty | Key Data |
|-------|-----------|----------|
| **Design System Orchestrator** | Coordinates design workflow | Orchestrates all UX agents |
| **UI Style Curator** | Visual style selection | 67 UI styles |
| **Color Palette Specialist** | Industry-specific colors | 96 color palettes |
| **Typography Specialist** | Font selection & pairing | 57 font pairings |
| **Data Visualization Designer** | Charts & dashboards | 25 chart types, 10 dashboard styles |
| **Industry UX Consultant** | Domain-specific rules | 100 industry rules |
| **Component Architect** | Design system structure | Component APIs & patterns |

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
├── ui-style-curator.md                 # 67 UI styles
├── color-palette-specialist.md         # 96 industry palettes
├── typography-specialist.md            # 57 font pairings
├── data-visualization-designer.md      # Charts & dashboards
├── industry-ux-consultant.md           # 100 industry rules
└── component-architect.md              # Design system structure
```

## Integration with DevTeam

These agents integrate with:
- **Frontend Developer** - Receives design tokens and implements
- **Accessibility Specialist** - Reviews for WCAG compliance
- **Ralph Quality Loop** - Validates design system completeness

## Tech Stack Support

All agents output for 13 frameworks:
- Web: React, Next.js, Vue, Nuxt, Svelte, Astro, HTML+Tailwind
- UI: shadcn/ui
- Mobile: SwiftUI, React Native, Flutter, Jetpack Compose

## Credits

Inspired by [ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) by nextlevelbuilder.
