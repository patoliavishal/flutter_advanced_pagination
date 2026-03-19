import 'package:flutter/material.dart';

import '../controller/pagination_controller.dart';
import '../models/pagination_state.dart';

class PagedSliverList<PageKey, Item> extends StatelessWidget {
  final PaginationController<PageKey, Item> controller;
  final Widget Function(BuildContext, Item, int) itemBuilder;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final Widget Function(BuildContext, Object?)? errorBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final Widget Function(BuildContext, Object?)? loadMoreErrorBuilder;

  const PagedSliverList({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.separatorBuilder,
    this.loadMoreErrorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PaginationState<PageKey, Item>>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state.items.isEmpty) {
          if (state.status == PaginationStatus.loading || state.status == PaginationStatus.refreshing) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: _buildLoader(context)),
            );
          }

          if (state.status == PaginationStatus.error) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: _buildError(context, state.error),
            );
          }

          if (state.status == PaginationStatus.empty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmpty(context),
            );
          }
        }

        final bool showLoader = state.hasNext && state.status == PaginationStatus.loadingMore;
        final bool showRetryFooter = state.items.isNotEmpty && state.status == PaginationStatus.error && state.hasNext;
        final int itemCount = state.items.length + ((showLoader || showRetryFooter) ? 1 : 0);

        Widget buildItem(BuildContext context, int index) {
          if (index < state.items.length) {
            return itemBuilder(context, state.items[index], index);
          }

          if (showRetryFooter) {
            return _buildLoadMoreError(context, state.error);
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: _buildLoader(context)),
          );
        }

        if (separatorBuilder == null) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              buildItem,
              childCount: itemCount,
            ),
          );
        }

        final int separatedCount = itemCount == 0 ? 0 : (itemCount * 2) - 1;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index.isOdd) {
                final int itemIndex = index ~/ 2;
                return separatorBuilder!(context, itemIndex);
              }

              final int itemIndex = index ~/ 2;
              return buildItem(context, itemIndex);
            },
            childCount: separatedCount,
          ),
        );
      },
    );
  }

  Widget _buildLoader(BuildContext context) {
    return loadingBuilder?.call(context) ?? const CircularProgressIndicator();
  }

  Widget _buildEmpty(BuildContext context) {
    return emptyBuilder?.call(context) ?? const SizedBox.shrink();
  }

  Widget _buildError(BuildContext context, Object? error) {
    return errorBuilder?.call(context, error) ?? const Center(child: Text("Something went wrong"));
  }

  Widget _buildLoadMoreError(BuildContext context, Object? error) {
    if (loadMoreErrorBuilder != null) {
      return loadMoreErrorBuilder!(context, error);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error?.toString() ?? "Something went wrong"),
            const SizedBox(height: 8),
            TextButton(onPressed: controller.retry, child: const Text("Retry")),
          ],
        ),
      ),
    );
  }
}

typedef AdvancedSliverList<PageKey, Item> = PagedSliverList<PageKey, Item>;
