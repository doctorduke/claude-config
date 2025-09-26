# CLAUDE.md - UI Mobile Package

## Purpose
The ui-mobile package provides a React Native component library optimized for the mobile platform. It includes native-feeling, performant, and accessible components that work seamlessly on both iOS and Android while following the umemee design system.

## Dependencies

### Internal Dependencies
- `@umemee/types` - Component prop types
- `@umemee/utils` - Utility functions

### External Dependencies
- `react-native` - Mobile framework
- `react-native-reanimated` - Animations
- `react-native-gesture-handler` - Gestures
- `react-native-safe-area-context` - Safe areas
- `react-native-svg` - SVG support

## Key Files

```
ui-mobile/
├── src/
│   ├── index.ts           # Main exports
│   ├── components/        # Components
│   │   ├── Button/
│   │   │   ├── Button.tsx
│   │   │   ├── Button.test.tsx
│   │   │   └── Button.styles.ts
│   │   ├── Card/
│   │   ├── BottomSheet/
│   │   └── List/
│   ├── hooks/             # UI hooks
│   │   ├── useTheme.ts
│   │   └── useHaptics.ts
│   ├── theme/             # Theme system
│   │   ├── colors.ts
│   │   ├── spacing.ts
│   │   └── typography.ts
│   └── utils/             # Mobile UI utils
│       ├── platform.ts    # Platform checks
│       └── responsive.ts  # Responsive utils
├── package.json
└── tsconfig.json
```

## Conventions

### Component Structure
```typescript
// Button.tsx
import React, { FC } from 'react'
import {
  TouchableOpacity,
  Text,
  StyleSheet,
  ViewStyle,
  TextStyle,
} from 'react-native'
import Animated, {
  useAnimatedStyle,
  withSpring,
} from 'react-native-reanimated'

interface ButtonProps {
  title: string
  onPress: () => void
  variant?: 'primary' | 'secondary'
  disabled?: boolean
  style?: ViewStyle
}

export const Button: FC<ButtonProps> = ({
  title,
  onPress,
  variant = 'primary',
  disabled,
  style,
}) => {
  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: withSpring(disabled ? 0.95 : 1) }],
  }))

  return (
    <Animated.View style={animatedStyle}>
      <TouchableOpacity
        onPress={onPress}
        disabled={disabled}
        style={[
          styles.button,
          styles[variant],
          disabled && styles.disabled,
          style,
        ]}
        activeOpacity={0.8}
      >
        <Text style={[styles.text, styles[`${variant}Text`]]}>
          {title}
        </Text>
      </TouchableOpacity>
    </Animated.View>
  )
}

const styles = StyleSheet.create({
  button: {
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 8,
  },
  primary: {
    backgroundColor: '#007AFF',
  },
  secondary: {
    backgroundColor: '#F2F2F7',
  },
  disabled: {
    opacity: 0.5,
  },
  text: {
    fontSize: 16,
    fontWeight: '600',
  },
  primaryText: {
    color: '#FFFFFF',
  },
  secondaryText: {
    color: '#000000',
  },
})
```

## Testing

```bash
# Component tests
pnpm test

# Test on iOS simulator
pnpm ios

# Test on Android emulator
pnpm android

# Snapshot tests
pnpm test:snapshot
```

## Common Tasks

### Creating New Components
1. Create component with TypeScript
2. Add platform-specific styles
3. Implement animations with Reanimated
4. Add gesture handlers if needed
5. Write tests
6. Export from index

### Platform-Specific Code
```typescript
import { Platform } from 'react-native'

const styles = StyleSheet.create({
  shadow: {
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: {
        elevation: 4,
      },
    }),
  },
})
```

## Performance Considerations

- Use FlatList/FlashList for long lists
- Implement memo and callbacks properly
- Optimize image loading with FastImage
- Minimize bridge calls
- Use native driver for animations

## Accessibility

```typescript
<TouchableOpacity
  accessible={true}
  accessibilityLabel="Submit button"
  accessibilityHint="Double tap to submit the form"
  accessibilityRole="button"
  accessibilityState={{ disabled }}
>
  {children}
</TouchableOpacity>
```

## Security Notes

- Validate all user inputs
- Use SecureTextEntry for passwords
- Implement biometric authentication
- Handle deep links securely
