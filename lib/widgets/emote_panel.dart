import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/comment_info.dart';
import '../services/comment_state_service.dart';

/// 表情包选择面板 - 参考BLVD项目
class EmotePanel extends StatefulWidget {
  final Function(EmoteItem) onEmoteSelected;
  final String? searchText;

  const EmotePanel({
    Key? key,
    required this.onEmoteSelected,
    this.searchText,
  }) : super(key: key);

  @override
  State<EmotePanel> createState() => _EmotePanelState();
}

class _EmotePanelState extends State<EmotePanel>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentPackageIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<EmoteItem> _filteredEmotes = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchText ?? '';
    _searchController.addListener(_onSearchChanged);
    
    final commentStateService = Provider.of<CommentStateService>(context, listen: false);
    if (commentStateService.emoteResponse == null) {
      commentStateService.loadEmotes();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTabController();
    });
  }

  void _updateTabController() {
    final commentStateService = Provider.of<CommentStateService>(context, listen: false);
    final packages = commentStateService.emoteResponse?.packages ?? [];
    if (packages.isNotEmpty && _tabController.length != packages.length) {
      _tabController.dispose();
      _tabController = TabController(length: packages.length, vsync: this);
      _tabController.addListener(() {
        setState(() {
          _currentPackageIndex = _tabController.index;
        });
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final text = _searchController.text.trim();
    setState(() {
      _isSearching = text.isNotEmpty;
      if (_isSearching) {
        _filteredEmotes = _searchEmotes(text);
      }
    });
  }

  List<EmoteItem> _searchEmotes(String query) {
    final commentStateService = Provider.of<CommentStateService>(context, listen: false);
    final emoteResponse = commentStateService.emoteResponse;
    if (emoteResponse == null) return [];

    final allEmotes = <EmoteItem>[];
    
    // 添加所有包中的表情
    for (final package in emoteResponse.packages) {
      allEmotes.addAll(package.emotes);
    }
    
    // 添加独立的表情
    allEmotes.addAll(emoteResponse.emotes);
    
    // 搜索匹配的表情
    return allEmotes.where((emote) {
      return emote.text.toLowerCase().contains(query.toLowerCase()) ||
             emote.id.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final commentStateService = Provider.of<CommentStateService>(context);
    final emoteResponse = commentStateService.emoteResponse;
    final isLoadingEmotes = commentStateService.isLoadingEmotes;

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          if (isLoadingEmotes)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (emoteResponse == null)
            _buildEmptyState()
          else
            _buildEmoteContent(emoteResponse),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            '表情',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: '搜索表情',
          prefixIcon: Icon(Icons.search, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_emotions_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              '暂无表情包',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmoteContent(EmoteResponse emoteResponse) {
    if (_isSearching) {
      return _buildSearchResults();
    }

    return Column(
      children: [
        _buildTabBar(emoteResponse),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: emoteResponse.packages.map((package) {
              return _buildEmoteGrid(package.emotes);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return _buildEmoteGrid(_filteredEmotes);
  }

  Widget _buildTabBar(EmoteResponse emoteResponse) {
    if (emoteResponse.packages.length <= 1) return const SizedBox();

    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabs: emoteResponse.packages.map((package) {
        return Tab(
          text: package.text,
          icon: package.url.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: package.url,
                  width: 20,
                  height: 20,
                )
              : null,
        );
      }).toList(),
      labelStyle: const TextStyle(fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
    );
  }

  Widget _buildEmoteGrid(List<EmoteItem> emotes) {
    if (emotes.isEmpty) {
      return const Center(
        child: Text('该分类暂无表情'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: emotes.length,
      itemBuilder: (context, index) {
        final emote = emotes[index];
        return _buildEmoteItem(emote);
      },
    );
  }

  Widget _buildEmoteItem(EmoteItem emote) {
    return GestureDetector(
      onTap: () {
        widget.onEmoteSelected(emote);
        Navigator.of(context).pop();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey.shade50,
        ),
        child: Tooltip(
          message: emote.text,
          child: CachedNetworkImage(
            imageUrl: emote.url,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 1),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade200,
              child: Center(
                child: Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 快捷表情选择器
class QuickEmoteSelector extends StatelessWidget {
  final List<String> quickEmotes = const [
    '[doge]', '[笑哭]', '[呲牙]', '[偷笑]', '[可爱]', '[鬼脸]',
    '[玫瑰]', '[爱心]', '[蛋糕]', '[庆祝]', '[烟花]', '[红包]',
  ];

  final Function(String) onEmoteSelected;

  const QuickEmoteSelector({
    Key? key,
    required this.onEmoteSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final commentStateService = Provider.of<CommentStateService>(context);
    final emoteCache = commentStateService.emoteCache;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickEmotes.length,
        itemBuilder: (context, index) {
          final emoteKey = quickEmotes[index];
          final emote = emoteCache[emoteKey];
          
          return GestureDetector(
            onTap: () => onEmoteSelected(emoteKey),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey.shade100,
              ),
              child: emote != null
                  ? CachedNetworkImage(
                      imageUrl: emote.url,
                      fit: BoxFit.contain,
                    )
                  : Center(
                      child: Text(
                        emoteKey,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}