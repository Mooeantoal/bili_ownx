import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/error_handler.dart';

/// 网络状态
enum NetworkStatus {
  online,    // 在线
  offline,   // 离线
  checking,  // 检查中
}

/// 网络状态服务
/// 用于监听和管理网络连接状态
class NetworkService extends ChangeNotifier {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  NetworkStatus _status = NetworkStatus.checking;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final List<String> _failedRequests = [];

  /// 当前网络状态
  NetworkStatus get status => _status;

  /// 是否在线
  bool get isOnline => _status == NetworkStatus.online;

  /// 是否离线
  bool get isOffline => _status == NetworkStatus.offline;

  /// 失败的请求列表
  List<String> get failedRequests => List.unmodifiable(_failedRequests);

  /// 初始化网络监听
  Future<void> initialize() async {
    // 检查当前网络状态
    await checkConnectivity();

    // 监听网络状态变化
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// 检查网络连接
  Future<void> checkConnectivity() async {
    try {
      _status = NetworkStatus.checking;
      notifyListeners();

      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);

      // 进一步验证网络是否真正可用
      if (result != ConnectivityResult.none) {
        await _validateNetworkConnection();
      }
    } catch (e) {
      _status = NetworkStatus.offline;
      notifyListeners();
    }
  }

  /// 更新连接状态
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (results.isNotEmpty) {
      final result = results.first;
      switch (result) {
        case ConnectivityResult.wifi:
        case ConnectivityResult.mobile:
        case ConnectivityResult.ethernet:
        case ConnectivityResult.bluetooth:
        case ConnectivityResult.vpn:
        case ConnectivityResult.other:
          _status = NetworkStatus.online;
          break;
        case ConnectivityResult.none:
          _status = NetworkStatus.offline;
          break;
      }
    } else {
      _status = NetworkStatus.offline;
    }
    notifyListeners();
  }

  /// 验证网络连接是否真正可用
  Future<bool> _validateNetworkConnection() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final response = await dio.get('https://httpbin.org/status/200');

      if (response.statusCode == 200) {
        _status = NetworkStatus.online;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _status = NetworkStatus.offline;
      notifyListeners();
      return false;
    }
    return false;
  }

  /// 添加失败请求
  void addFailedRequest(String identifier) {
    if (!_failedRequests.contains(identifier)) {
      _failedRequests.add(identifier);
    }
  }

  /// 清除失败请求
  void clearFailedRequests() {
    _failedRequests.clear();
  }

  /// 重试所有失败请求
  Future<void> retryFailedRequests() async {
    if (!isOnline) return;

    // 这里可以添加具体的重试逻辑
    clearFailedRequests();
  }

  /// 创建带网络检查的 Dio 实例
  Dio createDioWithNetworkCheck() {
    final dio = Dio();

    // 添加请求拦截器
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (isOffline) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.unknown,
                error: '网络连接已断开',
              ),
            );
            return;
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout) {
            _status = NetworkStatus.offline;
            notifyListeners();
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  /// 执行带网络检查的请求
  Future<T> executeWithNetworkCheck<T>(
    Future<T> Function() request, {
    Duration timeout = const Duration(seconds: 30),
    int retryCount = 3,
    Duration retryDelay = const Duration(seconds: 2),
    RetryConfig? retryConfig,
  }) async {
    if (isOffline) {
      throw NetworkException('网络连接已断开，请检查网络设置');
    }

    final config = retryConfig ?? RetryConfig.defaultConfig;
    int attempts = 0;

    while (attempts < config.maxRetries) {
      try {
        return await request().timeout(timeout);
      } catch (e) {
        attempts++;

        // 检查是否应该重试
        if (!config.shouldRetry(e, attempts)) {
          // 更新网络状态
          if (ErrorHandler.isNetworkError(e)) {
            _status = NetworkStatus.offline;
            notifyListeners();
          }
          rethrow;
        }

        // 等待后重试
        await Future.delayed(config.getRetryDelay(attempts));
      }
    }

    throw NetworkException('请求失败，已重试 ${config.maxRetries} 次');
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}

/// 网络异常类
class NetworkException implements Exception {
  final String message;
  final String? code;

  const NetworkException(this.message, {this.code});

  @override
  String toString() => message;
}

/// 网络状态监听器
class NetworkStatusListener {
  final NetworkService _networkService;
  final void Function(NetworkStatus) onStatusChanged;

  NetworkStatusListener(this._networkService, {required this.onStatusChanged}) {
    _networkService.addListener(_handleStatusChange);
  }

  void _handleStatusChange() {
    onStatusChanged(_networkService.status);
  }

  void dispose() {
    _networkService.removeListener(_handleStatusChange);
  }
}
