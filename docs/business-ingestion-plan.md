# Business Material Ingestion Plan

## Supported Input Types
- PRDs (Product Requirements Documents)
- Chat transcripts (Slack, Discord, Teams)
- Technical documentation
- Document snippets
- Images (with OCR/description)

## Ingestion Process

### 1. Material Collection
```bash
docs/business-materials/
├── prds/
│   ├── mvp-spec.md
│   └── feature-roadmap.md
├── chats/
│   ├── product-decisions.txt
│   └── user-feedback.json
├── tech-docs/
│   └── architecture-decisions.md
└── images/
    └── wireframes/
```

### 2. Mapping Strategy

| Input Type | Maps To | Extraction Focus |
|------------|---------|------------------|
| PRDs | Purpose & Boundary, Interface Contract | Problems, requirements, user stories |
| Chats | Decisions & Rationale, Work State | Decisions made, action items |
| Tech Docs | Dependencies, Spec Snapshot | Architecture, technical choices |
| Images | Interface Contract (UI flows) | Screen layouts, user flows |

### 3. BRIEF Generation Commands

```bash
# For each major feature/module:
brief ingest \
  --module features/[feature-name] \
  --src docs/business-materials/prds/[feature].md \
  --out features/[feature-name]/BRIEF.md \
  --reference-root features/[feature-name]/_reference

# Review generated BRIEF for INFERRED: markers
# Edit to replace inferences with facts
```

### 4. Quality Checklist

Before committing generated BRIEFs:
- [ ] Interface Contract has clear Inputs/Outputs
- [ ] Module scope is clear (not mixed with app-wide)
- [ ] Work items extracted to Work State section
- [ ] Decisions captured with dates
- [ ] Details pushed to _reference/ (BRIEF <200 lines)
- [ ] INFERRED: markers reviewed and resolved

## Implementation Priority

1. **Core Features** (Week 1)
   - User authentication
   - Workspace management
   - Document CRUD

2. **Platform Features** (Week 2)
   - Mobile offline sync
   - Web real-time collab
   - Desktop file integration

3. **Integration Features** (Week 3)
   - API client setup
   - Third-party services
   - Analytics pipeline

## Success Metrics
- All features have BRIEFs before implementation
- 90% of decisions captured in Decisions & Rationale
- Work State accurately reflects sprint planning
- Interface Contracts validated by tests