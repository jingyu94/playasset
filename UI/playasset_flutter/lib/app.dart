import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_providers.dart';
import 'features/home/home_shell.dart';

class PlayAssetApp extends ConsumerWidget {
  const PlayAssetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);

    if (session.isBootstrapping) {
      return MaterialApp(
        title: 'PlayAsset',
        theme: AppTheme.lightTheme(),
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'PlayAsset',
      theme: AppTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      home: session.isAuthenticated ? const HomeShell() : const LoginPage(),
    );
  }
}
