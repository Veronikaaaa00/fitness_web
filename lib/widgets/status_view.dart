import 'dart:async';

import 'package:flutter/material.dart';

import '../state/load_status.dart';

/// Общий индикатор состояний списка.
/// Состояние loading держится минимум ~450 мс, чтобы спиннер было видно на защите/скринах.
class StatusView extends StatefulWidget {
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
  State<StatusView> createState() => _StatusViewState();
}

class _StatusViewState extends State<StatusView> {
  static const _minLoading = Duration(milliseconds: 450);

  late LoadStatus _shown;
  DateTime? _loadingStarted;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _shown = widget.status;
    if (widget.status == LoadStatus.loading || widget.status == LoadStatus.idle) {
      _loadingStarted = DateTime.now();
    }
  }

  @override
  void didUpdateWidget(covariant StatusView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyStatus(widget.status);
  }

  void _applyStatus(LoadStatus next) {
    if (next == LoadStatus.loading || next == LoadStatus.idle) {
      _timer?.cancel();
      _loadingStarted ??= DateTime.now();
      if (_shown != LoadStatus.loading) {
        setState(() => _shown = LoadStatus.loading);
      }
      return;
    }

    if (_shown == LoadStatus.loading) {
      final started = _loadingStarted ?? DateTime.now();
      final elapsed = DateTime.now().difference(started);
      _loadingStarted = null;
      if (elapsed < _minLoading) {
        _timer?.cancel();
        _timer = Timer(_minLoading - elapsed, () {
          if (!mounted) return;
          setState(() => _shown = next);
        });
        return;
      }
    }

    _timer?.cancel();
    if (_shown != next) {
      setState(() => _shown = next);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_shown) {
      LoadStatus.loading || LoadStatus.idle => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Загрузка…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
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
                  widget.emptyTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                if (widget.emptySubtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.emptySubtitle!,
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
                  widget.message ?? 'Не удалось загрузить данные',
                  textAlign: TextAlign.center,
                ),
                if (widget.onRetry != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: widget.onRetry,
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
