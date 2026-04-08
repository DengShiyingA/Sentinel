import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'transport.dart';
import 'lan_transport.dart';
import '../../shared/models/approval_request.dart';
import '../../shared/models/activity_item.dart';
import '../trust/temporary_trust.dart';

/// 连接状态枚举
enum ConnStatus { disconnected, connecting, connected, error }

/// 全局连接状态（不可变，每次更新创建新实例）
class SentinelState {
  final ConnectionMode mode;
  final ConnStatus status;
  final String? error;
  final String? host;

  // 审批 + 活动 + 终端数据（用新 list 替换触发 rebuild）
  final List<ApprovalRequest> pendingRequests;
  final List<ActivityItem> activityFeed;
  final List<TerminalLine> terminalLines;
  final int resolvedCount;
  final int newActivityCount;
  final String? syncToast;

  const SentinelState({
    this.mode = ConnectionMode.lan,
    this.status = ConnStatus.disconnected,
    this.error,
    this.host,
    this.pendingRequests = const [],
    this.activityFeed = const [],
    this.terminalLines = const [],
    this.resolvedCount = 0,
    this.newActivityCount = 0,
    this.syncToast,
  });

  bool get isConnected => status == ConnStatus.connected;

  SentinelState copyWith({
    ConnectionMode? mode,
    ConnStatus? status,
    String? error,
    String? host,
    List<ApprovalRequest>? pendingRequests,
    List<ActivityItem>? activityFeed,
    List<TerminalLine>? terminalLines,
    int? resolvedCount,
    int? newActivityCount,
    String? syncToast,
  }) {
    return SentinelState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      error: error,
      host: host ?? this.host,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      activityFeed: activityFeed ?? this.activityFeed,
      terminalLines: terminalLines ?? this.terminalLines,
      resolvedCount: resolvedCount ?? this.resolvedCount,
      newActivityCount: newActivityCount ?? this.newActivityCount,
      syncToast: syncToast,
    );
  }
}

/// 核心状态管理器 — 管理连接、审批、活动、终端
class SentinelNotifier extends Notifier<SentinelState> {
  Transport? _transport;

  @override
  SentinelState build() {
    _loadMode();
    return const SentinelState();
  }

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('sentinel.connectionMode') ?? 'lan';
    final mode = ConnectionMode.values.firstWhere(
      (m) => m.value == modeStr,
      orElse: () => ConnectionMode.lan,
    );
    state = state.copyWith(mode: mode);
  }

  // ==================== 连接管理 ====================

  /// 切换连接模式
  Future<void> switchMode(ConnectionMode mode) async {
    _transport?.disconnect();
    _transport = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sentinel.connectionMode', mode.value);
    state = state.copyWith(mode: mode, status: ConnStatus.disconnected, error: null);
  }

  /// 手动连接（LAN 模式，输入 host:port）
  Future<void> connectLan(String host, int port) async {
    _transport?.disconnect();
    state = state.copyWith(status: ConnStatus.connecting, error: null);

    final lan = LanTransport();
    _wireCallbacks(lan);
    _transport = lan;

    try {
      await lan.connectTo(host, port);
      state = state.copyWith(status: ConnStatus.connected, host: '$host:$port');
      debugPrint('[Provider] Connected to $host:$port');
    } catch (e) {
      state = state.copyWith(status: ConnStatus.error, error: e.toString());
      debugPrint('[Provider] Connect failed: $e');
    }
  }

  /// 断开连接
  void disconnect() {
    _transport?.disconnect();
    _transport = null;
    state = state.copyWith(status: ConnStatus.disconnected, error: null);
  }

  // ==================== 审批操作 ====================

  /// 发送审批决策
  void sendDecision(String requestId, Decision decision) {
    _transport?.sendDecision(requestId, decision);
    final updated = List<ApprovalRequest>.from(state.pendingRequests)
      ..removeWhere((r) => r.id == requestId);
    state = state.copyWith(
      pendingRequests: updated,
      resolvedCount: state.resolvedCount + 1,
    );
  }

  /// 发送用户消息给 Claude Code
  void sendUserMessage(String text) {
    _transport?.sendUserMessage(text);
    final msg = ActivityItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ActivityType.userMessage,
      summary: text,
      timestamp: DateTime.now(),
      message: text,
    );
    state = state.copyWith(
      activityFeed: [msg, ...state.activityFeed].take(50).toList(),
    );
  }

  /// 清除新活动计数（切换到消息 Tab 时调用）
  void clearNewActivity() {
    state = state.copyWith(newActivityCount: 0);
  }

  /// 清除终端
  void clearTerminal() {
    state = state.copyWith(terminalLines: []);
  }

  // ==================== 回调绑定 ====================

  void _wireCallbacks(Transport t) {
    // 收到审批请求 — 先检查临时信任，命中则自动允许
    t.onRequest = (request) {
      if (state.pendingRequests.any((r) => r.id == request.id)) return;

      // 检查临时信任规则
      final trust = ref.read(trustProvider.notifier);
      if (trust.checkAndAutoAllow(request)) {
        // 自动发送允许决策，不显示卡片
        _transport?.sendDecision(request.id, Decision.allowed);
        state = state.copyWith(resolvedCount: state.resolvedCount + 1);
        debugPrint('[Provider] Auto-allowed by trust rule: ${request.toolName}');
        return;
      }

      state = state.copyWith(
        pendingRequests: [request, ...state.pendingRequests],
      );
      debugPrint('[Provider] New request: ${request.toolName}');
    };

    // 收到活动事件
    t.onActivity = (item) {
      state = state.copyWith(
        activityFeed: [item, ...state.activityFeed].take(50).toList(),
        newActivityCount: state.newActivityCount + 1,
      );
    };

    // 收到终端输出
    t.onTerminal = (text) {
      final line = TerminalLine(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        timestamp: DateTime.now(),
      );
      final lines = [...state.terminalLines, line];
      if (lines.length > 500) lines.removeRange(0, lines.length - 500);
      state = state.copyWith(terminalLines: lines);
    };

    // 收到多设备决策同步
    t.onDecisionSync = (requestId) {
      final updated = List<ApprovalRequest>.from(state.pendingRequests)
        ..removeWhere((r) => r.id == requestId);
      state = state.copyWith(
        pendingRequests: updated,
        resolvedCount: state.resolvedCount + 1,
        syncToast: '已由其他设备处理',
      );
      // 2秒后清除 toast
      Future.delayed(const Duration(seconds: 2), () {
        if (state.syncToast != null) {
          state = state.copyWith(syncToast: null);
        }
      });
    };
  }
}

/// 全局 Provider
final connectionProvider =
    NotifierProvider<SentinelNotifier, SentinelState>(SentinelNotifier.new);
