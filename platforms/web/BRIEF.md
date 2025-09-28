# Web Platform — BRIEF

## Purpose & Boundary

**Purpose**: Deliver umemee as a performant, SEO-optimized web application with progressive web app capabilities across all modern browsers.

**Boundary**: Next.js 15+ application handling server-side rendering, client-side interactivity, API routing, and static asset optimization for web/PWA delivery.

## Interface Contract

```yaml
inputs:
  user_interactions:
    - Browser requests (HTTP/HTTPS)
    - Form submissions
    - File uploads
    - WebSocket connections
  platform_signals:
    - Route parameters
    - Query strings
    - Cookies/sessions
    - Browser APIs (geolocation, notifications)
  shared_packages:
    - "@umemee/ui-web": Web UI components
    - "@umemee/types": Type definitions
    - "@umemee/api-client": API communication
    - "@umemee/config": Environment config
    - "@umemee/utils": Utility functions

outputs:
  rendered_content:
    - SSR/SSG HTML pages
    - Client-side React components
    - API responses (JSON)
    - Static assets (optimized)
  performance_artifacts:
    - Edge-cached content
    - Service worker cache
    - Prefetched routes
    - Code-split bundles
  seo_metadata:
    - Open Graph tags
    - Structured data
    - Sitemap.xml
    - Robots.txt

acceptance_oracles:
  core_web_vitals:
    - LCP < 2.5s
    - FID < 100ms
    - CLS < 0.1
    - INP < 200ms
  lighthouse_scores:
    - Performance > 90
    - Accessibility > 95
    - Best Practices > 95
    - SEO > 95
  browser_support:
    - Chrome/Edge 90+
    - Firefox 88+
    - Safari 14+
    - Mobile browsers
```

## Dependencies & Integration Points

- **Framework**: Next.js 15+ with App Router, Turbopack
- **UI Layer**: React 18+, Tailwind CSS, Radix UI, Framer Motion
- **State Management**: TanStack Query (server), Zustand (client)
- **Forms**: React Hook Form + Zod validation
- **Analytics**: Vercel Analytics, Sentry, PostHog
- **Deployment**: Vercel Edge Network, Docker standalone

## Work State

```yaml
active_tasks:
  - id: [WEB-01]
    task: "Implement RSC patterns for optimal performance"
    status: in_progress
  - id: [WEB-02]
    task: "Configure PWA with offline support"
    status: pending
  - id: [WEB-03]
    task: "Set up Edge Functions for global CDN"
    status: planned

tech_debt:
  - id: [WEB-TD-01]
    issue: "Migrate remaining pages to App Router"
    priority: high
  - id: [WEB-TD-02]
    issue: "Optimize bundle splitting strategy"
    priority: medium

completed:
  - Next.js 15 setup with Turbopack
  - Tailwind CSS configuration
  - Basic routing structure
  - Environment variable setup
```

## Spec Snapshot (2025-09-27)

**Version**: Next.js 15.0, React 18.3, Turbopack enabled

Key architectural elements:
- Server Components by default (reduced bundle size)
- Streaming SSR with Suspense boundaries
- Parallel/intercepting routes for modals
- Server Actions for mutations
- Edge runtime for API routes
- Incremental Static Regeneration (ISR)

## Decisions & Rationale

1. **Next.js App Router over Pages**: Superior performance via RSC, better DX with nested layouts
2. **Turbopack over Webpack**: 10x faster HMR in development, better tree-shaking
3. **Tailwind + Radix UI**: Rapid styling with accessible primitives
4. **TanStack Query for server state**: Built-in caching, background refetching, optimistic updates
5. **Vercel deployment**: Optimal Next.js integration, Edge Functions, automatic optimization

## Local Reference Index

```
platforms/web/
├── app/                    # App Router (routes, layouts, API)
│   ├── layout.tsx         # Root layout with providers
│   ├── page.tsx          # Homepage
│   ├── (auth)/          # Auth route group
│   ├── (dashboard)/     # Protected routes
│   └── api/            # API endpoints
├── components/          # React components
│   ├── ui/            # Base UI components
│   └── features/      # Feature-specific
├── lib/               # Utilities and hooks
├── public/           # Static assets
├── next.config.js    # Next.js configuration
└── CLAUDE.md        # Detailed AI instructions
```

## Answer Pack

```yaml
quickstart: |
  pnpm dev --filter=@umemee/web     # Start dev server on localhost:3000
  pnpm build --filter=@umemee/web   # Production build
  pnpm start --filter=@umemee/web   # Run production server

common_issues:
  hydration_mismatch: "Ensure server/client render identical content, check dynamic values"
  env_vars_not_working: "Client vars need NEXT_PUBLIC_ prefix"
  slow_dev_server: "Turbopack should be enabled, check next.config.js"

web_specific:
  ssr_data_fetching: "Use Server Components with async/await for data"
  seo_optimization: "Use generateMetadata() for dynamic meta tags"
  pwa_setup: "Configure next-pwa in next.config.js with manifest.json"

performance_tips:
  - Use next/image for automatic image optimization
  - Implement next/font for web font optimization
  - Lazy load below-the-fold components with dynamic()
  - Enable ISR for semi-static content
  - Use Edge runtime for lightweight API routes
```