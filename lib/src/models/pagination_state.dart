enum PaginationStatus { idle, loading, refreshing, loadingMore, success, empty, error }

class PaginationState<PageKey, Item> {
  final List<Item> items;
  final List<List<Item>> pages;
  final List<PageKey?> keys;
  final PaginationStatus status;
  final Object? error;
  final bool isLoading;
  final bool hasNext;
  final bool hasPrevious;
  final bool isFromCache;
  final DateTime? lastUpdated;

  const PaginationState({
    required this.items,
    required this.pages,
    required this.keys,
    required this.status,
    required this.error,
    required this.isLoading,
    required this.hasNext,
    required this.hasPrevious,
    required this.isFromCache,
    required this.lastUpdated,
  });

  PaginationState<PageKey, Item> copyWith({
    List<Item>? items,
    List<List<Item>>? pages,
    List<PageKey?>? keys,
    PaginationStatus? status,
    Object? error,
    bool? isLoading,
    bool? hasNext,
    bool? hasPrevious,
    bool? isFromCache,
    DateTime? lastUpdated,
  }) {
    return PaginationState<PageKey, Item>(
      items: items ?? this.items,
      pages: pages ?? this.pages,
      keys: keys ?? this.keys,
      status: status ?? this.status,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
      isFromCache: isFromCache ?? this.isFromCache,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  static PaginationState<PageKey, Item> initial<PageKey, Item>() {
    return PaginationState<PageKey, Item>(
      items: const [],
      pages: const [],
      keys: const [],
      status: PaginationStatus.idle,
      error: null,
      isLoading: false,
      hasNext: true,
      hasPrevious: false,
      isFromCache: false,
      lastUpdated: null,
    );
  }
}
