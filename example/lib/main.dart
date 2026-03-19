import 'package:advanced_pagination/advanced_pagination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const PaginationShowcaseApp());
}

class PaginationShowcaseApp extends StatelessWidget {
  const PaginationShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Advanced Pagination",
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const ShowcaseHome(),
    );
  }
}

class ShowcaseHome extends StatelessWidget {
  const ShowcaseHome({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = <_DemoEntry>[
      _DemoEntry("Basic Pagination", () => const BasicDemoPage()),
      _DemoEntry("Scroll Prefetch", () => const PrefetchDemoPage()),
      _DemoEntry("Cache + Stale-While-Revalidate", () => const CacheDemoPage()),
      _DemoEntry("Offset-based Pagination", () => const OffsetDemoPage()),
      _DemoEntry("Cursor-based Pagination", () => const CursorDemoPage()),
      _DemoEntry("Retry Footer + Separators", () => const RetryFooterDemoPage()),
      _DemoEntry("Sliver Empty/Error Demo", () => const SliverStateDemoPage()),
      _DemoEntry("Sliver Grid Demo", () => const SliverGridDemoPage()),
      _DemoEntry("Bloc Pagination Demo", () => const BlocDemoPage()),
      _DemoEntry("PagedLayoutBuilder States", () => const LayoutBuilderDemoPage()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Advanced Pagination Demos")),
      body: ListView.separated(
        itemCount: demos.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final demo = demos[index];
          return ListTile(
            title: Text(demo.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => demo.builder()));
            },
          );
        },
      ),
    );
  }
}

class _DemoEntry {
  final String title;
  final Widget Function() builder;

  _DemoEntry(this.title, this.builder);
}

class BasicDemoPage extends StatefulWidget {
  const BasicDemoPage({super.key});

  @override
  State<BasicDemoPage> createState() => _BasicDemoPageState();
}

class _BasicDemoPageState extends State<BasicDemoPage> {
  late final PaginationController<int, int> controller;

  @override
  void initState() {
    super.initState();
    controller = PaginationController.pageBased(firstPageKey: 1, pageSize: 20, fetchPage: _fetchPage);
  }

  Future<PageResult<int, int>> _fetchPage(PaginationRequest<int> request) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final int page = request.pageKey ?? 1;
    final data = List.generate(request.pageSize, (index) => (page - 1) * request.pageSize + index);

    return PageResult(items: data, hasNext: page < 6, hasPrevious: page > 1);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Basic Pagination")),
      body: PagedListView<int, int>(
        controller: controller,
        itemBuilder: (context, item, index) => ListTile(title: Text("Item $item")),
      ),
    );
  }
}

class PrefetchDemoPage extends StatefulWidget {
  const PrefetchDemoPage({super.key});

  @override
  State<PrefetchDemoPage> createState() => _PrefetchDemoPageState();
}

class _PrefetchDemoPageState extends State<PrefetchDemoPage> {
  late final PaginationController<int, int> controller;

  @override
  void initState() {
    super.initState();
    controller = PaginationController.pageBased(firstPageKey: 1, pageSize: 20, fetchPage: _fetchPage);
  }

  Future<PageResult<int, int>> _fetchPage(PaginationRequest<int> request) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final int page = request.pageKey ?? 1;
    final data = List.generate(request.pageSize, (index) => (page - 1) * request.pageSize + index);

    return PageResult(items: data, hasNext: page < 6, hasPrevious: page > 1);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scroll Prefetch")),
      body: PagedListView<int, int>(
        controller: controller,
        enableScrollPrefetch: true,
        prefetchOffset: 700,
        preloadOffset: 200,
        loadingBuilder: (context) => CircularProgressIndicator(color: Colors.red),
        itemBuilder: (context, item, index) => ListTile(title: Text("Item $item")),
      ),
    );
  }
}

class CacheDemoPage extends StatefulWidget {
  const CacheDemoPage({super.key});

  @override
  State<CacheDemoPage> createState() => _CacheDemoPageState();
}

class _CacheDemoPageState extends State<CacheDemoPage> {
  late final PaginationController<int, int> controller;
  final MemoryPaginationCacheManager<int, int> cache = MemoryPaginationCacheManager(maxEntries: 10);

  @override
  void initState() {
    super.initState();
    controller = PaginationController.pageBased(
      firstPageKey: 1,
      pageSize: 20,
      fetchPage: _fetchPage,
      cacheManager: cache,
      cacheKey: "cache-demo",
      cachePolicy: const PaginationCachePolicy(maxAge: Duration(seconds: 8), staleWhileRevalidate: true),
    );
  }

  Future<PageResult<int, int>> _fetchPage(PaginationRequest<int> request) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final int page = request.pageKey ?? 1;
    final data = List.generate(request.pageSize, (index) => (page - 1) * request.pageSize + index);

    return PageResult(items: data, hasNext: page < 6, hasPrevious: page > 1);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cache + SWR"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => controller.refresh())],
      ),
      body: ValueListenableBuilder<PaginationState<int, int>>(
        valueListenable: controller,
        builder: (context, state, _) {
          return Column(
            children: [
              if (state.isFromCache)
                Container(width: double.infinity, padding: const EdgeInsets.all(12), color: Colors.amber.withValues(alpha: 0.2), child: const Text("Showing cached data (refreshing in background)")),
              Expanded(
                child: PagedListView<int, int>(
                  controller: controller,
                  itemBuilder: (context, item, index) => ListTile(title: Text("Item $item")),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class OffsetDemoPage extends StatefulWidget {
  const OffsetDemoPage({super.key});

  @override
  State<OffsetDemoPage> createState() => _OffsetDemoPageState();
}

class _OffsetDemoPageState extends State<OffsetDemoPage> {
  static const int _totalItems = 120;
  late final PaginationController<int, int> controller;

  @override
  void initState() {
    super.initState();
    controller = PaginationController.offsetBased(initialOffset: 0, pageSize: 15, fetchPage: _fetchPage);
  }

  Future<PageResult<int, int>> _fetchPage(PaginationRequest<int> request) async {
    await Future.delayed(const Duration(milliseconds: 650));
    final int offset = request.pageKey ?? 0;
    final int end = (offset + request.pageSize).clamp(0, _totalItems).toInt();
    final data = List.generate(end - offset, (index) => offset + index);

    return PageResult(items: data, hasNext: end < _totalItems, hasPrevious: offset > 0);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Offset-based Pagination")),
      body: PagedListView<int, int>(
        controller: controller,
        itemBuilder: (context, item, index) => ListTile(title: Text("Offset Item $item")),
      ),
    );
  }
}

class CursorDemoPage extends StatefulWidget {
  const CursorDemoPage({super.key});

  @override
  State<CursorDemoPage> createState() => _CursorDemoPageState();
}

class _CursorDemoPageState extends State<CursorDemoPage> {
  static const int _totalItems = 120;
  final List<String> _data = List.generate(_totalItems, (index) => "Cursor Item $index");
  late final PaginationController<String, String> controller;

  @override
  void initState() {
    super.initState();
    controller = PaginationController.cursorBased(initialCursor: "0", pageSize: 12, fetchPage: _fetchPage);
  }

  Future<PageResult<String, String>> _fetchPage(PaginationRequest<String> request) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final int start = int.tryParse(request.pageKey ?? "0") ?? 0;
    final int end = (start + request.pageSize).clamp(0, _data.length).toInt();
    final items = _data.sublist(start, end);

    final int prevStart = start - request.pageSize;
    final String? prevCursor = prevStart >= 0 ? prevStart.toString() : null;
    final String? nextCursor = end < _data.length ? end.toString() : null;

    return PageResult(items: items, hasNext: nextCursor != null, hasPrevious: prevCursor != null, nextKey: nextCursor, prevKey: prevCursor);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cursor-based Pagination")),
      body: PagedListView<String, String>(
        controller: controller,
        itemBuilder: (context, item, index) => ListTile(title: Text(item)),
      ),
    );
  }
}

class RetryFooterDemoPage extends StatefulWidget {
  const RetryFooterDemoPage({super.key});

  @override
  State<RetryFooterDemoPage> createState() => _RetryFooterDemoPageState();
}

class _RetryFooterDemoPageState extends State<RetryFooterDemoPage> {
  late final PaginationController<int, int> controller;
  bool _failOnce = true;

  @override
  void initState() {
    super.initState();
    controller = PaginationController.pageBased(firstPageKey: 1, pageSize: 15, fetchPage: _fetchPage);
  }

  Future<PageResult<int, int>> _fetchPage(PaginationRequest<int> request) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final int page = request.pageKey ?? 1;

    if (_failOnce && page == 3) {
      _failOnce = false;
      throw Exception("Simulated load-more failure");
    }

    final items = List.generate(request.pageSize, (index) => (page - 1) * request.pageSize + index);

    return PageResult(items: items, hasNext: page < 6, hasPrevious: page > 1);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Retry Footer + Separators")),
      body: PagedListView<int, int>(
        controller: controller,
        separatorBuilder: (context, index) => const Divider(height: 1),
        loadMoreErrorBuilder: (context, error) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error?.toString() ?? "Load more failed"),
                  const SizedBox(height: 8),
                  TextButton(onPressed: controller.retry, child: const Text("Retry loading more")),
                ],
              ),
            ),
          );
        },
        itemBuilder: (context, item, index) => ListTile(title: Text("Item $item")),
      ),
    );
  }
}

class SliverStateDemoPage extends StatefulWidget {
  const SliverStateDemoPage({super.key});

  @override
  State<SliverStateDemoPage> createState() => _SliverStateDemoPageState();
}

class _SliverStateDemoPageState extends State<SliverStateDemoPage> {
  late final PaginationController<int, int> controller;
  _SliverDemoMode _mode = _SliverDemoMode.success;
  bool _showGrid = false;

  @override
  void initState() {
    super.initState();
    controller = PaginationController.pageBased(firstPageKey: 1, pageSize: 12, fetchPage: _fetchPage);
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.refresh(reason: "initial"));
  }

  Future<PageResult<int, int>> _fetchPage(PaginationRequest<int> request) async {
    await Future.delayed(const Duration(milliseconds: 600));

    switch (_mode) {
      case _SliverDemoMode.success:
        final items = List.generate(request.pageSize, (index) => index + 1);
        return PageResult(items: items, hasNext: false, hasPrevious: false);
      case _SliverDemoMode.empty:
        return const PageResult(items: [], hasNext: false, hasPrevious: false);
      case _SliverDemoMode.error:
        throw Exception("Sliver demo error");
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(title: const Text("Sliver Empty/Error Demo"), pinned: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text("Select state:"),
                  _buildModeChip(_SliverDemoMode.success, "Success"),
                  _buildModeChip(_SliverDemoMode.empty, "Empty"),
                  _buildModeChip(_SliverDemoMode.error, "Error"),
                  FilterChip(
                    label: const Text("Show Grid"),
                    selected: _showGrid,
                    onSelected: (value) {
                      setState(() {
                        _showGrid = value;
                      });
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: () => controller.refresh(reason: "manual"),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reload"),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          if (!_showGrid)
            PagedSliverList<int, int>(
              controller: controller,
              emptyBuilder: (_) => const Center(child: Text("No items")),
              errorBuilder: (_, error) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error?.toString() ?? "Something went wrong"),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: () => controller.refresh(), child: const Text("Retry")),
                    ],
                  ),
                );
              },
              itemBuilder: (context, item, index) => ListTile(title: Text("Item $item")),
            ),
          if (_showGrid)
            PagedSliverGrid<int, int>(
              controller: controller,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.6),
              emptyBuilder: (_) => const Center(child: Text("No items")),
              errorBuilder: (_, error) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error?.toString() ?? "Something went wrong"),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: () => controller.refresh(), child: const Text("Retry")),
                    ],
                  ),
                );
              },
              itemBuilder: (context, item, index) => Card(child: Center(child: Text("Grid $item"))),
            ),
        ],
      ),
    );
  }

  Widget _buildModeChip(_SliverDemoMode mode, String label) {
    final bool selected = _mode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _mode = mode;
        });
        controller.refresh(reason: "mode_$label");
      },
    );
  }
}

enum _SliverDemoMode { success, empty, error }

class SliverGridDemoPage extends StatefulWidget {
  const SliverGridDemoPage({super.key});

  @override
  State<SliverGridDemoPage> createState() => _SliverGridDemoPageState();
}

class _SliverGridDemoPageState extends State<SliverGridDemoPage> {
  late final PaginationController<int, int> controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = PaginationController.pageBased(firstPageKey: 1, pageSize: 20, fetchPage: _fetchPage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.refresh(reason: "initial");
    });
  }

  Future<PageResult<int, int>> _fetchPage(PaginationRequest<int> request) async {
    await Future.delayed(const Duration(milliseconds: 650));
    final int page = request.pageKey ?? 1;
    final data = List.generate(request.pageSize, (index) => (page - 1) * request.pageSize + index);

    return PageResult(items: data, hasNext: page < 6, hasPrevious: page > 1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
            controller.fetchNext(reason: "auto");
          }
          return false;
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(title: const Text("Sliver Grid Demo"), floating: true, pinned: true),
            PagedSliverGrid<int, int>(
              controller: controller,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.6),
              itemBuilder: (context, item, index) {
                return Card(child: Center(child: Text("Grid $item")));
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}

class LayoutBuilderDemoPage extends StatefulWidget {
  const LayoutBuilderDemoPage({super.key});

  @override
  State<LayoutBuilderDemoPage> createState() => _LayoutBuilderDemoPageState();
}

class _LayoutBuilderDemoPageState extends State<LayoutBuilderDemoPage> {
  late final PaginationController<int, int> controller;
  _LayoutDemoMode _mode = _LayoutDemoMode.success;

  @override
  void initState() {
    super.initState();
    controller = PaginationController.pageBased(firstPageKey: 1, pageSize: 20, fetchPage: _fetchPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refresh(reason: "initial");
    });
  }

  Future<PageResult<int, int>> _fetchPage(PaginationRequest<int> request) async {
    await Future.delayed(const Duration(milliseconds: 700));

    switch (_mode) {
      case _LayoutDemoMode.success:
        final items = List.generate(request.pageSize, (index) => index + 1);
        return PageResult(items: items, hasNext: false, hasPrevious: false);
      case _LayoutDemoMode.empty:
        return const PageResult(items: [], hasNext: false, hasPrevious: false);
      case _LayoutDemoMode.error:
        throw Exception("Demo error: tap retry");
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PagedLayoutBuilder States")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text("Select state:"),
                _buildModeChip(_LayoutDemoMode.success, "Success"),
                _buildModeChip(_LayoutDemoMode.empty, "Empty"),
                _buildModeChip(_LayoutDemoMode.error, "Error"),
                OutlinedButton.icon(
                  onPressed: () => controller.refresh(reason: "manual"),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reload"),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: PagedLayoutBuilder<int, int>(
              controller: controller,
              loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
              emptyBuilder: (_) => const Center(child: Text("Nothing here yet")),
              errorBuilder: (context, error) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error?.toString() ?? "Something went wrong"),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: () => controller.refresh(), child: const Text("Retry")),
                    ],
                  ),
                );
              },
              builder: (context, state) {
                return PagedListView<int, int>(
                  controller: controller,
                  itemBuilder: (context, item, index) => ListTile(title: Text("Item $item")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(_LayoutDemoMode mode, String label) {
    final bool selected = _mode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _mode = mode;
        });
        controller.refresh(reason: "mode_$label");
      },
    );
  }
}

enum _LayoutDemoMode { success, empty, error }

class PaginationCubit extends Cubit<PaginationState<int, int>> {
  final PaginationController<int, int> controller;

  PaginationCubit() : controller = PaginationController.pageBased(firstPageKey: 1, pageSize: 20, fetchPage: _fetchPageStatic), super(PaginationState.initial()) {
    emit(controller.value);
    controller.addListener(_onControllerChanged);
  }

  static Future<PageResult<int, int>> _fetchPageStatic(PaginationRequest<int> request) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final int page = request.pageKey ?? 1;
    final data = List.generate(request.pageSize, (index) => (page - 1) * request.pageSize + index);

    return PageResult(items: data, hasNext: page < 6, hasPrevious: page > 1);
  }

  void _onControllerChanged() {
    emit(controller.value);
  }

  Future<void> refresh() => controller.refresh();

  @override
  Future<void> close() {
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    return super.close();
  }
}

class BlocDemoPage extends StatefulWidget {
  const BlocDemoPage({super.key});

  @override
  State<BlocDemoPage> createState() => _BlocDemoPageState();
}

class _BlocDemoPageState extends State<BlocDemoPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh(PaginationCubit cubit) async {
    await cubit.refresh();
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaginationCubit(),
      child: Builder(
        builder: (context) {
          final cubit = context.read<PaginationCubit>();

          return Scaffold(
            appBar: AppBar(
              title: const Text("Bloc Pagination Demo"),
              actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => _refresh(cubit))],
            ),
            body: PagedListView<int, int>(
              controller: cubit.controller,
              scrollController: _scrollController,
              itemBuilder: (context, item, index) => ListTile(title: Text("Item $item")),
            ),
          );
        },
      ),
    );
  }
}
