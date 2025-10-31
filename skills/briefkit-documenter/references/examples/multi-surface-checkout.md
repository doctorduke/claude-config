# Multi-Surface Checkout Example

**When to use this example**: Building apps with Web + Mobile + Kiosk/Hardware interfaces

**Key patterns demonstrated**:
- Surface-specific acceptance criteria for different platforms
- Gesture documentation for mobile interactions
- Different interaction models (keyboard/mouse vs. touch vs. physical readers)
- Platform-specific payment integrations

**Related documentation**:
- [PATTERNS.md](../PATTERNS.md) - Surface definition patterns
- [PHILOSOPHY.md](../PHILOSOPHY.md) - Gesture and interaction documentation

---

## Example 2: Multi-Surface Application

### Scenario
E-commerce checkout module supporting web, mobile, and kiosk interfaces.

### File: `app/checkout/BRIEF.md`

```markdown
# Checkout — BRIEF

## Purpose & Boundary
Handles payment processing and order completion across web, mobile app, and in-store kiosks. Manages cart finalization, payment methods, and order confirmation. Does NOT handle inventory management or shipping logistics.

## Interface Contract (Inputs → Outputs)
**Inputs**
- Cart data (items, quantities, prices)
- Payment method selection (credit card, PayPal, Apple Pay, Google Pay)
- Shipping address and preferences
- Promo codes and discounts
- User authentication token

**Outputs**
- Order confirmation with order ID
- Payment receipt (email and in-app)
- Inventory reservation events
- Analytics events (checkout started, completed, abandoned)
- Error states (payment failed, address invalid)

**Web — Interaction & Presentation**
- Key flows: Multi-step checkout wizard, express checkout (saved payment), guest checkout
- Interactions: Form validation, autofill support, keyboard navigation (Tab/Enter)
- Acceptance:
  - GIVEN user has items in cart
    WHEN user clicks "Checkout"
    THEN checkout wizard loads in ≤1s with cart summary
  - GIVEN payment info entered
    WHEN user submits
    THEN payment processes in ≤5s OR shows error with retry option

**Mobile — Interaction & Presentation**
- Key flows: One-tap checkout (biometric auth), saved address selection, in-app payment
- Gestures: Swipe between steps, pull-to-refresh order status
- Acceptance:
  - GIVEN user has Face ID/Touch ID enabled
    WHEN user taps "Pay with Face ID"
    THEN payment completes after biometric auth in ≤3s
  - GIVEN mobile payment selected
    WHEN user confirms
    THEN native payment sheet appears (Apple Pay/Google Pay)

**Kiosk — Interaction & Presentation**
- Key flows: QR code scan for cart import, card reader integration, receipt printing
- Interactions: Touch-only (no keyboard), large touch targets (min 44x44pt)
- Acceptance:
  - GIVEN customer scans QR code
    WHEN cart imports
    THEN checkout screen shows within 2s with cart contents
  - GIVEN payment completed
    WHEN receipt requested
    THEN receipt prints within 5s

**Inspirations/Comparables**
- Amazon one-click checkout (speed and simplicity)
- Shopify mobile checkout (native payment integration)
- Square kiosk UI (large touch targets, accessibility)
- Apple Store checkout (minimal friction, biometric auth)

**Anti-Goals**
- No subscription management (separate module)
- No split payments across multiple cards in v1
- No cryptocurrency payments in v1

## Dependencies & Integration Points
**Upstream**
- Cart service (cart contents, pricing)
- Auth service (user identity, saved payment methods)
- Payment gateway (Stripe API)
- Address validation service (Smarty Streets)

**Downstream**
- Order management system (order creation)
- Inventory service (reservation, deduction)
- Email service (receipts, confirmation)
- Analytics (conversion tracking)

## Work State (Planned / Doing / Done)
- **Planned**: [CHK-45] Add buy-now-pay-later options (Klarna, Afterpay) (owner @payments-team, target 2025-12-01)
- **Planned**: [CHK-47] Implement saved payment method management (owner @frontend-team, target 2025-11-20)
- **Doing**:   [CHK-42] Fix kiosk card reader timeout issues (owner @hardware-team, started 2025-10-28)
- **Doing**:   [CHK-43] Add promo code validation API (owner @backend-team, started 2025-10-29)
- **Done**:    [CHK-38] Launch mobile biometric checkout (merged 2025-10-20, PR #234)
- **Done**:    [CHK-40] Kiosk receipt printing integration (merged 2025-10-25, PR #241)

## SPEC_SNAPSHOT (2025-10-31)
- Features: multi-surface checkout, saved payments, guest checkout, promo codes, biometric auth (mobile)
- Tech: React (web), React Native (mobile), Electron (kiosk), Stripe SDK, Smarty Streets API
- Performance: <1s page load (web), <3s payment processing, <5s receipt printing
- Security: PCI DSS Level 1 compliant, tokenized payments, no card data stored
- Diagrams: [checkout flow](checkout/_reference/diagrams/flow-diagram.svg), [payment integration](checkout/_reference/spec/stripe-integration.png)
- Full spec: [checkout/_reference/spec/2025-10-20-v2.md](checkout/_reference/spec/2025-10-20-v2.md)

## Decisions & Rationale
- 2025-08-15 — Use Stripe for all payments (consolidate providers, reduce complexity)
- 2025-09-10 — Build kiosk version with Electron (code reuse from web, faster development)
- 2025-10-01 — Biometric auth mobile-only in v1 (web lacks consistent browser support)
- 2025-10-15 — Save payment methods server-side (security, cross-device sync)

## Local Reference Index
- [Stripe integration guide](checkout/_reference/spec/stripe-setup.md)
- [PCI compliance checklist](checkout/_reference/security/pci-compliance.md)
- [Error handling matrix](checkout/_reference/spec/error-codes.md)
- [Kiosk hardware specs](checkout/_reference/hardware/kiosk-requirements.md)

## Answer Pack
\```yaml
kind: answerpack
module: app/checkout
intent: "Process payments and complete orders across web, mobile, and kiosk"
surfaces:
  web:
    key_flows: ["multi-step wizard", "express checkout", "guest checkout"]
    acceptance: ["wizard loads ≤1s", "payment processes ≤5s", "keyboard navigable"]
  mobile:
    key_flows: ["one-tap biometric checkout", "saved address selection"]
    gestures: ["swipe between steps", "tap for native payment"]
    acceptance: ["biometric payment ≤3s", "native payment sheet appears"]
  kiosk:
    key_flows: ["QR cart import", "card reader payment", "receipt printing"]
    acceptance: ["cart imports ≤2s", "receipt prints ≤5s", "44x44pt touch targets"]
work_state:
  planned: ["CHK-45 buy-now-pay-later", "CHK-47 payment method management"]
  doing: ["CHK-42 kiosk card reader fix", "CHK-43 promo validation API"]
  done: ["CHK-38 mobile biometric", "CHK-40 kiosk receipt printing"]
interfaces:
  inputs: ["cart_data", "payment_method", "shipping_address", "promo_code", "auth_token"]
  outputs: ["order_confirmation", "payment_receipt", "inventory_reservation", "analytics_events", "error_states"]
spec_snapshot_ref: checkout/_reference/spec/2025-10-20-v2.md
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
\```
```

---

## Adaptation Checklist
- [ ] Replace checkout context with your multi-surface module
- [ ] Adjust surface sections to match your platforms (Web/Mobile/Kiosk/etc.)
- [ ] Update work state with current tickets and owners
- [ ] Verify dependencies are complete for each platform
- [ ] Add platform-specific performance requirements
- [ ] Include gesture documentation for mobile surfaces
- [ ] Document acceptance criteria for each surface separately

## See Also
- [PATTERNS.md](../PATTERNS.md) - Surface-specific pattern definitions
- [PHILOSOPHY.md](../PHILOSOPHY.md) - Gesture documentation and interaction patterns
- [EXAMPLES.md](../EXAMPLES.md) - Example index and selection guide
