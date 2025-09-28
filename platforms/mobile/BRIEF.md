# Mobile Platform — BRIEF

## Purpose & Boundary

Native mobile application for iOS and Android devices providing offline-first access to umemee. This module contains the React Native/Expo implementation with platform-specific optimizations for touch interactions, native features, and mobile performance. Boundary includes all mobile-specific UI, navigation, device integrations, and platform services.

Submodules:
- `src/navigation/` — React Navigation stack and tab routing
- `src/screens/` — Platform screen components
- `src/services/` — Native device services (camera, storage, notifications)
- `src/components/` — Mobile-specific UI components

## Interface Contract (Inputs → Outputs)

**Inputs**
- Touch gestures (tap, swipe, pinch, long-press)
- Device events (rotation, keyboard, background/foreground)
- Push notifications and deep links (`umemee://`)
- Native API permissions (camera, location, contacts)
- Network status changes (online/offline transitions)
- Biometric authentication (FaceID/TouchID/fingerprint)

**Outputs**
- Native UI rendering at 60fps minimum
- Haptic feedback for interactions
- Local notifications and badges
- Offline data persistence via AsyncStorage/SecureStore
- Background sync when network available
- Native share sheet integration
- Platform-specific toasts and alerts

**Mobile — Interaction & Presentation**

Key flows:
- Swipe-right from edge opens command drawer
- Pull-to-refresh on all scrollable lists
- Long-press for context menus
- Pinch-to-zoom on media content
- Shake device to report bug (dev mode)

Acceptance oracles:
- GIVEN offline mode WHEN user opens app THEN cached content loads ≤200ms
- GIVEN background state WHEN push received THEN notification appears with app badge
- GIVEN low memory warning WHEN app active THEN gracefully reduces cache
- GIVEN biometric enabled WHEN app returns from background THEN requires authentication

**Inspirations/Comparables**
- Apollo (gesture navigation)
- Notion Mobile (offline sync)
- Telegram (performance and animations)
- Things 3 (haptic feedback patterns)

**Anti-Goals**
- No tablet-specific layouts in v1
- No Apple Watch / WearOS companion apps yet
- No widget support initially
- No AR/VR features
- No background audio/video playback

## Dependencies & Integration Points

**Upstream Dependencies**
- `@umemee/types` — TypeScript definitions
- `@umemee/utils` — Shared utilities
- `@umemee/config` — App configuration
- `@umemee/api-client` — Backend API access
- `@umemee/ui-mobile` — React Native component library

**Downstream Consumers**
- EAS Build service for cloud builds
- App Store Connect / Google Play Console
- Sentry for crash reporting
- Analytics services (Firebase/Amplitude)

**Integration Points**
- Expo SDK for managed workflow
- React Navigation for routing
- React Query for server state
- Zustand for client state
- AsyncStorage for persistence
- SecureStore for credentials

## Work State (Planned / Doing / Done)

- **Planned**: [MOB-01] Implement biometric authentication (owner @mobile-team, target Sprint-3)
- **Planned**: [MOB-02] Add offline queue for API calls (owner @volunteer, target Sprint-3)
- **Planned**: [MOB-03] Integrate push notifications (owner @mobile-team, target Sprint-4)
- **Doing**: [MOB-04] Polish gesture navigation (owner @volunteerA, started 2025-09-26)
- **Doing**: [MOB-05] Optimize list performance with FlashList (owner @mobile-team, started 2025-09-25)
- **Done**: [MOB-06] Setup Expo SDK 50 (merged 2025-09-21, PR #142)
- **Done**: [MOB-07] Implement React Navigation 6 (merged 2025-09-20, PR #138)

## Spec Snapshot (2025-09-27)

- **Features**: Offline-first sync, gesture navigation, push notifications, biometric auth, deep linking
- **Tech choices**: React Native 0.73+, Expo SDK 50, React Navigation 6, Reanimated 3, TanStack Query
- **Performance**: 60fps animations, <200ms offline load, <2MB initial bundle
- **Platforms**: iOS 14+ (iPhone only), Android 8+ (API 26+)
- **Diagrams**: See _reference/spec/navigation-flow.png
- **Full spec**: _reference/spec/2025-09-27-mobile-v1.md

## Decisions & Rationale

- 2025-09-22 — Choose Expo managed workflow over bare (faster iteration, OTA updates)
- 2025-09-23 — React Navigation over Expo Router (more mature, better gesture support)
- 2025-09-24 — FlashList over FlatList for large lists (10x performance improvement)
- 2025-09-24 — Zustand over Redux for state (simpler, better React Native integration)
- 2025-09-25 — AsyncStorage + SecureStore over MMKV (Expo compatibility)
- 2025-09-26 — Swipe-right command drawer pattern (one-hand reachability)

## Local Reference Index

- **src/navigation/** → [Navigation docs](_reference/navigation/README.md)
  - key refs: [gesture map](_reference/navigation/gestures.md), [deep link schema](_reference/navigation/deep-links.md)
- **src/services/** → [Services docs](_reference/services/README.md)
  - key refs: [offline sync](_reference/services/offline-sync.md), [push setup](_reference/services/push-notifications.md)
- **src/screens/** → [Screen inventory](_reference/screens/README.md)
  - key refs: [screen flows](_reference/screens/user-flows.md), [performance metrics](_reference/screens/perf-budgets.md)

## Answer Pack

```yaml
kind: answerpack
module: platforms/mobile
intent: "Native iOS/Android app with offline-first architecture and gesture navigation"
surfaces:
  mobile:
    key_flows:
      - "swipe-right command drawer"
      - "pull-to-refresh lists"
      - "offline content access"
      - "biometric authentication"
      - "push notification handling"
    gestures:
      - "edge-swipe for drawer"
      - "pull-down to refresh"
      - "long-press context menu"
      - "pinch-to-zoom media"
      - "shake for bug report"
    acceptance:
      - "offline load ≤200ms"
      - "60fps animations"
      - "haptic feedback on actions"
      - "background push delivery"
work_state:
  planned: ["MOB-01 biometric auth", "MOB-02 offline queue", "MOB-03 push notifications"]
  doing: ["MOB-04 gesture polish", "MOB-05 FlashList optimization"]
  done: ["MOB-06 Expo SDK 50", "MOB-07 React Navigation 6"]
interfaces:
  inputs: ["touch gestures", "device events", "push notifications", "deep links", "permissions"]
  outputs: ["60fps UI", "haptic feedback", "local notifications", "offline persistence", "background sync"]
spec_snapshot_ref: _reference/spec/2025-09-27-mobile-v1.md
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
```