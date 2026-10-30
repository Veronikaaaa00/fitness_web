import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_router.dart';
import 'core/app_theme.dart';
import 'core/auth_token_store.dart';
import 'core/pb_client.dart';
import 'repositories/auth_repository.dart';
import 'repositories/bookings_repository.dart';
import 'repositories/catalog_repository.dart';
import 'repositories/class_equipment_repository.dart';
import 'repositories/classes_repository.dart';
import 'repositories/equipment_repository.dart';
import 'repositories/member_profiles_repository.dart';
import 'repositories/memberships_repository.dart';
import 'repositories/plans_repository.dart';
import 'repositories/rooms_repository.dart';
import 'state/auth_notifier.dart';
import 'state/network_status.dart';
import 'widgets/inactivity_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  final tokens = AuthTokenStore();
  final network = NetworkStatus();

  late final AuthNotifier auth;
  late final AuthRepository authRepo;
  final dio = buildPbClient(
    tokenStore: tokens,
    network: network,
    onRefresh: () async {
      await authRepo.me();
    },
    onLogout: () => auth.logout(),
  );

  authRepo = AuthRepository(dio, tokens);
  auth = AuthNotifier(prefs, authRepo, tokens);
  await auth.restore();

  final router = createRouter(auth);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: network),
        Provider.value(value: dio),
        Provider.value(value: authRepo),
        Provider(create: (_) => RoomsRepository(dio)),
        Provider(create: (_) => PlansRepository(dio)),
        Provider(create: (_) => ClassesRepository(dio)),
        Provider(create: (_) => BookingsRepository(dio)),
        Provider(create: (_) => CatalogRepository(dio)),
        Provider(create: (_) => EquipmentRepository(dio)),
        Provider(create: (_) => MembershipsRepository(dio)),
        Provider(create: (_) => ClassEquipmentRepository(dio)),
        Provider(create: (_) => MemberProfilesRepository(dio)),
      ],
      child: FitnessApp(router: router),
    ),
  );
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    return MaterialApp.router(
      title: 'Фитнес-клуб',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!auth.isAuthenticated) {
          return content;
        }
        return InactivityWatcher(
          timeout: AuthNotifier.inactivityTimeout,
          warningBefore: AuthNotifier.inactivityWarning,
          onWarning: () {},
          onTimeout: () {
            final messenger = ScaffoldMessenger.of(context);
            context.read<AuthNotifier>().logout().then((_) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Выход по неактивности')),
              );
            });
          },
          child: content,
        );
      },
    );
  }
}
