// @telos L1:function:lib/app:app

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

/// The root widget of the Bento application.
///
/// Configures [MaterialApp.router] with go_router navigation and theming.
class BentoApp extends ConsumerWidget {
  const BentoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Bento',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: BentoTheme.light,
      darkTheme: BentoTheme.dark,
      themeMode: ThemeMode.system,

      // Router configuration
      routerConfig: router,
    );
  }
}
