import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'shared/providers/theme_provider.dart';

class DreamTogetherApp extends ConsumerWidget {
  const DreamTogetherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync profile row after every sign-in, including OAuth redirects.
    ref.listen(authStateProvider, (_, next) {
      if (next.value?.event == AuthChangeEvent.signedIn) {
        ref.read(authActionsProvider).syncProfile();
      }
    });

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'DreamTogether',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
