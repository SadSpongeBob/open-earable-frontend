import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/app/routing/deep_link_service.dart';
import 'package:openearable/app/routing/router_provider.dart';
import 'package:openearable/features/auth/controllers/auth_controller.dart';

class AppBootstrapper extends ConsumerStatefulWidget {
  const AppBootstrapper({super.key});

  @override
  ConsumerState<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends ConsumerState<AppBootstrapper> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final router = ref.read(routerProvider);
      await ref.read(deepLinkServiceProvider).init(router);

      await ref.read(authControllerProvider).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
