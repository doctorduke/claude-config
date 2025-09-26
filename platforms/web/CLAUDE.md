# CLAUDE.md - Web Platform

## Purpose
The web platform delivers umemee as a modern, performant web application using Next.js 14+ with App Router. This platform provides server-side rendering, SEO optimization, and progressive web app capabilities while maintaining a responsive design that works across all modern browsers and devices.

## Dependencies

### Internal Dependencies
- `@umemee/ui-web` - Web-optimized UI component library
- `@umemee/types` - Shared TypeScript definitions
- `@umemee/api-client` - API client for backend communication
- `@umemee/config` - Shared configuration and environment settings
- `@umemee/utils` - Common utility functions
- Core modules from `core-modules/` when implemented

### External Dependencies
- **Next.js 14+** - React framework with App Router
- **React 18+** - UI library with concurrent features
- **Tailwind CSS** - Utility-first CSS framework
- **Radix UI** - Unstyled, accessible component primitives
- **Framer Motion** - Animation library
- **React Query/TanStack Query** - Server state management
- **Zustand** - Client state management
- **React Hook Form** - Form management
- **Zod** - Schema validation

## Key Files

```
web/
├── app/                  # Next.js App Router
│   ├── layout.tsx       # Root layout
│   ├── page.tsx        # Home page
│   ├── globals.css     # Global styles
│   ├── (auth)/         # Auth route group
│   ├── (dashboard)/    # Dashboard routes
│   └── api/           # API routes
├── components/         # React components
│   ├── ui/            # UI components
│   ├── features/      # Feature components
│   └── layouts/       # Layout components
├── lib/               # Library code
│   ├── hooks/         # Custom React hooks
│   ├── utils/         # Web-specific utilities
│   └── services/      # Service layer
├── public/            # Static assets
├── styles/            # Additional styles
├── next.config.js     # Next.js configuration
├── tailwind.config.ts # Tailwind configuration
└── tsconfig.json      # TypeScript configuration
```

## Conventions

### File Naming
- Components: `PascalCase.tsx` (e.g., `UserProfile.tsx`)
- Utilities: `kebab-case.ts` (e.g., `format-date.ts`)
- Hooks: `use-{name}.ts` (e.g., `use-auth.ts`)
- API Routes: `route.ts` in appropriate directories
- Types: `{name}.types.ts` or within component files

### Component Structure
```typescript
// components/features/UserProfile.tsx
import { FC } from 'react'
import { cn } from '@/lib/utils'

interface UserProfileProps {
  className?: string
  userId: string
}

export const UserProfile: FC<UserProfileProps> = ({ 
  className,
  userId 
}) => {
  // Component logic
  return (
    <div className={cn('default-styles', className)}>
      {/* Component JSX */}
    </div>
  )
}
```

### Route Organization
- Use route groups `(name)` for organization without affecting URLs
- Parallel routes for modals and overlays
- Intercepting routes for modal patterns
- Dynamic routes `[param]` for parameterized pages
- Catch-all routes `[...slug]` for flexible routing

## Testing

### Test Setup
```bash
# Run all tests
pnpm test

# Run tests in watch mode
pnpm test:watch

# Run E2E tests
pnpm test:e2e

# Generate coverage report
pnpm test:coverage
```

### Testing Strategy
- **Unit Tests**: Jest + React Testing Library for components
- **Integration Tests**: API route testing with MSW
- **E2E Tests**: Playwright for critical user journeys
- **Visual Regression**: Chromatic/Percy for UI consistency

### Test Organization
```
__tests__/
├── unit/           # Unit tests
├── integration/    # Integration tests
└── e2e/           # End-to-end tests

components/
└── Button/
    ├── Button.tsx
    └── Button.test.tsx  # Co-located tests
```

## Common Tasks

### Development
```bash
# Start development server
pnpm dev

# Start with specific port
pnpm dev -- -p 3001

# Start with HTTPS
pnpm dev -- --https

# Clear Next.js cache
rm -rf .next
```

### Building
```bash
# Create production build
pnpm build

# Analyze bundle size
pnpm analyze

# Run production server locally
pnpm start

# Export static site (if applicable)
pnpm export
```

### Adding Features
```bash
# Create new page
mkdir -p app/features/new-feature
touch app/features/new-feature/page.tsx

# Add new component
mkdir -p components/features/NewComponent
touch components/features/NewComponent/NewComponent.tsx
touch components/features/NewComponent/index.ts

# Add API route
mkdir -p app/api/new-endpoint
touch app/api/new-endpoint/route.ts
```

## Gotchas

### Common Issues
1. **Hydration Mismatches**: Ensure server and client render identical content
2. **Import Order**: CSS modules must be imported before component usage
3. **Client Components**: Mark with 'use client' when using browser APIs
4. **Dynamic Imports**: Use for code splitting and lazy loading
5. **Environment Variables**: Prefix with `NEXT_PUBLIC_` for client access

### Next.js Specific
- Server Components by default in App Router
- Metadata API for SEO instead of Head component
- Loading and error boundaries per route segment
- Streaming and Suspense for progressive rendering
- Server Actions for mutations

## Architecture Decisions

### Why Next.js App Router?
- **Performance**: React Server Components reduce bundle size
- **SEO**: Built-in SSR/SSG capabilities
- **DX**: File-based routing with TypeScript support
- **Features**: Built-in optimizations (Image, Font, Script)
- **Ecosystem**: Vercel deployment and Edge Functions

### State Management Strategy
- **Server State**: TanStack Query for API data
- **Client State**: Zustand for UI state
- **Form State**: React Hook Form with Zod validation
- **URL State**: Next.js router for navigation state

### Styling Approach
- **Tailwind CSS**: Utility-first for rapid development
- **CSS Modules**: Component-specific styles when needed
- **Radix UI**: Unstyled primitives for accessibility
- **CVA**: Class variance authority for component variants

## Performance Considerations

### Core Web Vitals
- **LCP**: Optimize largest content paint < 2.5s
- **FID**: First input delay < 100ms
- **CLS**: Cumulative layout shift < 0.1
- **INP**: Interaction to Next Paint < 200ms

### Optimization Techniques
```typescript
// Image optimization
import Image from 'next/image'

// Font optimization
import { Inter } from 'next/font/google'
const inter = Inter({ subsets: ['latin'] })

// Dynamic imports
const HeavyComponent = dynamic(() => import('./HeavyComponent'), {
  loading: () => <Skeleton />,
  ssr: false
})

// Prefetching
<Link href="/about" prefetch={true}>
```

### Bundle Optimization
- Tree shaking with proper imports
- Code splitting at route level
- Lazy load below-the-fold content
- Optimize third-party scripts
- Use next/dynamic for heavy components

## Security Notes

### Security Headers
```javascript
// next.config.js
const securityHeaders = [
  {
    key: 'Content-Security-Policy',
    value: "default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline';"
  },
  {
    key: 'X-Frame-Options',
    value: 'DENY'
  },
  {
    key: 'X-Content-Type-Options',
    value: 'nosniff'
  }
]
```

### Best Practices
- Validate all user inputs
- Sanitize data before rendering
- Use CSRF tokens for mutations
- Implement rate limiting on API routes
- Never expose sensitive keys to client
- Use environment variables properly
- Implement proper authentication/authorization

## API Routes

### Route Handler Pattern
```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  // Handle GET request
  return NextResponse.json({ users: [] })
}

export async function POST(request: NextRequest) {
  const body = await request.json()
  // Handle POST request
  return NextResponse.json({ user: body }, { status: 201 })
}
```

### Middleware
```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  // Auth check, redirects, rewrites
  return NextResponse.next()
}

export const config = {
  matcher: ['/api/:path*', '/dashboard/:path*']
}
```

## Deployment

### Vercel Deployment
```bash
# Install Vercel CLI
pnpm i -g vercel

# Deploy to preview
vercel

# Deploy to production
vercel --prod
```

### Environment Configuration
```bash
# .env.local (development)
NEXT_PUBLIC_API_URL=http://localhost:4000
DATABASE_URL=postgresql://...

# .env.production (production)
NEXT_PUBLIC_API_URL=https://api.umemee.com
DATABASE_URL=postgresql://...
```

### Build Configuration
```javascript
// next.config.js
module.exports = {
  output: 'standalone', // For Docker
  images: {
    domains: ['cdn.umemee.com'],
  },
  experimental: {
    serverActions: true,
  },
}
```

## Monitoring

### Performance Monitoring
- Vercel Analytics for Core Web Vitals
- Sentry for error tracking
- LogRocket for session replay
- Custom analytics with PostHog

### Monitoring Setup
```typescript
// lib/monitoring.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0,
})
```

## PWA Configuration

### next-pwa Setup
```javascript
// next.config.js
const withPWA = require('next-pwa')({
  dest: 'public',
  disable: process.env.NODE_ENV === 'development',
  register: true,
  skipWaiting: true,
})

module.exports = withPWA({
  // Next.js config
})
```

### Manifest Configuration
```json
// public/manifest.json
{
  "name": "Umemee",
  "short_name": "Umemee",
  "theme_color": "#000000",
  "background_color": "#ffffff",
  "display": "standalone",
  "scope": "/",
  "start_url": "/",
  "icons": [
    {
      "src": "/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    }
  ]
}
```

## Accessibility

### WCAG 2.1 Compliance
- Semantic HTML structure
- ARIA labels where needed
- Keyboard navigation support
- Focus management
- Color contrast ratios
- Screen reader testing

### Testing Tools
```bash
# Accessibility testing
pnpm test:a11y

# Lighthouse CI
pnpm lighthouse
```

## Future Enhancements

1. Implement Edge Functions for global performance
2. Add Internationalization (i18n) support
3. Integrate AI-powered features
4. Implement real-time collaboration
5. Add offline support with Service Workers
6. Enhance PWA capabilities
7. Implement A/B testing framework
8. Add WebAssembly modules for performance