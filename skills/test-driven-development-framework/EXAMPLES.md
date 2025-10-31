# TDD Examples

## Example 1: Bug Fix via Regression Test (Python)

Scenario: Function miscalculates discounts when total is exactly at threshold.

Given/When/Then:
- Given a cart total of 100 and threshold at 100
- When computing discount at 10%
- Then discount should apply (10) and total becomes 90

Sketch (pytest):
```
def test_discount_applies_at_threshold():
    assert apply_discount(total=100, pct=0.10, threshold=100) == 90
```
Drive fix minimally, then add near-boundary tests (99.99, 100.01).

## Example 2: Outside-In API Slice with Contract (Node.js)

Scenario: Add POST /todos that validates payload and returns created item.

Steps:
- Write consumer test (supertest) failing on POST /todos
- Define OpenAPI schema and examples for request/response
- Add provider contract verification
- Implement route and service; use in-memory repo in unit tests

Snippet (Jest + supertest):
```
it('creates a todo and returns 201', async () => {
  await request(app).post('/todos').send({ title: 'Buy milk' })
    .expect(201)
    .expect(res => expect(res.body).toMatchObject({ id: expect.any(String), title: 'Buy milk' }))
})
```

## Example 3: Legacy Code Characterization (Java)

Scenario: Payment calculation module is brittle; behavior unknown.

Steps:
- Write characterization tests at module facade using fixtures
- Capture edge behaviors (rounding, fees) without changing code
- Introduce seam via interface to external tax service
- Replace internal algorithm incrementally, keeping tests green

## Example 4: UI Component Behavior (React)

Scenario: Button opens modal on click and traps focus.

Steps:
- Test by role and keyboard: focus moves to modal; Esc closes
- Avoid snapshot tests for behavior; assert accessibility states

Snippet (RTL + Jest):
```
it('opens modal and traps focus', async () => {
  render(<Page/>)
  await user.click(screen.getByRole('button', { name: /open/i }))
  const dialog = await screen.findByRole('dialog', { name: /settings/i })
  expect(dialog).toBeVisible()
  await user.keyboard('{Tab}')
  expect(dialog).toHaveFocusWithin()
})
```

## Example 5: Async Scheduler with Fake Clock (Go)

Scenario: Scheduler executes tasks at intervals.

Steps:
- Inject clock and ticker; in tests, advance fake time
- Assert execution counts and ordering deterministically

Sketch:
```
fake := NewFakeClock()
s := NewScheduler(fake)
go s.Start()
fake.Advance(1 * time.Minute)
require.Equal(t, 1, s.RunCount())
```

