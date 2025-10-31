# PRD to BRIEF Conversion Example

**When to use this example**: Converting Product Requirements Documents to BRIEFs

**Key patterns demonstrated**:
- Extracting structure from prose requirements
- Inferring interfaces from PRD sections
- Mapping PRD concepts to BRIEF sections
- Review requirements for converted docs

**Related documentation**:
- [PATTERNS.md](../PATTERNS.md) - BRIEF structure and section definitions
- [KNOWLEDGE.md](../KNOWLEDGE.md) - Conversion strategies and validation

---

## Example 6: Document Ingestion (PRD → BRIEF)

### Scenario
Converting a Product Requirements Document into a BRIEF.

### Input: PRD for "Smart Search" Feature

```
PRODUCT REQUIREMENTS: Smart Search v1

PROBLEM
Users struggle to find specific articles in large reading lists. Current search is keyword-only and slow.

SOLUTION
Implement semantic search with filters and ranking.

REQUIREMENTS
- Full-text search across titles and content
- Filter by: date range, author, tags, read status
- Rank by relevance (TF-IDF) and recency
- Search suggestions (autocomplete)
- Search history for logged-in users

SURFACES
Web: Search bar in header, results page with filters sidebar
Mobile: Search icon in tab bar, modal results with swipeable filters

UX INSPIRATION
- Notion's quick-find (speed + keyboard navigation)
- Gmail search (powerful filters, simple UI)

TECH CHOICES
- Elasticsearch for search index
- React components for UI
- Background indexer job

ACCEPTANCE CRITERIA
- Search returns results in <500ms
- Autocomplete appears after 2 characters
- Results update as user types (debounced 300ms)
- Filters applied client-side without re-query

OUT OF SCOPE
- No image search
- No search analytics in v1
- No saved searches

ROADMAP
Q4 2025: Basic search + filters
Q1 2026: Autocomplete + search history
Q2 2026: ML-based ranking

TECHNICAL DECISIONS
- Use Elasticsearch over PostgreSQL full-text (better performance, more features)
- Index updates via background job every 5 minutes (acceptable staleness for this use case)
```

### Output: Generated BRIEF

### File: `app/search/BRIEF.md`

```markdown
# Smart Search — BRIEF

## Purpose & Boundary
> INFERRED: Derived from PRD "Problem" and "Solution" sections

Provides semantic search functionality for article discovery. Enables users to search across titles and content with filtering and relevance ranking. Covers search UI, query processing, and result ranking. Does NOT handle article content indexing (separate indexer service).

## Interface Contract (Inputs → Outputs)
**Inputs**
> INFERRED: From "Requirements" section

- User text input (search queries)
- Filter selections: date range, author, tags, read status
- User interactions: typing, selecting suggestions, applying filters

**Outputs**
> INFERRED: From "Requirements" and "Acceptance Criteria"

- Search results list (ranked by relevance and recency)
- Autocomplete suggestions (appears after 2 characters)
- Search history for logged-in users
- Filter state persistence

**Performance Guarantees**
> INFERRED: From "Acceptance Criteria"

- Search results return in <500ms (p95)
- Autocomplete debounced 300ms
- Filter application client-side (instant)

**Web — Interaction & Presentation**
> INFERRED: From "Surfaces" section

- Key flows: Type in header search bar, review results page, apply filters via sidebar
- Interactions: Keyboard navigation (↑↓ for suggestions, Enter to search), click filters
- Acceptance:
  - GIVEN user types in search bar
    WHEN 2+ characters entered
    THEN autocomplete suggestions appear within 300ms
  - GIVEN search results displayed
    WHEN user applies filter
    THEN results update instantly client-side

**Mobile — Interaction & Presentation**
> INFERRED: From "Surfaces" section

- Key flows: Tap search icon, enter query in modal, swipe filters horizontally
- Gestures: Tap to select suggestion, swipe for more filters
- Acceptance:
  - GIVEN user taps search icon
    WHEN search modal opens
    THEN keyboard appears and search input focused
  - GIVEN results displayed
    WHEN user swipes filter carousel
    THEN filters scroll smoothly at 60fps

**Inspirations/Comparables**
> INFERRED: From "UX Inspiration"

- Notion quick-find (speed + keyboard navigation)
- Gmail search (powerful filters, simple UI)

**Anti-Goals**
> INFERRED: From "Out of Scope"

- No image search
- No search analytics in v1
- No saved searches

## Dependencies & Integration Points
**Upstream**
> INFERRED: From "Tech Choices" and general architecture

- Elasticsearch cluster (search index)
- Indexer service (keeps search index updated)
- Auth service (user identity for search history)

**Downstream**
> INFERRED: From typical search system dependencies

- Article detail pages (navigation on result click)
- Analytics (search queries, result clicks)

## Work State (Planned / Doing / Done)
> INFERRED: From "Roadmap" section

- **Planned**: [SRCH-05] ML-based ranking (owner @ml-team, target Q2 2026)
- **Planned**: [SRCH-04] Autocomplete + search history (owner @frontend-team, target Q1 2026)
- **Doing**:   [SRCH-01] Basic search implementation (owner @search-team, started 2025-10-20)
- **Doing**:   [SRCH-02] Filters implementation (owner @frontend-team, started 2025-10-25)
- **Done**:    [SRCH-00] PRD approved and BRIEF created (completed 2025-10-31)

## SPEC_SNAPSHOT (2025-10-31)
> INFERRED: From "Tech Choices" and "Requirements"

- Features (v1): full-text search, filters (date/author/tags/status), relevance ranking (TF-IDF + recency)
- Features (planned): autocomplete, search history, ML ranking
- Tech: Elasticsearch 8.x, React components, background indexer (Node.js)
- Performance: <500ms search, 300ms autocomplete debounce, 60fps filter scroll
- Indexing: Background job every 5 minutes
- Full spec: [app/search/_reference/spec/prd-smart-search-v1.pdf](app/search/_reference/spec/prd-smart-search-v1.pdf) (original PRD stored)

## Decisions & Rationale
> INFERRED: From "Technical Decisions" section

- 2025-10-15 — Use Elasticsearch over PostgreSQL full-text (better performance, richer features)
- 2025-10-18 — Background indexing every 5 minutes (acceptable staleness vs complexity trade-off)

## Local Reference Index
- [Original PRD](app/search/_reference/spec/prd-smart-search-v1.pdf)
- [Elasticsearch schema design](app/search/_reference/spec/elasticsearch-mapping.json) (to be created)
- [UI wireframes](app/search/_reference/ux/wireframes.pdf) (to be created)

## Answer Pack
\```yaml
kind: answerpack
module: app/search
intent: "Semantic search with filters and ranking for article discovery"
surfaces:
  web:
    key_flows: ["search from header", "apply filters", "navigate to result"]
    acceptance: ["results <500ms", "autocomplete after 2 chars", "instant filter application"]
  mobile:
    key_flows: ["tap search icon", "enter query", "swipe filters"]
    gestures: ["tap to select", "swipe filters"]
    acceptance: ["modal opens with keyboard", "smooth 60fps filter scroll"]
work_state:
  planned: ["SRCH-05 ML ranking", "SRCH-04 autocomplete + history"]
  doing: ["SRCH-01 basic search", "SRCH-02 filters"]
  done: ["SRCH-00 PRD approved"]
interfaces:
  inputs: ["search queries", "filter selections", "user typing"]
  outputs: ["search results", "autocomplete suggestions", "search history", "filter state"]
spec_snapshot_ref: app/search/_reference/spec/prd-smart-search-v1.pdf
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
\```

**REVIEW REQUIRED**: This BRIEF was generated from PRD. Please verify:
1. Interface Contract accuracy (inputs/outputs complete?)
2. Performance guarantees realistic?
3. Dependencies correct?
4. Work State IDs and timeline feasible?
5. Remove INFERRED markers after verification.
```

---

## Conversion Checklist
- [ ] Extract "Problem" and "Solution" → Purpose & Boundary
- [ ] Map "Requirements" → Interface Contract inputs/outputs
- [ ] Extract "Acceptance Criteria" → Performance Guarantees and Acceptance sections
- [ ] Extract "Surfaces" → Surface-specific sections (Web/Mobile/etc.)
- [ ] Extract "UX Inspiration" → Inspirations/Comparables
- [ ] Extract "Out of Scope" → Anti-Goals
- [ ] Extract "Roadmap" → Work State (map to Planned/Doing/Done)
- [ ] Extract "Tech Choices" and "Technical Decisions" → Decisions & Rationale
- [ ] Infer missing dependencies from tech stack and interfaces
- [ ] Create REVIEW REQUIRED note and verification checklist
- [ ] Mark all inferred content with INFERRED markers
- [ ] Store original PRD in _reference/ directory

## Validation Checklist (After Conversion)
- [ ] Does Interface Contract match PRD requirements?
- [ ] Are performance guarantees achievable?
- [ ] Are dependencies complete and accurate?
- [ ] Does each surface section match PRD surfaces?
- [ ] Are anti-goals aligned with out-of-scope items?
- [ ] Is work state timeline realistic?
- [ ] Have all INFERREDs been reviewed?

## See Also
- [PATTERNS.md](../PATTERNS.md) - BRIEF structure standards
- [KNOWLEDGE.md](../KNOWLEDGE.md) - PRD analysis and conversion strategies
- [EXAMPLES.md](../EXAMPLES.md) - Example index and selection guide
