import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_shell.dart';

class PlayAssetApp extends StatelessWidget {
  const PlayAssetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlayAsset',
      theme: AppTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      home: const HomeShell(),
    );
  }
}
