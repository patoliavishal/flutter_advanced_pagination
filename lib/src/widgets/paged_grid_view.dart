import 'package:flutter/material.dart';

import '../controller/pagination_controller.dart';
import '../models/pagination_state.dart';

class PagedGridView<PageKey, Item> extends StatefulWidget {
  final PaginationController<PageKey, Item> controller;
  final Widget Function(BuildContext, Item, int) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final Widget Function(BuildContext, PaginationStatus)? statusBuilder;
  final WidgetBuilder? loadingBuilder;
  final ScrollController? scrollController;
  final bool autoLoad;
  final double preloadOffset;
  final bool enableScrollPrefetch;
  final double prefetchOffset;

  const PagedGridView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    required this.gridDelegate,
    this.statusBuilder,
    this.loadingBuilder,
    this.scrollController,
    this.autoLoad = true,
    this.preloadOffset = 200,
    this.enableScrollPrefetch = false,
    this.prefetchOffset = 600,
  });

  @override
  State<PagedGridView<PageKey, Item>> createState() => _PagedGridViewState<PageKey, Item>();
}

class _PagedGridViewState<PageKey, Item> extends State<PagedGridView<PageKey, Item>> {
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
  void didUpdateWidget(covariant PagedGridView<PageKey, Item> oldWidget) {
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

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverGrid(
          gridDelegate: widget.gridDelegate,
          delegate: SliverChildBuilderDelegate(
            (context, index) => widget.itemBuilder(context, state.items[index], index),
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
}

typedef AdvancedPaginationGrid<PageKey, Item> = PagedGridView<PageKey, Item>;
