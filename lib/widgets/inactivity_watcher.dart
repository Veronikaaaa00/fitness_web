import 'dart:async';

import 'package:flutter/material.dart';

class InactivityWatcher extends StatefulWidget {
  const InactivityWatcher({
    super.key,
    required this.timeout,
    required this.warningBefore,
    required this.onWarning,
    required this.onTimeout,
    required this.child,
  });

  final Duration timeout;
  final Duration warningBefore;
  final VoidCallback onWarning;
  final VoidCallback onTimeout;
  final Widget child;

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _timeoutTimer;
  Timer? _warningTimer;
  Timer? _logoutTimer;
  Timer? _tickTimer;
  var _warned = false;
  var _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    _timeoutTimer?.cancel();
    _warningTimer?.cancel();
    _logoutTimer?.cancel();
    _tickTimer?.cancel();
    _warned = false;
    _secondsLeft = 0;
    if (mounted) setState(() {});

    final warnAt = widget.timeout - widget.warningBefore;
    if (warnAt > Duration.zero) {
      _warningTimer = Timer(warnAt, _armWarning);
    }
    _timeoutTimer = Timer(widget.timeout, _fireTimeout);
  }

  void _armWarning() {
    if (_warned || !mounted) return;
    _warned = true;
    _secondsLeft = widget.warningBefore.inSeconds;
    widget.onWarning();
    setState(() {});

    _logoutTimer?.cancel();
    _logoutTimer = Timer(widget.warningBefore, _fireTimeout);

    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft = (_secondsLeft - 1).clamp(0, 999));
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  void _fireTimeout() {
    if (!mounted) return;
    _timeoutTimer?.cancel();
    _warningTimer?.cancel();
    _logoutTimer?.cancel();
    _tickTimer?.cancel();
    widget.onTimeout();
  }

  /// До предупреждения любая активность сбрасывает таймер.
  /// После предупреждения — только кнопка «Остаться».
  void _onActivity() {
    if (_warned) return;
    _restart();
  }

  void _stayLoggedIn() => _restart();

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _warningTimer?.cancel();
    _logoutTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onActivity(),
      onPointerMove: (_) => _onActivity(),
      onPointerSignal: (_) => _onActivity(),
      child: Stack(
        children: [
          widget.child,
          if (_warned)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Material(
                elevation: 4,
                color: scheme.errorContainer,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Неактивность: выход через $_secondsLeft с.',
                            style: TextStyle(
                              color: scheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: _stayLoggedIn,
                          child: const Text('Остаться'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
