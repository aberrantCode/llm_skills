---
name: react-native
description: React Native and Expo patterns, platform-specific code, list performance, animations, and navigation best practices
---

# React Native Skill

*Load with: base.md + typescript.md*

---

## Project Structure

```
project/
├── src/
│   ├── core/                   # Pure business logic (no React)
│   │   ├── types.ts
│   │   └── services/
│   ├── components/             # Reusable UI components
│   │   ├── Button/
│   │   │   ├── Button.tsx
│   │   │   ├── Button.test.tsx
│   │   │   └── index.ts
│   │   └── index.ts            # Barrel export
│   ├── screens/                # Screen components
│   │   ├── Home/
│   │   │   ├── HomeScreen.tsx
│   │   │   ├── useHome.ts      # Screen-specific hook
│   │   │   └── index.ts
│   │   └── index.ts
│   ├── navigation/             # Navigation configuration
│   ├── hooks/                  # Shared custom hooks
│   ├── store/                  # State management
│   └── utils/                  # Utilities
├── __tests__/
├── android/
├── ios/
└── CLAUDE.md
```

---

## Component Patterns

### Functional Components Only
```typescript
interface ButtonProps {
  label: string;
  onPress: () => void;
  disabled?: boolean;
}

export function Button({ label, onPress, disabled = false }: ButtonProps): JSX.Element {
  return (
    <Pressable onPress={onPress} disabled={disabled}>
      <Text>{label}</Text>
    </Pressable>
  );
}
```

### Extract Logic to Hooks
```typescript
// useHome.ts — all logic here
export function useHome() {
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    setLoading(true);
    const data = await fetchItems();
    setItems(data);
    setLoading(false);
  }, []);

  return { items, loading, refresh };
}

// HomeScreen.tsx — pure presentation
export function HomeScreen(): JSX.Element {
  const { items, loading, refresh } = useHome();
  return <ItemList items={items} loading={loading} onRefresh={refresh} />;
}
```

### Props Interface Always Explicit
```typescript
interface ItemCardProps {
  item: Item;
  onPress: (id: string) => void;
}

export function ItemCard({ item, onPress }: ItemCardProps): JSX.Element {
  // ...
}
```

### Conditional Rendering — No Falsy `&&`
```typescript
// Bad — renders "0" when count is 0
{count && <Badge count={count} />}

// Good — always explicit
{count > 0 && <Badge count={count} />}
{isVisible ? <Modal /> : null}
```

---

## State Management

### Local State First
```typescript
// Start with useState, escalate only when needed
const [value, setValue] = useState('');
```

### Minimize State Subscriptions
Subscribe to the smallest slice of state possible — avoid subscribing to entire store objects when you only need one field.

### Zustand for Global State
```typescript
// store/useAppStore.ts
import { create } from 'zustand';

interface AppState {
  user: User | null;
  setUser: (user: User | null) => void;
}

export const useAppStore = create<AppState>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
}));
```

### React Query for Server State
```typescript
export function useItems() {
  return useQuery({ queryKey: ['items'], queryFn: fetchItems });
}

export function useCreateItem() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: createItem,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['items'] }),
  });
}
```

### Show Fallback on First Render
When data is loading, always show a skeleton or fallback — never render empty containers that cause layout shift.

---

## List Performance (CRITICAL)

High-performance lists are the most common React Native performance bottleneck.

### Use FlashList for Large Lists
`FlashList` (from `@shopify/flash-list`) recycles cells and is dramatically faster than `FlatList` for lists with many items.

```typescript
import { FlashList } from '@shopify/flash-list';

<FlashList
  data={items}
  renderItem={({ item }) => <ItemCard item={item} />}
  estimatedItemSize={80}
  keyExtractor={(item) => item.id}
/>
```

### Memoize List Item Components
```typescript
// Good — component only re-renders when its props change
const ItemCard = React.memo(({ item, onPress }: ItemCardProps) => (
  <Pressable onPress={() => onPress(item.id)}>
    <Text>{item.title}</Text>
  </Pressable>
));
```

### Stabilize Callback References
```typescript
// Bad — new function on every render causes all items to re-render
<FlashList renderItem={({ item }) => <ItemCard onPress={(id) => handlePress(id)} />} />

// Good — stable reference via useCallback
const handlePress = useCallback((id: string) => {
  // ...
}, []);
<FlashList renderItem={({ item }) => <ItemCard onPress={handlePress} />} />
```

### Avoid Inline Objects in List Items
```typescript
// Bad — new object reference on every render
<ItemCard style={{ padding: 8 }} />

// Good — stable reference
const styles = StyleSheet.create({ card: { padding: 8 } });
<ItemCard style={styles.card} />
```

### Use Item Types for Heterogeneous Lists
When a list contains different item shapes, use `getItemType` to let FlashList reuse the correct cell recycling pool.

```typescript
<FlashList
  getItemType={(item) => item.type}  // 'header' | 'row' | 'footer'
  renderItem={({ item }) => {
    if (item.type === 'header') return <SectionHeader />;
    return <ItemRow item={item} />;
  }}
/>
```

### Optimize Images in Lists
Use `expo-image` (not `Image` from react-native) — it supports memory/disk caching, blurhash placeholders, and is significantly more performant in lists.

```typescript
import { Image } from 'expo-image';

<Image source={{ uri: item.imageUrl }} style={styles.thumbnail} contentFit="cover" />
```

---

## Animations

### Animate Only `transform` and `opacity`
GPU-accelerated properties only. Never animate `width`, `height`, `top`, `left`, `margin`, or `padding` — these trigger layout recalculation on the JS thread.

```typescript
// Good — GPU properties
const animatedStyle = useAnimatedStyle(() => ({
  transform: [{ scale: scale.value }, { translateY: translateY.value }],
  opacity: opacity.value,
}));
```

### Use `useDerivedValue` for Computed Animations
```typescript
// Good — computed on the UI thread, no JS bridge overhead
const rotation = useDerivedValue(() => `${progress.value * 360}deg`);
```

### Prefer `Gesture.Tap` over `Pressable` in Animated Contexts
When paired with Reanimated, `Gesture.Tap` from `react-native-gesture-handler` avoids the JS bridge entirely:

```typescript
import { Gesture, GestureDetector } from 'react-native-gesture-handler';

const tap = Gesture.Tap().onEnd(() => {
  scale.value = withSpring(1);
});

<GestureDetector gesture={tap}>
  <Animated.View style={animatedStyle} />
</GestureDetector>
```

---

## Navigation

### Use Native Navigators
Prefer `@react-navigation/native-stack` and `@react-navigation/bottom-tabs` over the JS-based equivalents. Native navigators use platform navigation components and are hardware-accelerated.

```typescript
import { createNativeStackNavigator } from '@react-navigation/native-stack';
const Stack = createNativeStackNavigator();

<Stack.Navigator>
  <Stack.Screen name="Home" component={HomeScreen} />
  <Stack.Screen name="Detail" component={DetailScreen} />
</Stack.Navigator>
```

---

## UI Patterns

### Images — Always `expo-image`
```typescript
import { Image } from 'expo-image';
// Supports blurhash placeholders, caching, content-fit
<Image source={uri} placeholder={blurhash} contentFit="cover" />
```

### Pressable over TouchableOpacity
`Pressable` is the current recommended primitive — it supports `pressed` state, hit slop, and is more composable.

```typescript
<Pressable
  onPress={onPress}
  style={({ pressed }) => [styles.button, pressed && styles.buttonPressed]}
  hitSlop={8}
>
  <Text>Press me</Text>
</Pressable>
```

### Safe Areas in ScrollViews
```typescript
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export function Screen() {
  const insets = useSafeAreaInsets();
  return (
    <ScrollView contentContainerStyle={{ paddingBottom: insets.bottom }}>
      {/* content */}
    </ScrollView>
  );
}
```

### Native Modals When Possible
Use `Modal` from react-native or platform-specific sheet libraries over JS-based modal stacks — native modals participate in the OS accessibility and gesture systems.

### Measure Views with `onLayout`
```typescript
// Good — layout callback, no layout thrash
<View onLayout={(e) => setHeight(e.nativeEvent.layout.height)} />

// Bad — synchronous measure() forces a layout pass
ref.current?.measure((x, y, w, h) => setHeight(h));
```

### Styling
Use `StyleSheet.create` for static styles, or Nativewind for Tailwind-style utility classes. Never use inline style objects in render paths that re-render frequently.

---

## Platform-Specific Code

### `Platform.select` for Minor Differences
```typescript
import { Platform } from 'react-native';

const styles = StyleSheet.create({
  shadow: Platform.select({
    ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.1 },
    android: { elevation: 2 },
  }),
});
```

### Separate Files for Complex Differences
```
Component/
├── Component.tsx          # Shared logic
├── Component.ios.tsx      # iOS-specific
├── Component.android.tsx  # Android-specific
└── index.ts
```

---

## Testing

### Component Testing with React Native Testing Library
```typescript
import { render, fireEvent } from '@testing-library/react-native';
import { Button } from './Button';

describe('Button', () => {
  it('calls onPress when pressed', () => {
    const onPress = jest.fn();
    const { getByText } = render(<Button label="Click me" onPress={onPress} />);
    fireEvent.press(getByText('Click me'));
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('does not call onPress when disabled', () => {
    const onPress = jest.fn();
    const { getByText } = render(<Button label="Click me" onPress={onPress} disabled />);
    fireEvent.press(getByText('Click me'));
    expect(onPress).not.toHaveBeenCalled();
  });
});
```

### Hook Testing
```typescript
import { renderHook, act } from '@testing-library/react-hooks';
import { useCounter } from './useCounter';

it('increments counter', () => {
  const { result } = renderHook(() => useCounter());
  act(() => result.current.increment());
  expect(result.current.count).toBe(1);
});
```

---

## Monorepo Configuration

### Keep Native Dependencies in the App Package
Native modules (those with `android/` or `ios/` directories) must live in the app package, not in shared packages. Metro can't hoist native modules.

### Single Dependency Versions Across Packages
Use a single version of React Native and its ecosystem packages across all packages in the monorepo. Version mismatches cause subtle runtime errors.

### Custom Fonts via Config Plugins
```typescript
// app.config.ts
export default {
  plugins: [
    ['expo-font', { fonts: ['./assets/fonts/Inter.ttf'] }]
  ]
};
```

### Design System Import Organization
```typescript
// Good — explicit, tree-shakeable
import { Button } from '@company/design-system/button';

// Avoid — barrel imports can include large unused chunks
import { Button } from '@company/design-system';
```

---

## Anti-Patterns

| ❌ Avoid | ✅ Instead |
|----------|-----------|
| Inline styles in hot paths | `StyleSheet.create` or Nativewind |
| Logic in render functions | Extract to hooks |
| Deep component nesting | Flatten hierarchy |
| Anonymous functions in list item props | `useCallback` with stable deps |
| Index as key in lists | Stable IDs |
| Direct state mutation | Always use setter |
| Mixing business logic with UI | Keep `core/` pure |
| Ignoring TypeScript errors | Fix them |
| Large components | Split into smaller pieces |
| `FlatList` for large data sets | `FlashList` |
| Animating layout properties | Animate only `transform`/`opacity` |
| `TouchableOpacity` | `Pressable` |
| `measure()` for view dimensions | `onLayout` |
| Falsy `&&` for conditional rendering | Ternary or explicit comparison |
| `Image` from react-native | `expo-image` |

## Diagram

[View diagram](diagram.html)
