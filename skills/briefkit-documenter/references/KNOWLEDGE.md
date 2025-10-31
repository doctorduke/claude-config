# Briefkit Deep Knowledge

This document explores the philosophy, methodology, and deeper principles behind interface-first documentation with BRIEF.

## Table of Contents

1. [Interface-First Philosophy](#interface-first-philosophy)
2. [When to Use Interface-First Documentation](#when-to-use-interface-first-documentation)
3. [BRIEF vs Traditional Documentation](#brief-vs-traditional-documentation)
4. [Agent-Parsable Documentation Design](#agent-parsable-documentation-design)
5. [Documentation as Code](#documentation-as-code)
6. [Maintenance Strategies](#maintenance-strategies)
7. [Common Pitfalls](#common-pitfalls)
8. [Documentation-Code Relationship](#documentation-code-relationship)

---

## Interface-First Philosophy

### Core Principle

**Document the "what" before the "how".**

Interface-first documentation prioritizes external behavior (inputs, outputs, contracts) over internal implementation (algorithms, data structures, classes). This inversion creates documentation that remains valuable even as implementation details change.

### Why Interface-First?

**1. Stable Foundation**

Interfaces change less frequently than implementations. A function's signature (what it accepts and returns) is more stable than its internal logic. By documenting interfaces first, documentation remains accurate longer.

**Example:**
```javascript
// Interface (stable):
function searchArticles(query, filters) → Promise<Article[]>

// Implementation (changes often):
// v1: Linear scan with string matching
// v2: SQL full-text search
// v3: Elasticsearch with ML ranking
```

The interface documentation remains valid across all three implementations.

**2. Contract-Driven Development**

When teams document interfaces first, they're forced to think about contracts before implementation:
- What inputs are required vs optional?
- What outputs are guaranteed?
- What invariants must hold?
- What are the failure modes?

This upfront thinking prevents API design mistakes that are expensive to fix later.

**3. Agent-Friendly**

AI coding agents benefit from knowing "what" a module does without needing to parse implementation details:
- "This module accepts X and produces Y"
- "Call this when you need to..."
- "This guarantees that..."

Clear contracts enable agents to use modules correctly without understanding internals.

**4. Human Onboarding**

New developers can be productive faster when they understand interfaces:
- Day 1: Understand what each module does (interfaces)
- Week 1: Understand how modules interact (dependencies)
- Month 1: Understand implementation details (optional)

Interface-first documentation front-loads the most valuable information.

### Interface-First in Practice

**Start with boundaries:**
```markdown
## Purpose & Boundary
This module handles user authentication. It manages login, logout,
and session validation. It does NOT handle authorization (separate
authz module) or user profile management (separate profile module).
```

**Define contracts explicitly:**
```markdown
## Interface Contract (Inputs → Outputs)
**Inputs**
- POST /api/auth/login with {username, password}
- Authorization header with Bearer token

**Outputs**
- 200 OK with JWT token (valid 24h)
- 401 Unauthorized if credentials invalid
- 429 Too Many Requests if rate limit exceeded
```

**State guarantees:**
```markdown
**Performance Guarantees**
- p95 latency <200ms
- 99.9% availability
- Password hashing uses bcrypt (10 rounds minimum)
```

### The Interface Hierarchy

Not all interfaces are equal. Document in this order:

1. **Public API** - What external consumers call
2. **Module interface** - What other modules in your system call
3. **Internal interfaces** - Private contracts within module
4. **Implementation** - How it actually works

BRIEF documents levels 1-2 only. Levels 3-4 go in code comments or _reference/ if needed.

---

## When to Use Interface-First Documentation

### Ideal Scenarios

**1. Modular Codebases**

When your codebase is organized into modules with clear boundaries, interface-first documentation shines. Each module gets its own BRIEF documenting its contract.

**2. Multi-Surface Applications**

Applications with Web + Mobile + API benefit from per-surface interface documentation. Document how each surface interacts with the module differently.

**3. Microservices**

Each service is an independent module with well-defined APIs. BRIEF documents service contracts, dependencies, and SLAs.

**4. Library/SDK Development**

When building libraries for others to use, interface-first documentation is essential. Users care about "what" they can do, not "how" you implemented it.

**5. Team Collaboration**

When multiple teams work on different modules, interface documentation becomes the contract between teams. Changes to interfaces require coordination; changes to implementation don't.

**6. AI-Assisted Development**

When using AI coding agents, interface documentation provides the context agents need without overwhelming them with implementation details.

### Less Ideal Scenarios

**1. Monolithic Scripts**

Small, single-purpose scripts with no external interfaces don't benefit much from BRIEF. A simple README or code comments suffice.

**2. Prototypes**

During rapid prototyping where interfaces change hourly, maintaining BRIEF creates friction. Wait until interfaces stabilize.

**3. Pure Implementation Projects**

If working on algorithm implementation (e.g., optimizing a sorting algorithm), interface-first docs add little value. The interface is simple; implementation is the interesting part.

**4. Documentation-Heavy Domains**

Some domains (regulated industries, complex standards) require extensive narrative documentation. BRIEF's concise style may not meet compliance needs. Consider it a supplement, not replacement.

### Adaptation Strategies

Even in less-ideal scenarios, you can adapt:

**For prototypes:** Use lightweight BRIEF with heavy INFERRED markers. Document intent, even if details are fuzzy.

**For monoliths:** Create BRIEFs for major subsystems, even if not formally modularized. Enforce boundaries through documentation.

**For algorithm work:** BRIEF can document the algorithm's interface (inputs, outputs, complexity guarantees) while _reference/ contains implementation details.

---

## BRIEF vs Traditional Documentation

### Comparison Matrix

| Aspect | Traditional Docs | BRIEF Documentation |
|--------|-----------------|-------------------|
| **Organization** | Topic-based (Getting Started, API Reference, Tutorials) | Module-based (one BRIEF per module) |
| **Scope** | Often application-wide | Always module-scoped |
| **Primary Audience** | Humans | Humans AND agents |
| **Update Frequency** | Quarterly or on request | With every PR that changes behavior |
| **Length** | Unbounded (can grow to 100s of pages) | Strictly limited (≤200 lines) |
| **Structure** | Freeform prose | Fixed schema with required sections |
| **Depth** | Everything in one place | Layered (BRIEF → _reference/) |
| **Validation** | Manual review | Automated checks (hooks, CI) |
| **Truth Source** | Separate from code | Lives alongside code |
| **Maintenance** | Often stale | Kept current via enforcement |

### Where BRIEF Excels

**1. Co-location with Code**

BRIEF lives in the module directory, next to the code it documents. This physical proximity encourages updates.

```
app/auth/
  BRIEF.md       ← Documentation
  src/           ← Code
  tests/         ← Tests
  _reference/    ← Deep docs
```

**2. Enforced Structure**

Fixed schema prevents documentation drift. Everyone knows where to find interface contracts, work state, and decisions.

**3. Agent-Parsable**

Answer Pack (YAML) provides structured data for agents to consume without parsing prose.

**4. Truth Hierarchy**

Explicit precedence rules (source > tests > BRIEF > _reference/) resolve conflicts between documentation and reality.

**5. Length Constraints**

200-line limit forces authors to be concise and link to _reference/ for depth. Prevents documentation bloat.

### Where Traditional Docs Excel

**1. Narrative Flow**

Traditional docs can tell a story: "First do X, then Y, then Z." BRIEF's fixed schema doesn't support narrative.

**2. Tutorials**

Step-by-step tutorials with code examples are better in traditional format. BRIEF references these in _reference/.

**3. Conceptual Overviews**

High-level architectural explanations benefit from freeform prose with diagrams. BRIEF links to these in Spec Snapshot.

**4. Marketing/Sales**

Product overview docs for non-technical audiences need different tone and structure. BRIEF is technical docs only.

### Hybrid Approach

Most projects benefit from both:

- **BRIEF** - Per-module normative docs (interface contracts, work state, decisions)
- **Traditional** - Application-wide guides (getting started, tutorials, architecture)
- **_reference/** - Deep technical specs (algorithms, protocols, data models)

Store traditional docs in `/docs`, BRIEFs in modules, _reference/ alongside each BRIEF.

---

## Agent-Parsable Documentation Design

### Why Agent-Parsable Matters

Modern development involves AI coding agents. Documentation optimized for agent consumption enables:

- **Code generation** - Agents generate code matching documented contracts
- **Code review** - Agents check if code matches documented behavior
- **Question answering** - Agents answer "how do I..." questions from docs
- **Refactoring** - Agents preserve documented invariants during refactors

### Design Principles

**1. Structured Data Over Prose**

Prose: "The search endpoint returns results sorted by relevance in under 500 milliseconds."

Structured:
```yaml
endpoints:
  - path: /api/search
    method: GET
    response:
      sort: relevance
      latency_p95: 500ms
```

Agents parse structured data reliably. Prose requires NLP.

**2. Predictable Locations**

Always put the same information in the same place:
- Inputs → Interface Contract section, Inputs subsection
- Performance → Interface Contract section, Performance Guarantees
- Decisions → Decisions & Rationale section

Agents learn where to find what they need.

**3. Explicit, Not Implicit**

Bad: "Handles authentication" (vague, requires inference)
Good: "Accepts username/password, returns JWT token valid for 24h" (explicit)

Agents struggle with implicit information. Be explicit.

**4. Enumerations Over Examples**

When documenting inputs, list all possible inputs:
```markdown
**Inputs**
- POST /api/users (create)
- GET /api/users/:id (read)
- PUT /api/users/:id (update)
- DELETE /api/users/:id (delete)
```

Don't just show one example and expect agents to infer others.

**5. Contracts Over Narratives**

Focus on contracts (what must be true) rather than narratives (how things happen):

Contract: "Returns 200 OK with user object OR 404 Not Found if user doesn't exist"
Narrative: "First we check if the user exists in the database..."

Agents need contracts to generate correct code. Narratives are helpful but secondary.

### Answer Pack Design

Answer Pack provides machine-readable summary:

```yaml
kind: answerpack
module: app/auth
intent: "User authentication via username/password"
interfaces:
  inputs: ["POST /api/auth/login {username, password}"]
  outputs: ["200 OK {token}", "401 Unauthorized"]
```

**When agents ask:**
- "What does app/auth do?" → Read `intent`
- "How do I call it?" → Read `interfaces.inputs`
- "What does it return?" → Read `interfaces.outputs`

No prose parsing needed.

### The "Search Pattern" Optimization

For large reference docs, include search patterns in BRIEF:

```markdown
## Local Reference Index
- [API Reference](\_reference/api/README.md) - Use grep "endpoint:" for specific endpoint docs
- [Error Codes](\_reference/spec/errors.md) - Use grep "ERR-" for error code meanings
```

Agents can use these grep patterns to find specific information without loading entire files.

---

## Documentation as Code

### Core Principles

**1. Documentation Lives in Source Control**

BRIEF files are committed to Git alongside code:
- Same version history
- Same branching strategy
- Same merge conflicts resolution
- Same code review process

**2. Documentation Changes via PRs**

Update BRIEF in the same PR that changes behavior:
- Code change + BRIEF update = atomic commit
- Reviewers verify documentation matches code
- Prevents documentation drift

**3. Validation in CI**

Automated checks in CI pipeline:
- BRIEF exists for every module
- Required sections present
- Spec Snapshot dated correctly
- No INFERRED markers in Interface Contract
- Links to _reference/ resolve

**4. Documentation-Driven Development**

For new features:
1. Write BRIEF first (intended interface)
2. Review BRIEF with stakeholders
3. Implement to match BRIEF
4. Update BRIEF if implementation reveals new insights

### Implementation Strategies

**Git Hooks**

Pre-commit hook:
```bash
# Check that BRIEF updated if code changed
if git diff --name-only | grep "^src/"; then
  if ! git diff --name-only | grep "BRIEF.md"; then
    echo "Warning: Code changed but BRIEF not updated"
    exit 1
  fi
fi
```

**CI Validation**

GitHub Actions example:
```yaml
- name: Validate BRIEFs
  run: |
    # Check all modules have BRIEF
    find . -type d -name src -exec test -f {}/BRIEF.md \; -print
    # Validate BRIEF structure
    .claude/skills/briefkit-documenter/assets/validate-brief.sh
```

**PR Templates**

Require BRIEF updates in PR template:
```markdown
## Checklist
- [ ] BRIEF.md updated if behavior changed
- [ ] Spec Snapshot date refreshed
- [ ] Work State updated (planned/doing/done)
- [ ] Tests cover new behavior
```

### Benefits

**1. Always Up-to-Date**

When docs are code, they stay current. Stale docs block PRs.

**2. Diff-able**

Git diff shows what changed in documentation, just like code:
```diff
## Interface Contract (Inputs → Outputs)
**Inputs**
- POST /api/users
+- PUT /api/users/:id (added update endpoint)
```

**3. Blame-able**

`git blame BRIEF.md` shows who documented what and when. Useful for context.

**4. Searchable History**

`git log --all --full-history -- BRIEF.md` shows entire evolution of module's documentation.

---

## Maintenance Strategies

### Keeping Documentation Current

**1. Update with Behavior Changes**

Rule: If behavior changes, BRIEF must change in same PR.

Behavior changes include:
- New inputs/outputs
- Changed performance characteristics
- New dependencies
- Removed features

**2. Refresh Spec Snapshots Regularly**

Even if behavior is stable, refresh Spec Snapshot quarterly:
- Update date to current
- Verify links still resolve
- Add new _reference/ materials created since last update
- Archive old Done items in Work State

**3. Prune Work State**

Keep Work State lean (3-7 items per section):
- Move completed items from Done to archive after 30 days
- Cancel old Planned items that are no longer relevant
- Update Doing items with current status

**4. Validate on Schedule**

Weekly/monthly: Run validation across all BRIEFs:
- Check for stale snapshots (>90 days)
- Verify all links resolve
- Identify BRIEFs with INFERRED markers
- Report missing BRIEFs for new modules

### Handling Drift

**When Code Contradicts BRIEF:**

Always trust code (per Truth Hierarchy). Fix BRIEF to match code, don't change code to match BRIEF without understanding why they diverged.

Investigation steps:
1. Verify code behavior (run tests, check implementation)
2. Check git history: When did code change? Was BRIEF updated?
3. Identify root cause: Intentional change not documented? BRIEF error?
4. Fix BRIEF to match reality
5. Add decision note explaining the divergence

**When BRIEF Has INFERRED Markers:**

INFERRED markers signal "needs human verification." Resolve them:
1. Review inferred content with someone familiar with the code
2. Correct any inferences that are wrong
3. Confirm correct inferences and remove INFERRED marker
4. If still uncertain, add to Planned work state: "Clarify X behavior"

### Refactoring Documentation

Sometimes BRIEF structure needs refactoring:

**Split large BRIEF:**
- Create submodules with own BRIEFs
- Parent BRIEF links to children via Local Reference Index
- Move details from parent to children

**Merge small BRIEFs:**
- If modules are tightly coupled, consider merging
- Document as single module with clear internal boundaries
- Use subsections in Interface Contract

**Restructure _reference/:**
- As _reference/ grows, reorganize into subdirectories
- Update links in BRIEF
- Maintain backward compat with redirects if public

---

## Common Pitfalls

### Pitfall 1: Documenting Implementation Instead of Interface

**Symptom:**
```markdown
## Interface Contract (Inputs → Outputs)
The authentication module uses bcrypt to hash passwords with 10 rounds.
It stores hashed passwords in the users table with a unique index on username.
```

**Problem:** This documents HOW, not WHAT. Implementation details don't belong in Interface Contract.

**Fix:**
```markdown
## Interface Contract (Inputs → Outputs)
**Inputs**
- Username (string, 3-50 characters)
- Password (string, 8+ characters)

**Outputs**
- Success: JWT token (valid 24h)
- Failure: Error message ("Invalid credentials")

**Security Guarantees**
- Passwords hashed with industry-standard algorithm (bcrypt)
- Passwords never returned in responses
```

### Pitfall 2: Letting BRIEF Grow Beyond 200 Lines

**Symptom:** BRIEF.md is 500 lines with detailed specs, API examples, and diagrams embedded.

**Problem:** Long BRIEFs are hard to scan. They defeat the "quick reference" purpose.

**Fix:**
- Move detailed specs to _reference/spec/
- Move diagrams to _reference/diagrams/
- Move API examples to _reference/api-examples/
- Keep BRIEF short with links to detail

### Pitfall 3: Vague Acceptance Oracles

**Symptom:**
```markdown
**Acceptance**
- Search works correctly
- Results are relevant
```

**Problem:** "Works correctly" and "relevant" are subjective. Not testable.

**Fix:**
```markdown
**Acceptance**
- GIVEN search query "javascript tutorial"
  WHEN user searches
  THEN results include articles with "javascript" in title or content
  AND results return in <500ms
  AND results sorted by relevance score (TF-IDF)
```

### Pitfall 4: Neglecting Answer Pack

**Symptom:** BRIEF has all prose sections but no Answer Pack, or Answer Pack with incomplete data.

**Problem:** Agents can't efficiently parse the BRIEF. They must read all prose.

**Fix:** Always include complete Answer Pack with:
- intent
- surfaces (all applicable: web, mobile, api)
- work_state
- interfaces (inputs and outputs)
- spec_snapshot_ref
- truth_hierarchy

### Pitfall 5: Duplicate Information

**Symptom:** Same information in BRIEF, _reference/spec/, and code comments.

**Problem:** Multiple sources of truth. When one is updated, others become stale.

**Fix:** Apply single-source-of-truth principle:
- Interface contracts → BRIEF (normative)
- Detailed specs → _reference/spec/ (informative)
- Implementation notes → code comments
- Each fact lives in exactly one place; others link to it

### Pitfall 6: Ignoring Truth Hierarchy

**Symptom:** BRIEF says "returns 200 OK" but code returns 201 Created. Developer "fixes" code to match BRIEF.

**Problem:** Violated truth hierarchy. Code is source of truth, not BRIEF.

**Fix:** When code contradicts BRIEF:
1. Trust code
2. Update BRIEF to match code
3. Investigate why they diverged
4. Add decision note if intentional change

### Pitfall 7: Not Using INFERRED Markers

**Symptom:** When generating BRIEF from legacy code, documenter guesses behavior and presents it as fact.

**Problem:** Guesses might be wrong. No signal to reviewer that verification is needed.

**Fix:** Use INFERRED markers liberally:
```markdown
**Inputs**
> INFERRED: Based on route handler signatures
- POST /api/login
- POST /api/logout
```

Reviewer knows to verify these inferences.

---

## Documentation-Code Relationship

### The Feedback Loop

Documentation and code inform each other:

```
Design phase:
  Write BRIEF → Reveals design issues → Refine BRIEF → Implement code

Development phase:
  Write code → Reveals implementation issues → Update BRIEF → Continue coding

Maintenance phase:
  Change code → Update BRIEF → Review both → Merge together
```

Documentation is not an afterthought. It's part of the development process.

### When Documentation Should Drive Code

**1. API Design**

Document the desired API in BRIEF before implementation:
- Forces thinking about contracts
- Reveals inconsistencies early
- Stakeholders can review API before implementation

**2. Refactoring**

Before refactoring, document intended new interface in BRIEF:
- Clarifies refactoring goals
- Preserves contracts that must remain stable
- Communicates changes to team

**3. New Features**

For new features, BRIEF acts as design doc:
- Purpose & Boundary: What are we building?
- Interface Contract: How do users/systems interact?
- Dependencies: What does this need?
- Work State: How do we track progress?

### When Code Should Drive Documentation

**1. Discovery**

When exploring solution space, let code lead:
- Prototype rapidly without BRIEF
- Once interface stabilizes, document in BRIEF
- Don't let documentation slow discovery

**2. Implementation Details**

Code reveals details that weren't anticipated:
- Error conditions that emerge during implementation
- Performance characteristics discovered through testing
- Edge cases found during development

Update BRIEF with these discoveries.

**3. Bug Fixes**

Bug fix changes behavior, update BRIEF if:
- Fix changes interface (new error code, different output)
- Fix changes performance characteristics
- Fix reveals incorrect documentation

If fix is purely internal (no interface change), code comment suffices.

### The Documentation Debt Problem

**Symptoms:**
- BRIEFs missing for many modules
- Existing BRIEFs have stale Spec Snapshots
- INFERRED markers everywhere, never resolved
- _reference/ links broken

**Causes:**
- Documentation not part of definition of done
- No enforcement (CI checks disabled)
- Time pressure ("we'll document it later")
- Team doesn't see value

**Solutions:**

**1. Enforce in CI:**
```yaml
# Block merges without BRIEF updates
jobs:
  validate-docs:
    - name: Check BRIEF updates
      run: |
        if git diff --name-only origin/main | grep "src/"; then
          git diff --name-only origin/main | grep "BRIEF.md" || exit 1
        fi
```

**2. Make Documentation Easy:**
- Provide templates (copy-paste and fill in)
- Automate inference (generate draft BRIEFs from code)
- Use AI agents to draft BRIEFs for review

**3. Demonstrate Value:**
- Show how agents use BRIEFs to answer questions
- Use BRIEFs in onboarding (new devs love them)
- Reference BRIEFs in design reviews

**4. Pay Down Debt Gradually:**
- Document one module per sprint
- Focus on high-traffic modules first
- Involve authors in documentation (they know the code)

**5. Make It Part of Culture:**
- Code review checklist includes "BRIEF updated?"
- Definition of done includes "BRIEF current"
- Celebrate good documentation in team meetings

---

## Conclusion

Interface-first documentation with BRIEF is a methodology for creating maintainable, agent-friendly, human-readable documentation that lives alongside code. Key takeaways:

1. **Document WHAT, not HOW** - Interfaces over implementation
2. **Structure over prose** - Fixed schema, predictable locations
3. **Co-location** - Documentation lives with code
4. **Enforcement** - Validate automatically, update with every change
5. **Layered depth** - BRIEF (brief) → _reference/ (deep)
6. **Agent-friendly** - Structured data (Answer Pack) + consistent format
7. **Truth hierarchy** - Code is source of truth, docs describe code

When applied consistently, this methodology creates documentation that developers trust, agents can parse, and teams can maintain over years.

---

*Knowledge version: 1.0.0*
*Based on: BRIEF System v3*
