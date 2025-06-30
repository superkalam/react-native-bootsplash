# State Management

The `react-native-bootsplash` package now supports dynamic state management with native text rendering. The status text is automatically displayed by the native bootsplash without requiring manual JavaScript rendering.

## Available States

- **default**: The standard bootsplash with no status text
- **updating**: Shows "updating..." text at the bottom of the bootsplash
- **updated**: Shows "updated ✅" text at the bottom of the bootsplash

## Usage

### Basic Setup

The `useHideAnimation` hook works exactly as before - no changes needed to your existing implementation:

```tsx
import BootSplash from "react-native-bootsplash";
import { Animated } from "react-native";

const { container, logo, brand } = BootSplash.useHideAnimation({
  manifest: require("./assets/bootsplash/manifest.json"),
  logo: require("./assets/bootsplash/logo.png"),
  animate: () => {
    // Your animation logic
  },
});

// Render as usual - status text is handled natively
return (
  <Animated.View {...container}>
    <Animated.Image {...logo} />
    <Animated.Image {...brand} />
  </Animated.View>
);
```

### Changing States

Use the `setState` function to change the bootsplash state. The text will automatically appear/disappear natively:

```tsx
import BootSplash from "react-native-bootsplash";

// Set to updating state
BootSplash.setState("updating");

// Set to updated state after some operation
setTimeout(() => {
  BootSplash.setState("updated");
}, 2000);

// Return to default state (hides text)
BootSplash.setState("default");
```

### Complete Example

```tsx
import { useState } from "react";
import { Animated } from "react-native";
import BootSplash from "react-native-bootsplash";

export const AnimatedBootSplash = ({ onAnimationEnd }) => {
  const [opacity] = useState(() => new Animated.Value(1));

  const { container, logo } = BootSplash.useHideAnimation({
    manifest: require("../assets/bootsplash/manifest.json"),
    logo: require("../assets/bootsplash/logo.png"),
    animate: () => {
      // Start with updating state
      BootSplash.setState("updating");

      // Simulate some loading process
      setTimeout(() => {
        BootSplash.setState("updated");
      }, 1500);

      // Hide after showing updated state
      setTimeout(() => {
        Animated.timing(opacity, {
          toValue: 0,
          duration: 500,
        }).start(onAnimationEnd);
      }, 3000);
    },
  });

  // No need to manually render status text - it's handled natively
  return (
    <Animated.View {...container} style={[container.style, { opacity }]}>
      <Animated.Image {...logo} />
    </Animated.View>
  );
};
```

## Native Implementation

The status text is now rendered natively on each platform:

- **iOS**: Uses a `UILabel` added to the storyboard view with Auto Layout constraints
- **Android**: Uses a `TextView` in a custom layout with proper positioning
- **Web**: Dynamically creates and positions DOM elements

This provides:

- ✅ Better performance (no JavaScript bridge calls for text updates)
- ✅ Native look and feel
- ✅ Automatic dark mode support
- ✅ Proper text positioning relative to brand images
- ✅ No additional rendering code needed in your components

## Platform Support

This state management feature works on:

- ✅ iOS (Native UILabel)
- ✅ Android (Native TextView)
- ✅ Web (DOM manipulation)

The implementation is fully native, providing optimal performance and integration with each platform's UI system.
