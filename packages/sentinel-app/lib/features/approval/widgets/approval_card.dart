import 'package:flutter/material.dart';
import '../../../shared/models/approval_request.dart';

class ApprovalCard extends StatelessWidget {
  final ApprovalRequest request;
  final VoidCallback onAllow;
  final VoidCallback onBlock;

  const ApprovalCard({
    super.key,
    required this.request,
    required this.onAllow,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final isHighRisk = request.riskLevel == RiskLevel.requireFaceID;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isHighRisk
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  isHighRisk ? Icons.warning_amber : Icons.help_outline,
                  color: isHighRisk ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.toolName,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      if (_filePath != null)
                        Text(_filePath!,
                            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                // Countdown
                _CountdownChip(timeoutAt: request.timeoutAt),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onBlock,
                    icon: const Icon(Icons.close),
                    label: const Text('拒绝'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAllow,
                    icon: Icon(isHighRisk ? Icons.fingerprint : Icons.check),
                    label: const Text('允许'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? get _filePath =>
      request.toolInput['file_path'] as String? ??
      request.toolInput['command'] as String? ??
      request.toolInput['path'] as String?;
}

class _CountdownChip extends StatelessWidget {
  final DateTime timeoutAt;
  const _CountdownChip({required this.timeoutAt});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final remaining = timeoutAt.difference(DateTime.now()).inSeconds;
        final secs = remaining.clamp(0, 999);
        return Chip(
          label: Text('${secs}s',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: secs < 30 ? Colors.red : null,
              )),
          visualDensity: VisualDensity.compact,
        );
      },
    );
  }
}
