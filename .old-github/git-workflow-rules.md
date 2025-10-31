# Git Workflow Rules

## NEVER Work on Trunk/Main
1. Always create feature branches: `feat/`, `fix/`, `docs/`, `chore/`
2. Trunk is protected even without GitHub enforcement
3. All work goes through PRs

## Branch Naming
- `feat/[feature-name]` - New features
- `fix/[issue-id]-[description]` - Bug fixes
- `docs/[area]` - Documentation
- `chore/[task]` - Maintenance

## Commit Strategy
1. Create feature branch
2. Make changes
3. Push to origin
4. Create PR
5. Review (even self-review)
6. Merge

## Without Branch Protection
Since we can't enforce via GitHub:
1. Add pre-push hook to prevent trunk pushes
2. Use git aliases to enforce workflow
3. Agent workflows check branch before committing