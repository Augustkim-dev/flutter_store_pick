import 'package:flutter/material.dart';
import 'skeleton_loader.dart';
import 'error_widget_custom.dart';

typedef PaginatedItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index,
);

typedef PaginatedDataFetcher<T> = Future<List<T>> Function(
  int page,
  int pageSize,
);

class PaginatedListView<T> extends StatefulWidget {
  final PaginatedItemBuilder<T> itemBuilder;
  final PaginatedDataFetcher<T> dataFetcher;
  final int pageSize;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Widget? separator;

  const PaginatedListView({
    Key? key,
    required this.itemBuilder,
    required this.dataFetcher,
    this.pageSize = 20,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.separator,
  }) : super(key: key);

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _scrollController = ScrollController();
  final List<T> _items = [];
  
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isFirstLoad = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.dataFetcher(_currentPage, widget.pageSize);
      
      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length >= widget.pageSize;
        _isLoading = false;
        _isFirstLoad = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isFirstLoad = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _currentPage = 1;
      _hasMore = true;
      _isFirstLoad = true;
      _error = null;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstLoad && _isLoading) {
      return Center(
        child: widget.loadingWidget ?? const CircularProgressIndicator(),
      );
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: widget.errorWidget ??
            CustomErrorWidget(
              message: _error,
              errorType: ErrorType.general,
              onRetry: _refresh,
            ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: widget.emptyWidget ??
            const EmptyStateWidget(
              title: '데이터가 없습니다',
              message: '표시할 항목이 없습니다',
            ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) {
          return widget.separator ?? const SizedBox.shrink();
        },
        itemBuilder: (context, index) {
          if (index == _items.length) {
            // 로딩 인디케이터
            if (_error != null) {
              return _buildErrorTile();
            }
            return _buildLoadingTile();
          }
          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }

  Widget _buildLoadingTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildErrorTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            '더 불러오는 중 오류가 발생했습니다',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadMore,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

// 무한 스크롤 그리드뷰
class PaginatedGridView<T> extends StatefulWidget {
  final PaginatedItemBuilder<T> itemBuilder;
  final PaginatedDataFetcher<T> dataFetcher;
  final int pageSize;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry? padding;
  final Widget? emptyWidget;
  final Widget? loadingWidget;

  const PaginatedGridView({
    Key? key,
    required this.itemBuilder,
    required this.dataFetcher,
    this.pageSize = 20,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.padding,
    this.emptyWidget,
    this.loadingWidget,
  }) : super(key: key);

  @override
  State<PaginatedGridView<T>> createState() => _PaginatedGridViewState<T>();
}

class _PaginatedGridViewState<T> extends State<PaginatedGridView<T>> {
  final ScrollController _scrollController = ScrollController();
  final List<T> _items = [];
  
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newItems = await widget.dataFetcher(_currentPage, widget.pageSize);
      
      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length >= widget.pageSize;
        _isLoading = false;
        _isFirstLoad = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isFirstLoad = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _currentPage = 1;
      _hasMore = true;
      _isFirstLoad = true;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstLoad && _isLoading) {
      return Center(
        child: widget.loadingWidget ?? const CircularProgressIndicator(),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: widget.emptyWidget ??
            const EmptyStateWidget(
              title: '데이터가 없습니다',
            ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: GridView.builder(
        controller: _scrollController,
        padding: widget.padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          childAspectRatio: widget.childAspectRatio,
          crossAxisSpacing: widget.crossAxisSpacing,
          mainAxisSpacing: widget.mainAxisSpacing,
        ),
        itemCount: _items.length + (_hasMore && _isLoading ? widget.crossAxisCount : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            // 로딩 스켈레톤
            return const ShopCardSkeleton();
          }
          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}