import 'package:flutter/material.dart';

import '../controller/pagination_controller.dart';
import '../models/pagination_state.dart';

typedef PagedStateBuilder<PageKey, Item> = Widget Function(
  BuildContext context,
  PaginationState<PageKey, Item> state,
);

typedef PagedErrorBuilder = Widget Function(
  BuildContext context,
  Object? error,
);

class PagedLayoutBuilder<PageKey, Item> extends StatelessWidget {
  final PaginationController<PageKey, Item> controller;
  final PagedStateBuilder<PageKey, Item> builder;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final PagedErrorBuilder? errorBuilder;

  const PagedLayoutBuilder({
    super.key,
    required this.controller,
    required this.builder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PaginationState<PageKey, Item>>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state.items.isEmpty) {
          if (state.status == PaginationStatus.loading || state.status == PaginationStatus.refreshing) {
            return loadingBuilder?.call(context) ?? const Center(child: CircularProgressIndicator());
          }

          if (state.status == PaginationStatus.error) {
            return errorBuilder?.call(context, state.error) ?? const Center(child: Text("Something went wrong"));
          }

          if (state.status == PaginationStatus.empty) {
            return emptyBuilder?.call(context) ?? const SizedBox.shrink();
          }
        }

        return builder(context, state);
      },
    );
  }
}
