import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_service.dart';
import '../models/network_info.dart';

/// 网络状态指示器
class NetworkStatusWidget extends StatelessWidget {
  final bool showLabel;
  final Color? onlineColor;
  final Color? offlineColor;
  final VoidCallback? onTap;

  const NetworkStatusWidget({
    super.key,
    this.showLabel = true,
    this.onlineColor,
    this.offlineColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkService>(
      builder: (context, networkService, child) {
        final isOnline = networkService.isOnline;
        final statusText = isOnline ? '网络正常' : '网络断开';
        final statusColor = isOnline 
            ? (onlineColor ?? Colors.green) 
            : (offlineColor ?? Colors.red);

        Widget statusWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );

        if (onTap != null) {
          return GestureDetector(
            onTap: onTap,
            child: statusWidget,
          );
        }

        return statusWidget;
      },
    );
  }
}

/// 网络状态栏
class NetworkStatusBar extends StatelessWidget {
  final double height;
  final Duration animationDuration;

  const NetworkStatusBar({
    super.key,
    this.height = 24.0,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkService>(
      builder: (context, networkService, child) {
        return AnimatedContainer(
          duration: animationDuration,
          height: networkService.isOffline ? height : 0,
          color: Colors.red,
          child: networkService.isOffline
              ? Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '网络连接已断开',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          // 触发网络检查
                          networkService._checkConnectivity();
                        },
                        child: const Text(
                          '重试',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

/// 网络加载状态组件
class NetworkLoadingWidget extends StatelessWidget {
  final String message;
  final Widget? child;
  final VoidCallback? onRetry;

  const NetworkLoadingWidget({
    super.key,
    this.message = '加载中...',
    this.child,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkService>(
      builder: (context, networkService, child) {
        if (networkService.isOffline) {
          return _buildOfflineWidget(context);
        }

        if (networkService.status == NetworkStatus.checking) {
          return _buildCheckingWidget(context);
        }

        return child ?? const SizedBox.shrink();
      },
    );
  }

  Widget _buildOfflineWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '网络连接已断开',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请检查网络设置后重试',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckingWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '正在检查网络连接...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// 带网络状态检查的列表组件
class NetworkListView extends StatefulWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final bool shrinkWrap;
  final EdgeInsets? padding;
  final Widget? separator;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoadMore;
  final bool hasMore;

  const NetworkListView({
    super.key,
    required this.children,
    this.controller,
    this.shrinkWrap = false,
    this.padding,
    this.separator,
    this.emptyWidget,
    this.loadingWidget,
    this.onRefresh,
    this.onLoadMore,
    this.hasMore = false,
  });

  @override
  State<NetworkListView> createState() => _NetworkListViewState();
}

class _NetworkListViewState extends State<NetworkListView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkService>(
      builder: (context, networkService, child) {
        if (networkService.isOffline) {
          return widget.emptyWidget ?? _buildDefaultEmptyWidget();
        }

        if (widget.children.isEmpty) {
          return widget.emptyWidget ?? _buildDefaultEmptyWidget();
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (scrollNotification is ScrollEndNotification) {
              final metrics = scrollNotification.metrics;
              if (metrics.pixels >= metrics.maxScrollExtent - 200 && 
                  widget.hasMore && 
                  widget.onLoadMore != null) {
                widget.onLoadMore!();
              }
            }
            return false;
          },
          child: widget.separator != null
              ? ListView.separated(
                  controller: widget.controller,
                  shrinkWrap: widget.shrinkWrap,
                  padding: widget.padding,
                  itemCount: widget.children.length + (widget.hasMore ? 1 : 0),
                  separatorBuilder: (context, index) => widget.separator!,
                  itemBuilder: (context, index) {
                    if (index == widget.children.length) {
                      return widget.loadingWidget ??
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                    }
                    return widget.children[index];
                  },
                )
              : ListView.builder(
                  controller: widget.controller,
                  shrinkWrap: widget.shrinkWrap,
                  padding: widget.padding,
                  itemCount: widget.children.length + (widget.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == widget.children.length) {
                      return widget.loadingWidget ??
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                    }
                    return widget.children[index];
                  },
                ),
        );
      },
    );
  }

  Widget _buildDefaultEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无数据',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}