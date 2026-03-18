import 'package:flutter/material.dart';

import '../controller/pagination_controller.dart';
import '../models/pagination_state.dart';

class PagedSliverGrid<PageKey, Item> extends StatelessWidget {
  final PaginationController<PageKey, Item> controller;
  final Widget Function(BuildContext, Item, int) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final WidgetBuilder? loadingBuilder;

  const PagedSliverGrid({
    super.key,
    required this.controller,
    required this.itemBuilder,
    required this.gridDelegate,
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

        return SliverMainAxisGroup(
          slivers: [
            SliverGrid(
              gridDelegate: gridDelegate,
              delegate: SliverChildBuilderDelegate(
                (context, index) => itemBuilder(context, state.items[index], index),
                childCount: state.items.length,
              ),
            ),
            if (showLoader)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: _buildLoader(context)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLoader(BuildContext context) {
    return loadingBuilder?.call(context) ?? const CircularProgressIndicator();
  }
}

typedef AdvancedSliverGrid<PageKey, Item> = PagedSliverGrid<PageKey, Item>;
