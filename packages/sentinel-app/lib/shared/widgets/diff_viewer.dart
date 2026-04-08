import 'package:flutter/material.dart';

/// Git-style diff 查看器
///
/// 解析标准 unified diff 格式，行级别高亮：
///   + 新增行 → 绿色背景
///   - 删除行 → 红色背景
///   @ hunk header → 蓝色
///   其余 → 上下文灰色
class DiffViewer extends StatelessWidget {
  final String diff;

  const DiffViewer({super.key, required this.diff});

  @override
  Widget build(BuildContext context) {
    final lines = diff.split('\n');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 统计栏
          _DiffStats(lines: lines, isDark: isDark),
          const Divider(height: 1),
          // Diff 内容
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: lines.asMap().entries.map((entry) {
                  return _DiffLine(
                    lineNumber: entry.key + 1,
                    text: entry.value,
                    isDark: isDark,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Diff 统计：+X 行 / -Y 行
class _DiffStats extends StatelessWidget {
  final List<String> lines;
  final bool isDark;

  const _DiffStats({required this.lines, required this.isDark});

  @override
  Widget build(BuildContext context) {
    int added = 0, removed = 0;
    for (final line in lines) {
      if (line.startsWith('+') && !line.startsWith('+++')) added++;
      if (line.startsWith('-') && !line.startsWith('---')) removed++;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          const SizedBox(width: 6),
          Text('${lines.length} 行',
              style: TextStyle(fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
          const SizedBox(width: 12),
          if (added > 0) ...[
            Text('+$added', style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
            const SizedBox(width: 8),
          ],
          if (removed > 0)
            Text('-$removed', style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
        ],
      ),
    );
  }
}

/// 单行 Diff
class _DiffLine extends StatelessWidget {
  final int lineNumber;
  final String text;
  final bool isDark;

  const _DiffLine({
    required this.lineNumber,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final type = _lineType(text);

    return Container(
      color: _bgColor(type),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 行号
          SizedBox(
            width: 32,
            child: Text(
              '$lineNumber',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 内容
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: _textColor(type),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _LineType _lineType(String line) {
    if (line.startsWith('@@')) return _LineType.hunk;
    if (line.startsWith('+++') || line.startsWith('---')) return _LineType.header;
    if (line.startsWith('+')) return _LineType.added;
    if (line.startsWith('-')) return _LineType.removed;
    return _LineType.context;
  }

  Color _bgColor(_LineType type) {
    switch (type) {
      case _LineType.added:
        return isDark
            ? const Color(0xFF0D2818)  // 深绿
            : const Color(0xFFE6FFEC); // 浅绿
      case _LineType.removed:
        return isDark
            ? const Color(0xFF2D0B0B)  // 深红
            : const Color(0xFFFFEBE9); // 浅红
      case _LineType.hunk:
        return isDark
            ? const Color(0xFF0D1B2A)  // 深蓝
            : const Color(0xFFE3F2FD); // 浅蓝
      default:
        return Colors.transparent;
    }
  }

  Color _textColor(_LineType type) {
    switch (type) {
      case _LineType.added: return isDark ? Colors.green.shade300 : Colors.green.shade800;
      case _LineType.removed: return isDark ? Colors.red.shade300 : Colors.red.shade800;
      case _LineType.hunk: return isDark ? Colors.blue.shade300 : Colors.blue.shade700;
      case _LineType.header: return isDark ? Colors.grey.shade500 : Colors.grey.shade600;
      case _LineType.context: return isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    }
  }
}

enum _LineType { added, removed, hunk, header, context }

/// 可折叠的 Diff 面板 — 集成到 ApprovalCard 使用
class CollapsibleDiff extends StatelessWidget {
  final String? diff;

  const CollapsibleDiff({super.key, this.diff});

  @override
  Widget build(BuildContext context) {
    if (diff == null || diff!.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Theme(
        // 去掉 ExpansionTile 的默认边框
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          leading: Icon(Icons.diff, size: 18,
              color: Theme.of(context).colorScheme.primary),
          title: Text('查看文件变更',
              style: TextStyle(fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500)),
          children: [
            DiffViewer(diff: diff!),
          ],
        ),
      ),
    );
  }
}
