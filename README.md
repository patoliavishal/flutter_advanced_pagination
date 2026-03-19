# Advanced Pagination - Flutter

A controller-first pagination package for Flutter with page/offset/cursor support, clean widgets, cache + prefetch, and customizable loading/empty/error UI.

## Features

- Page, offset, and cursor-based pagination.
- `PagedListView`, `PagedGridView`, and sliver variants.
- List separators and reverse pagination support.
- Load‑more error retry footer (default or custom).
- Sliver empty/error builders for fully custom states.
- Scroll prefetch to load ahead of the viewport.
- Cache manager with stale-while-revalidate support.
- `PagedLayoutBuilder` and per-widget builders for custom states.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  advanced_pagination: ^0.2.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1) Create a controller

```dart
final controller = PaginationController.pageBased(
  firstPageKey: 1,
  pageSize: 20,
  fetchPage: (request) async {
    final page = request.pageKey ?? 1;
    final items = await api.fetchPage(page, request.pageSize);

    return PageResult(
      items: items,
      hasNext: page < 10,
      hasPrevious: page > 1,
    );
  },
);
```

### 2) Render a list

```dart
PagedListView<int, Article>(
  controller: controller,
  itemBuilder: (context, item, index) => ArticleTile(item),
);
```

## Controller Types

### Page-based

```dart
final controller = PaginationController.pageBased(
  firstPageKey: 1,
  pageSize: 20,
  fetchPage: (request) async {
    final page = request.pageKey ?? 1;
    final items = await api.fetchPage(page, request.pageSize);

    return PageResult(
      items: items,
      hasNext: page < 10,
      hasPrevious: page > 1,
    );
  },
);
```

### Offset-based

```dart
final controller = PaginationController.offsetBased(
  initialOffset: 0,
  pageSize: 20,
  fetchPage: (request) async {
    final offset = request.pageKey ?? 0;
    final items = await api.fetchOffset(offset, request.pageSize);

    return PageResult(
      items: items,
      hasNext: items.isNotEmpty,
      hasPrevious: offset > 0,
    );
  },
);
```

### Cursor-based

```dart
final controller = PaginationController.cursorBased<String, Article>(
  initialCursor: "0",
  pageSize: 20,
  fetchPage: (request) async {
    final result = await api.fetchCursor(request.pageKey, request.pageSize);

    return PageResult(
      items: result.items,
      hasNext: result.nextCursor != null,
      hasPrevious: result.prevCursor != null,
      nextKey: result.nextCursor,
      prevKey: result.prevCursor,
    );
  },
);
```

## Widgets

### PagedGridView

```dart
PagedGridView<int, Article>(
  controller: controller,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
  ),
  itemBuilder: (context, item, index) => ArticleTile(item),
);
```

### PagedListView with separators + reverse

```dart
PagedListView<int, Article>(
  controller: controller,
  reverse: true,
  separatorBuilder: (context, index) => const Divider(height: 1),
  itemBuilder: (context, item, index) => ArticleTile(item),
);
```

### Sliver list/grid

```dart
CustomScrollView(
  // Use reverse: true here if you want a reversed sliver list/grid.
  slivers: [
    const SliverAppBar(title: Text("Sliver Grid")),
    PagedSliverGrid<int, Article>(
      controller: controller,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, item, index) => ArticleTile(item),
    ),
  ],
);
```

### Sliver empty / error builders

```dart
PagedSliverList<int, Article>(
  controller: controller,
  emptyBuilder: (_) => const Center(child: Text("No items")),
  errorBuilder: (_, error) => const Center(child: Text("Load failed")),
  itemBuilder: (context, item, index) => ArticleTile(item),
);
```

## Custom States

### PagedLayoutBuilder

```dart
PagedLayoutBuilder<int, Article>(
  controller: controller,
  loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
  emptyBuilder: (_) => const Center(child: Text("No items")),
  errorBuilder: (_, error) => const Center(child: Text("Something went wrong")),
  builder: (context, state) {
    return PagedListView<int, Article>(
      controller: controller,
      itemBuilder: (context, item, index) => ArticleTile(item),
    );
  },
);
```

### Per-widget builders

```dart
PagedListView<int, Article>(
  controller: controller,
  loadingBuilder: (_) => const CircularProgressIndicator(),
  statusBuilder: (context, status) {
    if (status == PaginationStatus.error) {
      return const Center(child: Text("Oops"));
    }
    return const SizedBox.shrink();
  },
  itemBuilder: (context, item, index) => ArticleTile(item),
);
```

### Load‑more error retry footer

```dart
PagedListView<int, Article>(
  controller: controller,
  loadMoreErrorBuilder: (context, error) {
    return Center(
      child: TextButton(
        onPressed: () => controller.retry(),
        child: const Text("Retry loading more"),
      ),
    );
  },
  itemBuilder: (context, item, index) => ArticleTile(item),
);
```

## Scroll Prefetch

```dart
PagedListView<int, Article>(
  controller: controller,
  enableScrollPrefetch: true,
  prefetchOffset: 700,
  preloadOffset: 200,
  itemBuilder: (context, item, index) => ArticleTile(item),
);
```

## Cache + Stale-While-Revalidate

```dart
final cache = MemoryPaginationCacheManager<int, Article>(maxEntries: 10);

final controller = PaginationController.pageBased(
  firstPageKey: 1,
  pageSize: 20,
  fetchPage: (request) async { /* ... */ },
  cacheManager: cache,
  cacheKey: "articles-feed",
  cachePolicy: const PaginationCachePolicy(
    maxAge: Duration(minutes: 10),
    staleWhileRevalidate: true,
  ),
);
```

## Parameters (Most Used)

- `autoLoad`: if `true`, loads the first page after build.
- `enableRefresh`: enables pull-to-refresh in `PagedListView`.
- `reverse`: reverses scroll direction (useful for chat UIs).
- `preloadOffset`: how close to the end before `fetchNext()` triggers.
- `enableScrollPrefetch`: enables early `prefetchNext()`.
- `prefetchOffset`: how early prefetch starts.
- `loadingBuilder`: custom loader widget (defaults to `CircularProgressIndicator`).
- `separatorBuilder`: adds separators between list items.
- `loadMoreErrorBuilder`: custom footer when loading more fails.
- `emptyBuilder` / `errorBuilder`: customize sliver empty/error states.

## Controller API

- `refresh()`: reload from start.
- `fetchNext()`: append next page.
- `fetchPrevious()`: prepend previous page.
- `prefetchNext()`: silent prefetch (no loader).
- `prefetchPrevious()`: silent prefetch in the previous direction.
- `retry()`: repeat last failed request.
- `cancel()`: cancel active request.

## Quick FAQ

You can read the Quick-FAQ here: https://github.com/patoliavishal/flutter_advanced_pagination/wiki/Quick-FAQ

## Running the Example App

The example is a full Flutter app with `android/` and `ios/` folders.

```bash
cd example
flutter pub get
flutter run
```

For iOS on macOS, run `flutter run` and allow Xcode to handle signing if prompted.

## Additional Information

Pull requests and feedback are welcome. If you encounter any issues, please open a GitHub issue and include a minimal reproducible example.
