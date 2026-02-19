import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/app/routing/deep_link_service.dart';
import 'package:openearable/app/routing/router_provider.dart';
import 'package:openearable/features/auth/controllers/auth_controller.dart';

/// A bootstrap widget responsible for initializing critical app services
/// right after the first frame is rendered.
///
/// This includes:
/// - Initializing deep link handling
/// - Bootstrapping the authentication state
///
/// Uses [ConsumerStatefulWidget] so it can access Riverpod providers
/// during the app startup lifecycle without rebuilding UI.
class AppBootstrapper extends ConsumerStatefulWidget {
  const AppBootstrapper({super.key});

  @override
  ConsumerState<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends ConsumerState<AppBootstrapper> {
  @override
  void initState() {
    super.initState();
    
    /// Schedules initialization after the first frame to safely access
    /// providers and avoid context-related issues during widget creation.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final router = ref.read(routerProvider);
      await ref.read(deepLinkServiceProvider).init(router);

      await ref.read(authControllerProvider).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
