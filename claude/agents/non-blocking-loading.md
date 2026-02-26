# Non-Blocking Loading Pattern

Apply the non-blocking loading animation pattern to pages that should show skeleton UI during data fetching instead of blocking the entire screen.

## When to Use

Use this pattern for:
- Data fetching on page load (read operations)
- Refresh/reload operations
- Pagination
- Any operation where users should see skeleton components underneath

**Do NOT use for:**
- Write operations (save, create, update, delete) - those should use blocking loading

## Reference Implementation

`nr_webui/src/pages/companies/CompanyRegistryPage.tsx:235-298`

## Instructions

Apply the following changes to the target page:

### 1. Disable WebUIPage Fullscreen Overlay

Add `disableLoadingOverlay={true}` to `WebUIPage` props:

```tsx
<WebUIPage
  headerIcon={<Icon className="h-6 w-6" />}
  headerTitle="Page Title"
  headerSubtitle="Description"
  pageTitle="Page Title - NeuroRep"
  pageWidth="xl"
  disableLoadingOverlay={true}  // ← Add this
>
```

### 2. Create Relative Container for Content

Wrap the page content in a relative container with min-height:

```tsx
<div className="relative min-h-[400px]">
  <div className="space-y-6">
    {/* Existing content here */}
  </div>
</div>
```

### 3. Add Content-Scoped LoadingAnimation

Import and add LoadingAnimation component after the content container (but inside the relative container):

```tsx
import { LoadingAnimation } from "@neurorep/ui";

// Inside the relative container, after content
<LoadingAnimation
  isOpen={isLoading && !isError}
  fullScreen={false}
  message="Loading [resource name]..."
  backdrop="none"
  size="md"
/>
```

### 4. Ensure DataTable Receives Loading State

Pass loading state to DataTable to show skeletons:

```tsx
<DataTable
  columns={columns}
  data={data}
  loading={isLoading}  // ← Ensure this is passed
  // ... other props
/>
```

### 5. Handle Error and Empty States Properly

**CRITICAL:** DataTable must render during loading to show skeletons!

```tsx
{error ? (
  /* Error state */
  <ErrorDisplay />
) : !isLoading && data.length === 0 ? (
  /* Empty state - only after loading completes */
  <EmptyState />
) : (
  /* DataTable - renders during loading to show skeletons */
  <DataTable loading={isLoading} data={data} ... />
)}
```

**Why this pattern matters:**
- If DataTable only renders when `data.length > 0`, it won't exist during initial load
- Without a rendered DataTable, there are no skeleton rows to display
- The loading animation will show over empty space instead of skeletons

**❌ WRONG - DataTable only renders with data:**
```tsx
{data.length > 0 && <DataTable loading={isLoading} ... />}
// During initial load: data = [] → DataTable doesn't render → no skeletons!
```

**✅ CORRECT - DataTable always renders (except error/empty):**
```tsx
{error ? <Error /> : !isLoading && data.length === 0 ? <Empty /> : <DataTable loading={isLoading} />}
// During load: DataTable renders with loading={true} → shows skeletons!
```

## Complete Example Pattern

```tsx
<WebUIPage
  disableLoadingOverlay={true}
  // ... other props
>
  <div className="relative min-h-[400px]">
    <div className="space-y-6">
      {error ? (
        /* Error state */
        <ErrorDisplay error={error} onRetry={refetch} />
      ) : !isLoading && data.length === 0 ? (
        /* Empty state - only shown after loading completes */
        <EmptyStateDisplay />
      ) : (
        /* DataTable - always renders to show skeletons during loading */
        <DataTable loading={isLoading} data={data} columns={columns} />
      )}
    </div>

    <LoadingAnimation
      isOpen={isLoading && !error}
      fullScreen={false}
      message="Loading data..."
      backdrop="none"
      size="md"
    />
  </div>
</WebUIPage>
```

## Key Points

- `fullScreen={false}` - Keeps animation in the relative container
- `backdrop="none"` - Fully transparent backdrop (shows skeletons underneath)
  - **IMPORTANT:** Use `"none"`, NOT `"transparent"` - `"transparent"` applies a 50% opacity background that blocks the skeleton view
  - Available options: `"blur"`, `"solid"`, `"transparent"`, `"dark"`, `"none"`
  - Only `"none"` allows skeletons to be fully visible
- Animation overlays on content, navigation remains accessible
- Always exclude error states from loading animation (`isLoading && !isError`)
- The relative container enables proper positioning of the loading overlay
- `min-h-[400px]` prevents layout shift when content loads

## Common Mistakes

### Mistake 1: Using wrong backdrop value

**❌ WRONG - Using `backdrop="transparent"`:**
```tsx
<LoadingAnimation backdrop="transparent" />  // Creates 50% opacity overlay!
```

**✅ CORRECT - Using `backdrop="none"`:**
```tsx
<LoadingAnimation backdrop="none" />  // Fully transparent, shows skeletons
```

### Mistake 2: Conditional DataTable rendering

**❌ WRONG - DataTable only renders when there's data:**
```tsx
{data.length > 0 && (
  <DataTable loading={isLoading} data={data} />
)}
// Problem: During initial load, data=[] so DataTable doesn't render → no skeletons!
```

**✅ CORRECT - DataTable always renders (except error/empty after load):**
```tsx
{error ? (
  <ErrorDisplay />
) : !isLoading && data.length === 0 ? (
  <EmptyDisplay />
) : (
  <DataTable loading={isLoading} data={data} />
)}
// DataTable renders during loading with loading={true} → shows skeletons!
```

## Verification Checklist

After applying the pattern, verify:

- [ ] Page refresh shows skeleton UI underneath loading spinner (NOT a dark overlay)
- [ ] Navigation sidebar remains accessible during loading
- [ ] Error states bypass loading animation entirely
- [ ] Loading spinner is centered over content area (not fullscreen)
- [ ] No layout shift when content loads
- [ ] LoadingAnimation uses `fullScreen={false}` and `backdrop="none"` (not "transparent"!)
