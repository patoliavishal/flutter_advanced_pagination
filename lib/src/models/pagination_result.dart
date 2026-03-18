class PageResult<PageKey, Item> {
  final List<Item> items;
  final PageKey? nextKey;
  final PageKey? prevKey;
  final bool hasNext;
  final bool hasPrevious;

  const PageResult({
    required this.items,
    required this.hasNext,
    required this.hasPrevious,
    this.nextKey,
    this.prevKey,
  });
}

typedef PaginationResult<PageKey, Item> = PageResult<PageKey, Item>;
