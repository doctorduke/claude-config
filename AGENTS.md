# Repository Guidelines

## Project Structure & Module Organization
Monorepo managed by pnpm + Turborepo. Platform apps in `platforms/` (`web/` Next.js, `mobile/` Expo, `desktop/` Electron). Shared packages—UI, types, API client, prompts, utilities—under `shared/`. Docs, briefs, and knowledge live in `docs/`, `brief-kit/`, and per-workspace `BRIEF.md`. Scripts and automation sit in `scripts/` and `tools/`. Add features beside their owning workspace and keep assets with the nearest `public/` or `assets/` directory.

## Build, Test, and Development Commands
Install once with `pnpm install`. Run the full stack using `pnpm dev`, or scope with `pnpm --filter <workspace> dev`. Produce release builds via `pnpm build`. Quality gates: `pnpm lint`, `pnpm typecheck`, `pnpm format`. Use `pnpm clean` to clear Turbo caches plus `node_modules` when runs drift.

## Coding Style & Naming Conventions
Prettier enforces 2-space indentation, 100-character lines, semicolons, single quotes, LF endings—invoke `pnpm format` before review. TypeScript operates in `strict` mode; prefer explicit return types for exports and use the `@umemee/*` alias instead of relative walks. ESLint with React Hooks/Refresh forbids unused vars (`_` prefix to ignore), warns on unexpected `any`, and limits `console` to `warn`/`error`. Align file names with their default export, e.g., `UserCard.tsx`, `useFeatureFlag.ts`.

## Testing Guidelines
`pnpm test` fans out through Turbo to each workspace. Every new package should expose `test`, `lint`, and `typecheck` scripts so the pipeline can discover it. Co-locate unit specs as `*.test.ts[x]` or within a sibling `__tests__/`. Share fixtures only when needed—`data/` already holds cross-cutting samples. Document uncovered paths in the PR body until the team sets numeric thresholds.

## Commit & Pull Request Guidelines
Follow Conventional Commits (`type(scope): summary`), mirroring recent history (`feat(web): ...`, `fix(ci): ...`). Keep commits focused, rebase before pushing, and confirm lint/test locally. Pull requests need a concise narrative, linked briefs or issues, terminal snippets for any `pnpm` checks run, and visuals for UI deltas. Update relevant `BRIEF.md` files so downstream work stays aligned.

## Agent Notes
`BRIEF.md` is the knowledge system and onboarding map—read it first to understand objectives, dependencies, and cross-links. `CLAUDE.md` covers agentic command-line tactics for that workspace. When you discover new context, augment the appropriate brief instead of scattering guidance elsewhere.
