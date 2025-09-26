# CLAUDE.md - UI Web Package

## Purpose
The ui-web package provides a comprehensive React component library optimized for web platforms (Next.js web app and Tauri desktop app). It includes accessible, performant, and customizable components following the umemee design system.

## Dependencies

### Internal Dependencies
- `@umemee/types` - Component prop types
- `@umemee/utils` - Utility functions

### External Dependencies
- `react` - UI framework
- `@radix-ui/react-*` - Headless component primitives
- `framer-motion` - Animation library
- `class-variance-authority` - Component variants
- `tailwindcss` - Styling framework

## Key Files

```
ui-web/
├── src/
│   ├── index.ts           # Main exports
│   ├── components/        # Components
│   │   ├── Button/
│   │   │   ├── Button.tsx
│   │   │   ├── Button.stories.tsx
│   │   │   └── Button.test.tsx
│   │   ├── Card/
│   │   ├── Dialog/
│   │   └── Form/
│   ├── hooks/             # UI hooks
│   │   ├── useTheme.ts
│   │   └── useMediaQuery.ts
│   ├── styles/            # Styles
│   │   ├── globals.css
│   │   └── themes.ts
│   └── utils/             # UI utilities
│       ├── cn.ts          # Class names
│       └── variants.ts    # CVA helpers
├── .storybook/            # Storybook config
├── package.json
└── tsconfig.json
```

## Conventions

### Component Structure
```typescript
// Button.tsx
import { forwardRef } from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '../../utils/cn'

const buttonVariants = cva(
  'base-classes',
  {
    variants: {
      variant: {
        primary: 'primary-classes',
        secondary: 'secondary-classes',
      },
      size: {
        sm: 'small-classes',
        md: 'medium-classes',
      },
    },
    defaultVariants: {
      variant: 'primary',
      size: 'md',
    },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, ...props }, ref) => {
    return (
      <button
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)

Button.displayName = 'Button'
```

## Testing

```bash
# Component tests
pnpm test

# Storybook
pnpm storybook

# Visual regression tests
pnpm test:visual

# Accessibility tests
pnpm test:a11y
```

## Common Tasks

### Creating New Components
1. Create component directory
2. Implement component with variants
3. Add Storybook stories
4. Write tests
5. Export from index

### Theming
- Use CSS variables for colors
- Support dark/light modes
- Allow custom theme overrides
- Maintain consistent spacing

## Performance Considerations

- Use React.memo for expensive components
- Implement virtual scrolling for lists
- Lazy load heavy components
- Optimize bundle size with tree-shaking

## Accessibility

- Use semantic HTML
- Include ARIA attributes
- Ensure keyboard navigation
- Test with screen readers
- Maintain focus management

## Security Notes

- Sanitize user-generated content
- Prevent XSS in dynamic styles
- Use CSP-compatible styling
