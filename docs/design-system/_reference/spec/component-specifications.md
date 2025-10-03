# Component Specifications

## Overview

This document defines the specifications for reusable UI components in the umemee design system. Each component includes visual specifications, interaction patterns, accessibility requirements, and implementation guidelines.

## Button Component

### Visual Specifications

```typescript
interface ButtonSpec {
  // Sizes
  sizes: {
    small: { height: '32px', padding: '6px 12px', fontSize: '14px' };
    medium: { height: '40px', padding: '8px 16px', fontSize: '16px' };
    large: { height: '48px', padding: '12px 24px', fontSize: '18px' };
  };

  // Variants
  variants: {
    primary: {
      backgroundColor: 'var(--color-primary-500)';
      color: 'var(--color-neutral-50)';
      border: '1px solid var(--color-primary-600)';
    };
    secondary: {
      backgroundColor: 'transparent';
      color: 'var(--color-primary-500)';
      border: '1px solid var(--color-primary-500)';
    };
    ghost: {
      backgroundColor: 'transparent';
      color: 'var(--color-primary-500)';
      border: 'none';
    };
  };

  // States
  states: {
    hover: { opacity: '0.9', transform: 'translateY(-1px)' };
    active: { opacity: '0.8', transform: 'translateY(0)' };
    disabled: { opacity: '0.5', cursor: 'not-allowed' };
    loading: { opacity: '0.7', cursor: 'wait' };
  };
}
```

### Interaction Patterns

- **Click**: Primary action trigger
- **Hover**: Visual feedback with subtle animation
- **Focus**: Keyboard navigation indicator
- **Loading**: Disabled state with spinner
- **Disabled**: Non-interactive state

### Accessibility Requirements

- **Keyboard Navigation**: Tab-accessible, Enter/Space activation
- **Screen Readers**: Proper ARIA labels and roles
- **Focus Management**: Visible focus indicators
- **Color Contrast**: Meets WCAG 2.1 AA standards

### Implementation Examples

#### Web (React)

```tsx
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'ghost';
  size?: 'small' | 'medium' | 'large';
  disabled?: boolean;
  loading?: boolean;
  children: React.ReactNode;
  onClick?: () => void;
}

const Button: React.FC<ButtonProps> = ({
  variant = 'primary',
  size = 'medium',
  disabled = false,
  loading = false,
  children,
  onClick
}) => {
  return (
    <button
      className={`btn btn-${variant} btn-${size}`}
      disabled={disabled || loading}
      onClick={onClick}
      aria-disabled={disabled || loading}
    >
      {loading && <Spinner size="small" />}
      {children}
    </button>
  );
};
```

#### Mobile (React Native)

```tsx
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'ghost';
  size?: 'small' | 'medium' | 'large';
  disabled?: boolean;
  loading?: boolean;
  children: React.ReactNode;
  onPress?: () => void;
}

const Button: React.FC<ButtonProps> = ({
  variant = 'primary',
  size = 'medium',
  disabled = false,
  loading = false,
  children,
  onPress
}) => {
  return (
    <TouchableOpacity
      style={[styles.button, styles[variant], styles[size]]}
      disabled={disabled || loading}
      onPress={onPress}
      accessibilityRole="button"
      accessibilityState={{ disabled: disabled || loading }}
    >
      {loading && <ActivityIndicator size="small" color="white" />}
      <Text style={[styles.text, styles[`${variant}Text`]]}>
        {children}
      </Text>
    </TouchableOpacity>
  );
};
```

## Input Component

### Visual Specifications

```typescript
interface InputSpec {
  // Sizes
  sizes: {
    small: { height: '32px', padding: '6px 12px', fontSize: '14px' };
    medium: { height: '40px', padding: '8px 16px', fontSize: '16px' };
    large: { height: '48px', padding: '12px 24px', fontSize: '18px' };
  };

  // States
  states: {
    default: {
      border: '1px solid var(--color-neutral-300)';
      backgroundColor: 'var(--color-neutral-50)';
    };
    focus: {
      border: '2px solid var(--color-primary-500)';
      boxShadow: '0 0 0 3px var(--color-primary-100)';
    };
    error: {
      border: '2px solid var(--color-error-500)';
      backgroundColor: 'var(--color-error-50)';
    };
    disabled: {
      backgroundColor: 'var(--color-neutral-100)';
      color: 'var(--color-neutral-400)';
      cursor: 'not-allowed';
    };
  };
}
```

### Interaction Patterns

- **Focus**: Border color change and shadow
- **Typing**: Real-time validation feedback
- **Error**: Red border and error message display
- **Success**: Green border for valid input
- **Disabled**: Grayed out and non-interactive

### Accessibility Requirements

- **Labels**: Proper label association
- **Error Messages**: ARIA-describedby for error states
- **Keyboard Navigation**: Tab-accessible
- **Screen Readers**: Proper announcements for state changes

## Card Component

### Visual Specifications

```typescript
interface CardSpec {
  // Variants
  variants: {
    default: {
      backgroundColor: 'var(--color-neutral-50)';
      border: '1px solid var(--color-neutral-200)';
      borderRadius: '8px';
      boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)';
    };
    elevated: {
      backgroundColor: 'var(--color-neutral-50)';
      border: 'none';
      borderRadius: '12px';
      boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)';
    };
    outlined: {
      backgroundColor: 'transparent';
      border: '2px solid var(--color-neutral-300)';
      borderRadius: '8px';
      boxShadow: 'none';
    };
  };

  // Padding
  padding: {
    small: '12px';
    medium: '16px';
    large: '24px';
  };
}
```

### Layout Patterns

- **Header**: Title and optional actions
- **Content**: Main card content
- **Footer**: Actions and metadata
- **Media**: Images, videos, or icons

### Accessibility Requirements

- **Semantic HTML**: Proper heading hierarchy
- **Focus Management**: Keyboard navigation support
- **Screen Readers**: Proper content structure

## Navigation Component

### Visual Specifications

```typescript
interface NavigationSpec {
  // Layout
  layout: {
    horizontal: {
      display: 'flex';
      flexDirection: 'row';
      alignItems: 'center';
      gap: '24px';
    };
    vertical: {
      display: 'flex';
      flexDirection: 'column';
      gap: '8px';
    };
  };

  // Link States
  linkStates: {
    default: {
      color: 'var(--color-neutral-700)';
      textDecoration: 'none';
    };
    hover: {
      color: 'var(--color-primary-500)';
      textDecoration: 'underline';
    };
    active: {
      color: 'var(--color-primary-600)';
      fontWeight: '600';
    };
  };
}
```

### Interaction Patterns

- **Hover**: Color change and underline
- **Active**: Bold text and primary color
- **Focus**: Keyboard navigation indicator
- **Mobile**: Collapsible menu for small screens

### Accessibility Requirements

- **Keyboard Navigation**: Tab-accessible links
- **ARIA Labels**: Proper navigation landmarks
- **Screen Readers**: Clear navigation structure
- **Skip Links**: Quick access to main content

## Component Testing

### Visual Regression Testing

```typescript
// Example visual regression test
import { render, screen } from '@testing-library/react';
import { Button } from './Button';

test('Button renders correctly', () => {
  render(<Button variant="primary" size="medium">Click me</Button>);

  const button = screen.getByRole('button', { name: /click me/i });
  expect(button).toBeInTheDocument();
  expect(button).toHaveClass('btn-primary', 'btn-medium');
});
```

### Accessibility Testing

```typescript
// Example accessibility test
import { render, screen } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import { Button } from './Button';

expect.extend(toHaveNoViolations);

test('Button has no accessibility violations', async () => {
  const { container } = render(
    <Button variant="primary">Click me</Button>
  );

  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

### Cross-Platform Testing

- **Web**: Chrome, Firefox, Safari, Edge
- **Mobile**: iOS Safari, Android Chrome
- **Desktop**: Electron/Tauri applications
- **Responsive**: Various screen sizes and orientations
