import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/network_status.dart';

class NetworkBanner extends StatelessWidget {
  const NetworkBanner({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final network = context.watch<NetworkStatus>();
    if (network.isOnline) return const SizedBox.shrink();

    return MaterialBanner(
      content: Text(network.message),
      leading: const Icon(Icons.wifi_off),
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: const Text('Повторить'),
          ),
      ],
    );
  }
}
