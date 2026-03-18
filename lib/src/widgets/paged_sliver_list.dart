import 'package:flutter/material.dart';

import '../controller/pagination_controller.dart';
import '../models/pagination_state.dart';

class PagedSliverList<PageKey, Item> extends StatelessWidget {
  final PaginationController<PageKey, Item> controller;
  final Widget Function(BuildContext, Item, int) itemBuilder;
  final WidgetBuilder? loadingBuilder;

  const PagedSliverList({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.loadingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PaginationState<PageKey, Item>>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state.items.isEmpty && state.status == PaginationStatus.loading) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: _buildLoader(context)),
          );
        }

        final bool showLoader = state.hasNext && state.status == PaginationStatus.loadingMore;
        final int itemCount = state.items.length + (showLoader ? 1 : 0);

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index < state.items.length) {
                return itemBuilder(context, state.items[index], index);
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: _buildLoader(context)),
              );
            },
            childCount: itemCount,
          ),
        );
      },
    );
  }

  Widget _buildLoader(BuildContext context) {
    return loadingBuilder?.call(context) ?? const CircularProgressIndicator();
  }
}

typedef AdvancedSliverList<PageKey, Item> = PagedSliverList<PageKey, Item>;
