import 'pagination_direction.dart';

class PaginationRequest<PageKey> {
  final PaginationDirection direction;
  final PageKey? pageKey;
  final int pageSize;
  final String reason;
  final Object? cancelToken;

  const PaginationRequest({
    required this.direction,
    required this.pageKey,
    required this.pageSize,
    required this.reason,
    this.cancelToken,
  });
}
