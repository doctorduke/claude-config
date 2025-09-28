# Mobile UI Components — BRIEF

## Purpose & Boundary

Provides React Native UI components for the mobile platform, enabling native iOS and Android experiences. This module owns all mobile-specific UI components, hooks, and theme utilities, serving as the sole UI layer for `@umemee/mobile`.

Submodules:
- `components/` — Core UI components (Button, Text, View, etc.)
- `hooks/` — Mobile UI hooks (useTheme, useHaptics)
- `theme/` — Design system tokens (colors, spacing, typography)
- `utils/` — Platform utilities and responsive helpers

## Interface Contract (Inputs → Outputs)

**Inputs**
- Component props from consuming mobile app (JSX properties)
- Theme context from app-level providers
- User interactions (taps, swipes, long-press gestures)
- Platform signals (orientation, safe areas, accessibility)

**Outputs**
- Rendered native UI components (iOS UIKit / Android Views)
- Animated transitions via Reanimated native driver
- Haptic feedback on interactions
- Accessibility tree for screen readers

**Mobile Interaction & Presentation**
- Native touch handling with customizable activeOpacity
- Gesture-based interactions (swipe, pan, pinch)
- Platform-specific shadows and elevations
- Safe area aware component positioning
- Hardware back button integration (Android)

**Inspirations/Comparables**
- NativeBase component patterns
- React Native Elements structure
- Shopify Polaris mobile principles

**Anti-Goals**
- Web rendering (use `@umemee/ui-web` instead)
- Business logic or state management
- API calls or data fetching
- Navigation implementation

## Dependencies & Integration Points

**Upstream Dependencies**
- `@umemee/types` → Component prop type definitions
- `@umemee/utils` → Shared utility functions
- `react-native` → Core mobile framework
- `react-native-reanimated` → Native animations
- `react-native-gesture-handler` → Touch handling

**Downstream Consumers**
- `@umemee/mobile` → Exclusive consumer of all components
- Theme providers wrap entire app
- Components composed in screen layouts

## Work State

**Planned**
- [UI-201] BottomSheet component with gesture dismiss (owner @mobile-team, target 2025-10-15)
- [UI-202] List virtualization with FlashList (owner @perf-team, target 2025-10-20)
- [UI-203] Biometric authentication UI wrapper (owner @security, target 2025-11-01)

**Doing**
- [UI-195] Card component with swipe actions (owner @ui-team, started 2025-09-25)
- [UI-196] Dark mode theme implementation (owner @design, started 2025-09-26)

**Done**
- [UI-180] Button component with variants (merged 2025-09-20, PR #380)
- [UI-181] Text component with typography (merged 2025-09-21, PR #385)
- [UI-182] View container with safe areas (merged 2025-09-22, PR #390)

## Spec Snapshot (2025-09-27)

**Current State**
- Components: Button, Text, View (core primitives)
- Animations: Spring-based with native driver
- Platforms: iOS 13+, Android 5.0+ (API 21+)
- Accessibility: VoiceOver/TalkBack compatible

**Tech Stack**
- React Native 0.81.4
- TypeScript strict mode
- StyleSheet API for styling
- Platform-specific code branches

**References**
- Component patterns: `_reference/patterns/component-structure.md`
- Theme system: `_reference/design/theme-tokens.md`
- Performance guide: `_reference/perf/mobile-optimization.md`

## Decisions & Rationale

- 2025-09-15 — Choose Reanimated 3 over LayoutAnimation (gesture performance)
- 2025-09-18 — Separate ui-mobile from ui-web packages (platform optimization)
- 2025-09-20 — Use StyleSheet.create over inline styles (performance)
- 2025-09-22 — Implement Platform.select for OS-specific code (maintainability)

## Local Reference Index

**Component Modules**
- `src/components/Button/` → Native touchable with haptics
- `src/components/Text/` → Typography with platform fonts
- `src/components/View/` → Container with safe area support

**Hook Modules**
- `src/hooks/useTheme` → Theme context consumer
- `src/hooks/useHaptics` → Haptic feedback wrapper

**Theme System**
- `src/theme/` → Design tokens and platform styles

## Answer Pack

```yaml
kind: answerpack
module: shared/ui-mobile
intent: "React Native component library for native mobile experiences"
surfaces:
  mobile:
    key_flows:
      - "Import component → Pass props → Render native view"
      - "Apply theme → Platform-specific styles → Native rendering"
    gestures: ["tap", "long-press", "swipe", "pan"]
    acceptance:
      - "Components render identically on iOS/Android (except platform styles)"
      - "All interactions trigger haptic feedback when enabled"
      - "Accessibility labels present on all interactive elements"
work_state:
  planned: ["UI-201", "UI-202", "UI-203"]
  doing: ["UI-195", "UI-196"]
  done: ["UI-180", "UI-181", "UI-182"]
interfaces:
  inputs:
    - "Component props (TypeScript interfaces)"
    - "Theme context values"
    - "User touch events"
    - "Platform OS signals"
  outputs:
    - "Native UI components"
    - "Animated transitions"
    - "Haptic feedback"
    - "Accessibility tree"
spec_snapshot_ref: _reference/spec/2025-09-27-v1.md
truth_hierarchy: ["source", "tests", "BRIEF", "CLAUDE.md", "_reference", "issues"]
```