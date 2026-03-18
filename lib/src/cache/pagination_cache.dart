import 'dart:collection';

class PaginationCacheSnapshot<PageKey, Item> {
  final List<List<Item>> pages;
  final List<PageKey?> keys;
  final bool hasNext;
  final bool hasPrevious;
  final PageKey? nextKey;
  final PageKey? prevKey;
  final DateTime savedAt;

  const PaginationCacheSnapshot({
    required this.pages,
    required this.keys,
    required this.hasNext,
    required this.hasPrevious,
    required this.nextKey,
    required this.prevKey,
    required this.savedAt,
  });
}

abstract class PaginationCacheManager<PageKey, Item> {
  PaginationCacheSnapshot<PageKey, Item>? read(String cacheKey);

  void write(String cacheKey, PaginationCacheSnapshot<PageKey, Item> snapshot);

  void clear(String cacheKey);

  void clearAll();
}

class MemoryPaginationCacheManager<PageKey, Item> implements PaginationCacheManager<PageKey, Item> {
  final int maxEntries;
  final LinkedHashMap<String, PaginationCacheSnapshot<PageKey, Item>> _store = LinkedHashMap();

  MemoryPaginationCacheManager({this.maxEntries = 20});

  @override
  PaginationCacheSnapshot<PageKey, Item>? read(String cacheKey) {
    final snapshot = _store.remove(cacheKey);
    if (snapshot != null) {
      _store[cacheKey] = snapshot;
    }
    return snapshot;
  }

  @override
  void write(String cacheKey, PaginationCacheSnapshot<PageKey, Item> snapshot) {
    _store[cacheKey] = snapshot;
    _evictIfNeeded();
  }

  @override
  void clear(String cacheKey) {
    _store.remove(cacheKey);
  }

  @override
  void clearAll() {
    _store.clear();
  }

  void _evictIfNeeded() {
    while (_store.length > maxEntries) {
      _store.remove(_store.keys.first);
    }
  }
}

class PaginationCachePolicy {
  final Duration maxAge;
  final bool useCacheOnRefresh;
  final bool staleWhileRevalidate;

  const PaginationCachePolicy({
    this.maxAge = const Duration(minutes: 10),
    this.useCacheOnRefresh = true,
    this.staleWhileRevalidate = true,
  });

  bool isExpired(DateTime savedAt) {
    return DateTime.now().difference(savedAt) > maxAge;
  }
}
