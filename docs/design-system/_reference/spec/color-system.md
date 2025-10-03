# Color System Specification

## Overview

The umemee color system provides a comprehensive palette that works across all platforms while maintaining brand consistency and accessibility standards.

## Color Palette

### Primary Colors

```css
:root {
  /* Primary Brand Colors */
  --color-primary-50: #f0f9ff;
  --color-primary-100: #e0f2fe;
  --color-primary-200: #bae6fd;
  --color-primary-300: #7dd3fc;
  --color-primary-400: #38bdf8;
  --color-primary-500: #0ea5e9;  /* Base primary */
  --color-primary-600: #0284c7;
  --color-primary-700: #0369a1;
  --color-primary-800: #075985;
  --color-primary-900: #0c4a6e;
  --color-primary-950: #082f49;

  /* Secondary Colors */
  --color-secondary-50: #fdf4ff;
  --color-secondary-100: #fae8ff;
  --color-secondary-200: #f5d0fe;
  --color-secondary-300: #f0abfc;
  --color-secondary-400: #e879f9;
  --color-secondary-500: #d946ef;  /* Base secondary */
  --color-secondary-600: #c026d3;
  --color-secondary-700: #a21caf;
  --color-secondary-800: #86198f;
  --color-secondary-900: #701a75;
  --color-secondary-950: #4a044e;
}
```

### Neutral Colors

```css
:root {
  /* Neutral/Gray Scale */
  --color-neutral-50: #f8fafc;
  --color-neutral-100: #f1f5f9;
  --color-neutral-200: #e2e8f0;
  --color-neutral-300: #cbd5e1;
  --color-neutral-400: #94a3b8;
  --color-neutral-500: #64748b;  /* Base neutral */
  --color-neutral-600: #475569;
  --color-neutral-700: #334155;
  --color-neutral-800: #1e293b;
  --color-neutral-900: #0f172a;
  --color-neutral-950: #020617;
}
```

### Semantic Colors

```css
:root {
  /* Success Colors */
  --color-success-50: #f0fdf4;
  --color-success-500: #22c55e;
  --color-success-600: #16a34a;
  --color-success-700: #15803d;

  /* Warning Colors */
  --color-warning-50: #fffbeb;
  --color-warning-500: #f59e0b;
  --color-warning-600: #d97706;
  --color-warning-700: #b45309;

  /* Error Colors */
  --color-error-50: #fef2f2;
  --color-error-500: #ef4444;
  --color-error-600: #dc2626;
  --color-error-700: #b91c1c;

  /* Info Colors */
  --color-info-50: #eff6ff;
  --color-info-500: #3b82f6;
  --color-info-600: #2563eb;
  --color-info-700: #1d4ed8;
}
```

## Usage Guidelines

### Primary Color Usage

- **Primary-500**: Main brand color for CTAs, links, and key UI elements
- **Primary-600**: Hover states and active elements
- **Primary-700**: Pressed states and emphasis
- **Primary-50-100**: Background tints and subtle highlights

### Neutral Color Usage

- **Neutral-900**: Primary text color
- **Neutral-700**: Secondary text color
- **Neutral-500**: Tertiary text and placeholders
- **Neutral-200**: Borders and dividers
- **Neutral-50**: Background colors

### Semantic Color Usage

- **Success**: Confirmation messages, success states, positive actions
- **Warning**: Caution messages, pending states, attention-grabbing elements
- **Error**: Error messages, destructive actions, validation failures
- **Info**: Informational messages, help text, neutral information

## Accessibility Standards

### Contrast Ratios

All color combinations must meet WCAG 2.1 AA standards:

- **Normal text**: 4.5:1 contrast ratio minimum
- **Large text**: 3:1 contrast ratio minimum
- **UI components**: 3:1 contrast ratio minimum

### Color Blindness Considerations

- Never rely solely on color to convey information
- Use patterns, icons, or text labels alongside color
- Test with color blindness simulators
- Provide alternative visual indicators

## Platform Implementation

### Web (CSS Custom Properties)

```css
.button-primary {
  background-color: var(--color-primary-500);
  color: var(--color-neutral-50);
  border: 1px solid var(--color-primary-600);
}

.button-primary:hover {
  background-color: var(--color-primary-600);
}
```

### Mobile (React Native)

```typescript
const colors = {
  primary: {
    50: '#f0f9ff',
    500: '#0ea5e9',
    600: '#0284c7',
    // ... rest of palette
  },
  neutral: {
    50: '#f8fafc',
    // ... rest of palette
  }
};

const styles = StyleSheet.create({
  buttonPrimary: {
    backgroundColor: colors.primary[500],
  },
  buttonPrimaryText: {
    color: colors.neutral[50],
  },
});
```

### Design Tokens (JSON)

```json
{
  "color": {
    "primary": {
      "50": { "value": "#f0f9ff", "type": "color" },
      "500": { "value": "#0ea5e9", "type": "color" },
      "600": { "value": "#0284c7", "type": "color" }
    },
    "semantic": {
      "success": { "value": "#22c55e", "type": "color" },
      "warning": { "value": "#f59e0b", "type": "color" },
      "error": { "value": "#ef4444", "type": "color" }
    }
  }
}
```

## Dark Mode Support

### Dark Mode Color Adjustments

```css
@media (prefers-color-scheme: dark) {
  :root {
    --color-primary-500: #38bdf8;  /* Lighter for dark backgrounds */
    --color-neutral-900: #f8fafc;  /* Inverted text colors */
    --color-neutral-50: #0f172a;   /* Inverted backgrounds */
  }
}
```

### Dark Mode Guidelines

- Use lighter primary colors for better contrast on dark backgrounds
- Invert neutral color scales (dark text on light backgrounds)
- Maintain semantic color meanings across themes
- Test all color combinations in both light and dark modes

## Color Testing

### Automated Testing

```typescript
// Example color contrast testing
import { getContrastRatio } from 'color-contrast';

const testContrast = (foreground: string, background: string) => {
  const ratio = getContrastRatio(foreground, background);
  expect(ratio).toBeGreaterThanOrEqual(4.5); // WCAG AA standard
};
```

### Manual Testing Checklist

- [ ] All text meets contrast requirements
- [ ] Color combinations work for colorblind users
- [ ] Dark mode colors are properly adjusted
- [ ] Semantic colors convey correct meaning
- [ ] Brand colors maintain consistency across platforms
