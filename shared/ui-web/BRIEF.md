# Web UI Components — BRIEF

## Purpose & Boundary
Provides reusable React components specifically optimized for web platforms (Next.js web app and Tauri desktop). This module handles all browser-specific UI rendering, interactions, and styling while maintaining accessibility standards and performance optimization for web environments.

## Interface Contract (Inputs → Outputs)

**Inputs**
* Component props from consuming platforms (variant, size, state, callbacks)
* Theme context and CSS variables for styling
* Browser events (clicks, hovers, keyboard interactions)
* Viewport state for responsive behavior

**Outputs**
* Rendered JSX elements with proper HTML semantics
* DOM events and callbacks to parent components
* CSS classes via Tailwind and CVA variants
* ARIA attributes for accessibility

**Web-Specific Behavior**
* Responsive breakpoints: sm (640px), md (768px), lg (1024px), xl (1280px)
* Keyboard shortcuts: focus management, tab navigation, escape dismissal
* Hover states and cursor interactions
* CSS-in-JS with runtime theming support

**Component Categories**
* Primitives: Button, Input, Label, Switch, Checkbox
* Layout: Card, Dialog, Sheet, Tabs, Accordion
* Forms: Form, FormField, FormControl, FormMessage
* Feedback: Toast, Alert, Progress, Skeleton

**Anti-Goals**
* No mobile-specific gestures or native behaviors
* No direct API calls or business logic
* No global state management

## Dependencies & Integration Points

**Upstream Dependencies**
* `@umemee/types` — Component prop types and interfaces
* `@umemee/utils` — Utility functions for formatting and helpers
* `react` — UI framework (peer dependency)
* `@radix-ui/react-*` — Headless component primitives
* `framer-motion` — Animation and gesture library
* `class-variance-authority` — Variant management
* `tailwindcss` — Utility-first CSS framework

**Downstream Consumers**
* `platforms/web` — Next.js application
* `platforms/desktop` — Tauri desktop app (future)

## Work State (Planned / Doing / Done)

- **Planned**: Component library documentation site
- **Planned**: Visual regression testing setup
- **Doing**: Core component set implementation
- **Done**: Project structure and build configuration

## Spec Snapshot (2025-09-27)

- **Components**: Button, Card, Dialog, Form primitives
- **Tech Stack**: React 18+, Radix UI, Tailwind CSS, CVA, Framer Motion
- **Patterns**: Compound components, forwardRef, CSS variables theming
- **Testing**: Vitest unit tests, Storybook for development

## Decisions & Rationale

- 2025-09-27 — Radix UI for accessibility-first headless components (WCAG compliance)
- 2025-09-27 — CVA for type-safe variant management (better than manual className logic)
- 2025-09-27 — Tailwind CSS for consistent utility classes across platforms
- 2025-09-27 — Framer Motion for declarative animations (better DX than CSS animations)

## Local Reference Index

Components are organized in flat structure under `src/components/`:
- Each component has its own directory with `.tsx`, `.stories.tsx`, `.test.tsx`
- Shared utilities in `src/utils/` for className merging and variant helpers
- Theme tokens and global styles in `src/styles/`

## Answer Pack

```yaml
kind: answerpack
module: shared/ui-web
intent: "React component library optimized for web browsers with accessibility and theming"
surfaces:
  web:
    key_components: ["Button", "Dialog", "Form", "Card", "Toast"]
    patterns: ["CVA variants", "Radix primitives", "Tailwind styling", "forwardRef"]
    accessibility: ["ARIA attributes", "keyboard navigation", "focus management"]
work_state:
  planned: ["component docs site", "visual regression tests"]
  doing: ["core component implementation"]
  done: ["project structure", "build config"]
interfaces:
  inputs: ["component props", "theme context", "browser events", "viewport state"]
  outputs: ["JSX elements", "DOM events", "CSS classes", "ARIA attributes"]
dependencies:
  internal: ["@umemee/types", "@umemee/utils"]
  external: ["react", "@radix-ui/*", "framer-motion", "tailwindcss", "cva"]
spec_snapshot_date: "2025-09-27"
truth_hierarchy: ["source", "tests", "storybook", "docs", "issues", "chat"]
```