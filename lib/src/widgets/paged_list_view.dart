import 'package:flutter/material.dart';

import '../controller/pagination_controller.dart';
import '../models/pagination_state.dart';

class PagedListView<PageKey, Item> extends StatefulWidget {
  final PaginationController<PageKey, Item> controller;
  final Widget Function(BuildContext, Item, int) itemBuilder;
  final Widget Function(BuildContext, PaginationStatus)? statusBuilder;
  final WidgetBuilder? loadingBuilder;
  final ScrollController? scrollController;
  final bool enableRefresh;
  final bool autoLoad;
  final double preloadOffset;
  final bool enableScrollPrefetch;
  final double prefetchOffset;

  const PagedListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.statusBuilder,
    this.loadingBuilder,
    this.scrollController,
    this.enableRefresh = true,
    this.autoLoad = true,
    this.preloadOffset = 200,
    this.enableScrollPrefetch = false,
    this.prefetchOffset = 600,
  });

  @override
  State<PagedListView<PageKey, Item>> createState() => _PagedListViewState<PageKey, Item>();
}

class _PagedListViewState<PageKey, Item> extends State<PagedListView<PageKey, Item>> {
  late ScrollController _scrollController;
  bool _ownsScrollController = false;

  @override
  void initState() {
    super.initState();

    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();

    widget.controller.addListener(_onControllerChange);
    _scrollController.addListener(_onScroll);

    if (widget.autoLoad && _shouldAutoLoad()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.controller.refresh(reason: "initial");
      });
    }
  }

  @override
  void didUpdateWidget(covariant PagedListView<PageKey, Item> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChange);
      widget.controller.addListener(_onControllerChange);
    }

    if (oldWidget.scrollController != widget.scrollController) {
      _scrollController.removeListener(_onScroll);
      if (_ownsScrollController) {
        _scrollController.dispose();
      }
      _ownsScrollController = widget.scrollController == null;
      _scrollController = widget.scrollController ?? ScrollController();
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _scrollController.removeListener(_onScroll);
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.value;

    if (widget.statusBuilder != null && state.items.isEmpty && state.status != PaginationStatus.success) {
      return widget.statusBuilder!(context, state.status);
    }

    if (state.items.isEmpty && state.status == PaginationStatus.loading) {
      return Center(child: _buildLoader(context));
    }

    if (state.items.isEmpty && state.status == PaginationStatus.error) {
      return const Center(child: Text("Something went wrong"));
    }

    if (state.items.isEmpty && state.status == PaginationStatus.empty) {
      return const SizedBox.shrink();
    }

    final bool showLoader = state.hasNext && state.status == PaginationStatus.loadingMore;
    final int itemCount = state.items.length + (showLoader ? 1 : 0);

    Widget list = ListView.builder(
      controller: _scrollController,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < state.items.length) {
          return widget.itemBuilder(context, state.items[index], index);
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: _buildLoader(context)),
        );
      },
    );

    if (!widget.enableRefresh) return list;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: list,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final threshold = _scrollController.position.maxScrollExtent - widget.preloadOffset;
    final prefetchThreshold = _scrollController.position.maxScrollExtent - widget.prefetchOffset;

    if (widget.enableScrollPrefetch && _scrollController.position.pixels >= prefetchThreshold) {
      widget.controller.prefetchNext(reason: "scroll_prefetch");
    }

    if (_scrollController.position.pixels >= threshold) {
      widget.controller.fetchNext(reason: "auto");
    }
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  bool _shouldAutoLoad() {
    final state = widget.controller.value;
    return state.items.isEmpty && state.status == PaginationStatus.idle;
  }

  Widget _buildLoader(BuildContext context) {
    return widget.loadingBuilder?.call(context) ?? const CircularProgressIndicator();
  }

  Future<void> _handleRefresh() async {
    await widget.controller.refresh(reason: "pull_to_refresh");
  }
}

typedef AdvancedPaginationList<PageKey, Item> = PagedListView<PageKey, Item>;
