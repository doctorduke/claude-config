# CLAUDE.md - Mobile Platform

## Purpose
The mobile platform delivers umemee as a native iOS and Android application using Expo and React Native. This platform provides native performance, offline capabilities, and full access to device features while sharing core business logic with other platforms through the monorepo structure.

## Dependencies

### Internal Dependencies
- `@umemee/ui-mobile` - React Native component library
- `@umemee/types` - Shared TypeScript definitions
- `@umemee/api-client` - API client for backend communication
- `@umemee/config` - Shared configuration
- `@umemee/utils` - Common utility functions
- Core modules from `core-modules/` when implemented

### External Dependencies
- **Expo SDK 50+** - Managed workflow for React Native
- **React Native 0.73+** - Cross-platform mobile framework
- **React Navigation 6+** - Navigation library
- **React Native Reanimated 3** - Animation library
- **React Native Gesture Handler** - Touch gestures
- **React Query/TanStack Query** - Server state management
- **Zustand** - Client state management
- **React Hook Form** - Form management
- **AsyncStorage** - Persistent storage
- **Expo SecureStore** - Secure credential storage

## Key Files

```
mobile/
├── app/                    # Expo Router (if using)
│   ├── _layout.tsx        # Root layout
│   ├── index.tsx          # Entry screen
│   ├── (auth)/            # Auth screens
│   └── (tabs)/            # Tab navigation
├── src/                    # Source code
│   ├── components/        # React Native components
│   ├── screens/           # Screen components
│   ├── navigation/        # Navigation setup
│   ├── hooks/             # Custom hooks
│   ├── services/          # Platform services
│   └── utils/             # Mobile utilities
├── assets/                # Images, fonts, etc.
├── app.json               # Expo configuration
├── eas.json               # EAS Build configuration
├── babel.config.js        # Babel configuration
├── metro.config.js        # Metro bundler config
└── tsconfig.json          # TypeScript configuration
```

## Conventions

### File Naming
- Components: `PascalCase.tsx` (e.g., `UserCard.tsx`)
- Screens: `{Name}Screen.tsx` (e.g., `HomeScreen.tsx`)
- Hooks: `use{Name}.ts` (e.g., `useAuth.ts`)
- Utils: `camelCase.ts` (e.g., `formatDate.ts`)
- Styles: `{Component}.styles.ts` for StyleSheet

### Component Structure
```typescript
// components/UserCard.tsx
import React, { FC } from 'react'
import { View, Text, StyleSheet } from 'react-native'
import { useTheme } from '@/hooks/useTheme'

interface UserCardProps {
  userId: string
  onPress?: () => void
}

export const UserCard: FC<UserCardProps> = ({ userId, onPress }) => {
  const theme = useTheme()
  
  return (
    <View style={styles.container}>
      <Text style={[styles.text, { color: theme.colors.text }]}>
        User {userId}
      </Text>
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    padding: 16,
    borderRadius: 8,
  },
  text: {
    fontSize: 16,
  },
})
```

### Navigation Pattern
```typescript
// navigation/AppNavigator.tsx
import { NavigationContainer } from '@react-navigation/native'
import { createNativeStackNavigator } from '@react-navigation/native-stack'
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs'

const Stack = createNativeStackNavigator()
const Tab = createBottomTabNavigator()
```

## Testing

### Test Setup
```bash
# Run unit tests
pnpm test

# Run tests in watch mode
pnpm test:watch

# Run E2E tests with Detox
pnpm test:e2e:ios
pnpm test:e2e:android

# Generate coverage
pnpm test:coverage
```

### Testing Strategy
- **Unit Tests**: Jest for logic and utilities
- **Component Tests**: React Native Testing Library
- **Integration Tests**: API and service layer testing
- **E2E Tests**: Detox for critical user flows
- **Device Testing**: Physical device testing matrix

### Platform Testing
```bash
# iOS Simulator
pnpm ios

# Android Emulator
pnpm android

# Physical device
pnpm start
# Scan QR code with Expo Go
```

## Common Tasks

### Development
```bash
# Start Expo development server
pnpm start

# Start with clear cache
pnpm start -c

# Run on iOS
pnpm ios

# Run on Android
pnpm android

# Run on specific device
pnpm ios --device "iPhone 15 Pro"
pnpm android --device "Pixel_7"
```

### Building
```bash
# Local build (requires native setup)
pnpm run:ios
pnpm run:android

# EAS Build (cloud)
eas build --platform ios
eas build --platform android
eas build --platform all

# Build for simulator/emulator
eas build --profile preview --platform ios
```

### Managing Dependencies
```bash
# Add Expo SDK package
pnpm expo install expo-camera

# Add React Native package
pnpm add react-native-svg

# Link native dependencies (if needed)
pnpm expo run:ios
pnpm expo run:android
```

## Gotchas

### Common Issues
1. **Metro Cache**: Clear with `npx expo start -c`
2. **Native Module Linking**: Use `expo-dev-client` for custom native code
3. **Platform Differences**: Test on both iOS and Android
4. **Memory Leaks**: Cleanup subscriptions and listeners
5. **Large Lists**: Use FlashList or VirtualizedList
6. **Navigation State**: Persist navigation state for app restoration

### Expo Specific
- Managed workflow limitations (some native modules)
- EAS Build required for production builds
- OTA updates affect versioning strategy
- Custom native code requires development builds

### Performance Pitfalls
- Avoid unnecessary re-renders
- Use React.memo and useMemo appropriately
- Optimize images (use expo-image)
- Minimize bridge calls
- Use InteractionManager for heavy operations

## Architecture Decisions

### Why Expo?
- **Managed Workflow**: Simplified development and deployment
- **EAS Services**: Cloud builds and OTA updates
- **SDK**: Comprehensive set of APIs
- **Cross-Platform**: Write once, run on iOS and Android
- **Developer Experience**: Hot reload, easy testing

### State Management
- **Server State**: TanStack Query with offline support
- **Client State**: Zustand with MMKV persistence
- **Navigation State**: React Navigation with persistence
- **Form State**: React Hook Form with validation

### Data Persistence
```typescript
// Secure storage
import * as SecureStore from 'expo-secure-store'

// General storage
import AsyncStorage from '@react-native-async-storage/async-storage'

// Fast key-value storage
import { MMKV } from 'react-native-mmkv'
const storage = new MMKV()
```

## Performance Considerations

### Startup Performance
- Lazy load screens and heavy components
- Optimize bundle size with Metro config
- Use Hermes JavaScript engine
- Implement splash screen properly
- Defer non-critical initialization

### Runtime Performance
```typescript
// Use FlashList for large lists
import { FlashList } from '@shopify/flash-list'

// Optimize images
import { Image } from 'expo-image'

// Memoize expensive computations
const expensiveValue = useMemo(() => 
  computeExpensive(data), [data]
)

// Use InteractionManager
InteractionManager.runAfterInteractions(() => {
  // Heavy operation
})
```

### Memory Management
- Monitor with Flipper or React DevTools
- Clear unused cached data
- Optimize image sizes and caching
- Cleanup timers and listeners
- Use weak references where appropriate

## Security Notes

### Secure Storage
```typescript
// Store sensitive data
await SecureStore.setItemAsync('token', authToken)

// Retrieve sensitive data
const token = await SecureStore.getItemAsync('token')

// Delete sensitive data
await SecureStore.deleteItemAsync('token')
```

### Security Best Practices
- Never store sensitive data in AsyncStorage
- Implement certificate pinning for API calls
- Obfuscate JavaScript code in production
- Use biometric authentication when available
- Validate deep links and URL schemes
- Implement jailbreak/root detection
- Use encrypted databases (SQLCipher)

### API Security
```typescript
// Certificate pinning example
import { NetworkingModule } from 'react-native'

NetworkingModule.addListener('certificateError', (error) => {
  // Handle certificate validation
})
```

## Platform-Specific Features

### iOS Specific
```typescript
// iOS-specific code
import { Platform } from 'react-native'

if (Platform.OS === 'ios') {
  // iOS-specific implementation
}

// iOS styles
...Platform.select({
  ios: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
  },
})
```

### Android Specific
```typescript
// Android-specific code
if (Platform.OS === 'android') {
  // Android-specific implementation
}

// Android styles
...Platform.select({
  android: {
    elevation: 4,
  },
})
```

## Native Modules

### Using Native Modules
```bash
# Create development build
pnpm expo prebuild

# Install native module
pnpm add react-native-vision-camera

# Rebuild for iOS
pnpm expo run:ios

# Rebuild for Android
pnpm expo run:android
```

### Custom Native Modules
```typescript
// Create native module interface
declare module 'react-native' {
  interface NativeModulesStatic {
    CustomModule: {
      doSomething: () => Promise<string>
    }
  }
}
```

## Deployment

### App Store Deployment
```bash
# Build for App Store
eas build --platform ios --profile production

# Submit to App Store
eas submit --platform ios
```

### Google Play Deployment
```bash
# Build for Google Play
eas build --platform android --profile production

# Submit to Google Play
eas submit --platform android
```

### OTA Updates
```bash
# Publish update
eas update --branch production --message "Bug fixes"

# Publish with specific channel
eas update --channel production
```

## Monitoring

### Crash Reporting
```typescript
// Sentry setup
import * as Sentry from 'sentry-expo'

Sentry.init({
  dsn: 'YOUR_DSN',
  enableInExpoDevelopment: false,
  debug: __DEV__,
})
```

### Analytics
```typescript
// Analytics setup
import * as Analytics from 'expo-analytics'

Analytics.logEvent('screen_view', {
  screen_name: 'Home',
})
```

### Performance Monitoring
- React Native Performance Monitor
- Flipper for debugging
- Custom performance metrics
- Firebase Performance Monitoring

## Offline Support

### Offline Strategy
```typescript
// Network detection
import NetInfo from '@react-native-community/netinfo'

NetInfo.addEventListener(state => {
  console.log('Is connected?', state.isConnected)
})

// Offline queue
import { persistQueryClient } from '@tanstack/react-query-persist-client'
```

### Data Sync
```typescript
// Background sync
import * as BackgroundFetch from 'expo-background-fetch'
import * as TaskManager from 'expo-task-manager'

TaskManager.defineTask('BACKGROUND_SYNC', async () => {
  // Sync data with server
  return BackgroundFetch.Result.NewData
})
```

## Accessibility

### Accessibility Features
```typescript
<View
  accessible={true}
  accessibilityLabel="User profile"
  accessibilityRole="button"
  accessibilityHint="Tap to view user details"
>
  {/* Content */}
</View>
```

### Screen Reader Support
- Use semantic accessibility props
- Test with VoiceOver (iOS) and TalkBack (Android)
- Provide proper labels and hints
- Group related elements
- Handle focus management

## Push Notifications

### Setup Push Notifications
```typescript
import * as Notifications from 'expo-notifications'

// Request permissions
const { status } = await Notifications.requestPermissionsAsync()

// Get push token
const token = await Notifications.getExpoPushTokenAsync()

// Handle notifications
Notifications.addNotificationReceivedListener(notification => {
  // Handle notification
})
```

## Deep Linking

### Configure Deep Links
```json
// app.json
{
  "expo": {
    "scheme": "umemee",
    "android": {
      "intentFilters": [
        {
          "action": "VIEW",
          "data": [{
            "scheme": "umemee",
            "host": "*"
          }]
        }
      ]
    }
  }
}
```

## Future Enhancements

1. Implement biometric authentication
2. Add AR capabilities with expo-camera
3. Integrate native widgets
4. Implement background tasks
5. Add Apple Watch / WearOS companion apps
6. Enhance offline capabilities
7. Implement end-to-end encryption
8. Add voice commands and Siri/Google Assistant integration