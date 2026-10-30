import 'package:flutter/material.dart';

import '../state/load_status.dart';

class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.status,
    this.message,
    this.onRetry,
    this.emptyTitle = 'Пока пусто',
    this.emptySubtitle,
  });

  final LoadStatus status;
  final String? message;
  final VoidCallback? onRetry;
  final String emptyTitle;
  final String? emptySubtitle;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      LoadStatus.loading || LoadStatus.idle => const Center(
          child: CircularProgressIndicator(),
        ),
      LoadStatus.empty => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  emptyTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                if (emptySubtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    emptySubtitle!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      LoadStatus.error => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  message ?? 'Не удалось загрузить данные',
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: onRetry,
                    child: const Text('Повторить'),
                  ),
                ],
              ],
            ),
          ),
        ),
      LoadStatus.success => const SizedBox.shrink(),
    };
  }
}
