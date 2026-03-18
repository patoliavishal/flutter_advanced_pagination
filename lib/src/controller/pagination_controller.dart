import 'package:flutter/foundation.dart';

import '../cache/pagination_cache.dart';
import '../models/pagination_direction.dart';
import '../models/pagination_request.dart';
import '../models/pagination_result.dart';
import '../models/pagination_state.dart';

typedef PageFetcher<PageKey, Item> = Future<PageResult<PageKey, Item>> Function(
  PaginationRequest<PageKey> request,
);

enum _KeyPolicy { page, offset, cursor }

class PaginationController<PageKey, Item> extends ValueNotifier<PaginationState<PageKey, Item>> {
  final int pageSize;
  final PageFetcher<PageKey, Item> fetchPage;
  final PageKey? initialKey;
  final Object? Function(Item)? keyOf;
  final PaginationCacheManager<PageKey, Item>? cacheManager;
  final PaginationCachePolicy cachePolicy;
  final String? cacheKey;

  final _KeyPolicy _keyPolicy;

  int _requestSerial = 0;
  int _activeRequestId = 0;
  bool _isDisposed = false;

  PaginationRequest<PageKey>? _lastRequest;
  PageKey? _nextKey;
  PageKey? _prevKey;

  PaginationController._({
    required this.pageSize,
    required this.fetchPage,
    required this.initialKey,
    required this.keyOf,
    this.cacheManager,
    this.cachePolicy = const PaginationCachePolicy(),
    this.cacheKey,
    required _KeyPolicy keyPolicy,
  })  : assert(cacheManager == null || cacheKey != null, "cacheKey is required when cacheManager is provided."),
        _keyPolicy = keyPolicy,
        super(PaginationState.initial());

  static PaginationController<int, Item> pageBased<Item>({
    required PageFetcher<int, Item> fetchPage,
    int firstPageKey = 1,
    int pageSize = 20,
    Object? Function(Item)? keyOf,
    PaginationCacheManager<int, Item>? cacheManager,
    PaginationCachePolicy cachePolicy = const PaginationCachePolicy(),
    String? cacheKey,
  }) {
    return PaginationController<int, Item>._(
      pageSize: pageSize,
      fetchPage: fetchPage,
      initialKey: firstPageKey,
      keyOf: keyOf,
      cacheManager: cacheManager,
      cachePolicy: cachePolicy,
      cacheKey: cacheKey,
      keyPolicy: _KeyPolicy.page,
    );
  }

  static PaginationController<int, Item> offsetBased<Item>({
    required PageFetcher<int, Item> fetchPage,
    int initialOffset = 0,
    int pageSize = 20,
    Object? Function(Item)? keyOf,
    PaginationCacheManager<int, Item>? cacheManager,
    PaginationCachePolicy cachePolicy = const PaginationCachePolicy(),
    String? cacheKey,
  }) {
    return PaginationController<int, Item>._(
      pageSize: pageSize,
      fetchPage: fetchPage,
      initialKey: initialOffset,
      keyOf: keyOf,
      cacheManager: cacheManager,
      cachePolicy: cachePolicy,
      cacheKey: cacheKey,
      keyPolicy: _KeyPolicy.offset,
    );
  }

  static PaginationController<PageKey, Item> cursorBased<PageKey, Item>({
    required PageFetcher<PageKey, Item> fetchPage,
    PageKey? initialCursor,
    int pageSize = 20,
    Object? Function(Item)? keyOf,
    PaginationCacheManager<PageKey, Item>? cacheManager,
    PaginationCachePolicy cachePolicy = const PaginationCachePolicy(),
    String? cacheKey,
  }) {
    return PaginationController<PageKey, Item>._(
      pageSize: pageSize,
      fetchPage: fetchPage,
      initialKey: initialCursor,
      keyOf: keyOf,
      cacheManager: cacheManager,
      cachePolicy: cachePolicy,
      cacheKey: cacheKey,
      keyPolicy: _KeyPolicy.cursor,
    );
  }

  bool get isLoading => value.isLoading;

  Future<void> refresh({String reason = "refresh"}) async {
    final bool usedCache = _hydrateFromCacheIfEnabled();
    final bool shouldRevalidate = !usedCache || cachePolicy.staleWhileRevalidate;

    if (shouldRevalidate) {
      await _fetch(
        direction: PaginationDirection.initial,
        reason: reason,
        reset: true,
        silent: usedCache,
      );
    }
  }

  Future<void> fetchNext({String reason = "manual"}) async {
    if (!value.hasNext || value.isLoading) return;

    await _fetch(
      direction: PaginationDirection.next,
      reason: reason,
    );
  }

  Future<void> prefetchNext({String reason = "prefetch"}) async {
    if (!value.hasNext || value.isLoading) return;

    await _fetch(
      direction: PaginationDirection.next,
      reason: reason,
      silent: true,
    );
  }

  Future<void> fetchPrevious({String reason = "manual"}) async {
    if (!value.hasPrevious || value.isLoading) return;

    await _fetch(
      direction: PaginationDirection.previous,
      reason: reason,
    );
  }

  Future<void> retry() async {
    final request = _lastRequest;
    if (request == null || value.isLoading) return;

    await _fetch(
      direction: request.direction,
      reason: "retry",
      explicitKey: request.pageKey,
    );
  }

  void cancel() {
    _activeRequestId = ++_requestSerial;

    if (!value.isLoading) return;

    final PaginationStatus status =
        value.items.isEmpty ? PaginationStatus.idle : PaginationStatus.success;

    _setState(value.copyWith(
      status: status,
      isLoading: false,
    ));
  }

  void updateItem(bool Function(Item) match, Item newItem) {
    final pages = value.pages.map((page) => List<Item>.from(page)).toList();

    bool updated = false;
    for (final page in pages) {
      for (int i = 0; i < page.length; i++) {
        if (match(page[i])) {
          page[i] = newItem;
          updated = true;
          break;
        }
      }
      if (updated) break;
    }

    if (!updated) return;

    _setState(value.copyWith(
      pages: pages,
      items: _flattenPages(pages),
      lastUpdated: DateTime.now(),
    ));
  }

  void insertItem(int index, Item item) {
    final pages = value.pages.map((page) => List<Item>.from(page)).toList();

    if (pages.isEmpty) {
      _setState(value.copyWith(
        pages: [<Item>[item]],
        keys: [initialKey],
        items: [item],
        status: PaginationStatus.success,
        lastUpdated: DateTime.now(),
      ));
      return;
    }

    int remaining = index;
    for (final page in pages) {
      if (remaining <= page.length) {
        page.insert(remaining, item);
        _setState(value.copyWith(
          pages: pages,
          items: _flattenPages(pages),
          lastUpdated: DateTime.now(),
        ));
        return;
      }
      remaining -= page.length;
    }

    pages.last.add(item);
    _setState(value.copyWith(
      pages: pages,
      items: _flattenPages(pages),
      lastUpdated: DateTime.now(),
    ));
  }

  void removeWhere(bool Function(Item) match) {
    final pages = value.pages.map((page) => List<Item>.from(page)).toList();

    bool removed = false;
    for (final page in pages) {
      final originalLength = page.length;
      page.removeWhere(match);
      if (page.length != originalLength) removed = true;
    }

    if (!removed) return;

    final items = _flattenPages(pages);
    final PaginationStatus status =
        items.isEmpty ? PaginationStatus.empty : PaginationStatus.success;

    _setState(value.copyWith(
      pages: pages,
      items: items,
      status: status,
      lastUpdated: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _fetch({
    required PaginationDirection direction,
    required String reason,
    bool reset = false,
    bool silent = false,
    PageKey? explicitKey,
  }) async {
    if (value.isLoading) return;

    final PageKey? pageKey = explicitKey ?? _resolvePageKey(direction);
    if (pageKey == null && direction != PaginationDirection.initial) return;

    final PaginationStatus status = silent ? value.status : _statusFor(direction);

    _setState(value.copyWith(
      status: status,
      isLoading: true,
      error: silent ? value.error : null,
      isFromCache: silent ? value.isFromCache : false,
    ));

    final request = PaginationRequest<PageKey>(
      direction: direction,
      pageKey: pageKey,
      pageSize: pageSize,
      reason: reason,
    );

    final int requestId = ++_requestSerial;
    _activeRequestId = requestId;
    _lastRequest = request;

    try {
      final result = await fetchPage(request);
      if (requestId != _activeRequestId) return;

      _applyResult(request, result, reset: reset || direction == PaginationDirection.initial);
    } catch (error) {
      if (requestId != _activeRequestId) return;

      final PaginationStatus errorStatus = silent ? value.status : PaginationStatus.error;
      _setState(value.copyWith(
        status: errorStatus,
        error: error,
        isLoading: false,
      ));
    }
  }

  PaginationStatus _statusFor(PaginationDirection direction) {
    switch (direction) {
      case PaginationDirection.initial:
        return value.items.isEmpty ? PaginationStatus.loading : PaginationStatus.refreshing;
      case PaginationDirection.next:
      case PaginationDirection.previous:
        return PaginationStatus.loadingMore;
    }
  }

  PageKey? _resolvePageKey(PaginationDirection direction) {
    switch (direction) {
      case PaginationDirection.initial:
        return initialKey;
      case PaginationDirection.next:
        return _nextKey ?? _inferNextKey(value.keys.isEmpty ? null : value.keys.last);
      case PaginationDirection.previous:
        return _prevKey ?? _inferPreviousKey(value.keys.isEmpty ? null : value.keys.first);
    }
  }

  void _applyResult(
    PaginationRequest<PageKey> request,
    PageResult<PageKey, Item> result, {
    required bool reset,
  }) {
    final PageKey? resolvedNext = _resolveNextKey(request.pageKey, result);
    final PageKey? resolvedPrev = _resolvePreviousKey(request.pageKey, result);

    final bool hasNext = result.hasNext && resolvedNext != null;
    final bool hasPrevious = result.hasPrevious && resolvedPrev != null;

    _nextKey = resolvedNext;
    _prevKey = resolvedPrev;

    List<List<Item>> pages;
    List<PageKey?> keys;

    if (reset || value.pages.isEmpty) {
      pages = [result.items];
      keys = [request.pageKey];
    } else if (request.direction == PaginationDirection.next) {
      pages = [...value.pages, result.items];
      keys = [...value.keys, request.pageKey];
    } else if (request.direction == PaginationDirection.previous) {
      pages = [result.items, ...value.pages];
      keys = [request.pageKey, ...value.keys];
    } else {
      pages = [result.items];
      keys = [request.pageKey];
    }

    final items = _flattenPages(pages);
    final PaginationStatus status =
        items.isEmpty ? PaginationStatus.empty : PaginationStatus.success;

    _setState(value.copyWith(
      pages: pages,
      keys: keys,
      items: items,
      status: status,
      error: null,
      isLoading: false,
      isFromCache: false,
      hasNext: request.direction == PaginationDirection.previous
          ? value.hasNext
          : hasNext,
      hasPrevious: request.direction == PaginationDirection.next
          ? value.hasPrevious
          : hasPrevious,
      lastUpdated: DateTime.now(),
    ));

    _persistCache();
  }

  PageKey? _resolveNextKey(PageKey? requestKey, PageResult<PageKey, Item> result) {
    if (result.nextKey != null) return result.nextKey;
    return _inferNextKey(requestKey);
  }

  PageKey? _resolvePreviousKey(PageKey? requestKey, PageResult<PageKey, Item> result) {
    if (result.prevKey != null) return result.prevKey;
    return _inferPreviousKey(requestKey);
  }

  PageKey? _inferNextKey(PageKey? currentKey) {
    if (_keyPolicy == _KeyPolicy.cursor) return null;
    if (currentKey == null) return null;

    final int current = currentKey as int;
    switch (_keyPolicy) {
      case _KeyPolicy.page:
        return (current + 1) as PageKey;
      case _KeyPolicy.offset:
        return (current + pageSize) as PageKey;
      case _KeyPolicy.cursor:
        return null;
    }
  }

  PageKey? _inferPreviousKey(PageKey? currentKey) {
    if (_keyPolicy == _KeyPolicy.cursor) return null;
    if (currentKey == null) return null;

    final int current = currentKey as int;
    switch (_keyPolicy) {
      case _KeyPolicy.page:
        return (current - 1) as PageKey;
      case _KeyPolicy.offset:
        final int prev = current - pageSize;
        return (prev < 0 ? 0 : prev) as PageKey;
      case _KeyPolicy.cursor:
        return null;
    }
  }

  List<Item> _flattenPages(List<List<Item>> pages) {
    final List<Item> items = [];
    for (final page in pages) {
      items.addAll(page);
    }
    return items;
  }

  bool _hydrateFromCacheIfEnabled() {
    if (cacheManager == null || cacheKey == null) return false;
    if (!cachePolicy.useCacheOnRefresh) return false;

    final snapshot = cacheManager!.read(cacheKey!);
    if (snapshot == null) return false;

    final bool expired = cachePolicy.isExpired(snapshot.savedAt);
    if (expired && !cachePolicy.staleWhileRevalidate) return false;

    _applyCacheSnapshot(snapshot);
    return true;
  }

  void _applyCacheSnapshot(PaginationCacheSnapshot<PageKey, Item> snapshot) {
    _nextKey = snapshot.nextKey;
    _prevKey = snapshot.prevKey;

    final pages = snapshot.pages.map((page) => List<Item>.from(page)).toList();
    final keys = List<PageKey?>.from(snapshot.keys);
    final items = _flattenPages(pages);
    final PaginationStatus status = items.isEmpty ? PaginationStatus.empty : PaginationStatus.success;

    _setState(value.copyWith(
      pages: pages,
      keys: keys,
      items: items,
      status: status,
      error: null,
      isLoading: false,
      isFromCache: true,
      hasNext: snapshot.hasNext,
      hasPrevious: snapshot.hasPrevious,
      lastUpdated: snapshot.savedAt,
    ));
  }

  void _persistCache() {
    if (cacheManager == null || cacheKey == null) return;

    final snapshot = PaginationCacheSnapshot<PageKey, Item>(
      pages: value.pages.map((page) => List<Item>.from(page)).toList(),
      keys: List<PageKey?>.from(value.keys),
      hasNext: value.hasNext,
      hasPrevious: value.hasPrevious,
      nextKey: _nextKey,
      prevKey: _prevKey,
      savedAt: DateTime.now(),
    );

    cacheManager!.write(cacheKey!, snapshot);
  }

  void _setState(PaginationState<PageKey, Item> next) {
    if (_isDisposed) return;
    value = next;
  }

}
