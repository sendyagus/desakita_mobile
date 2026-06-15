import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import 'package:desa_wisata/app/app_routes.dart';
import 'package:desa_wisata/app/app_scroll_behavior.dart';
import 'package:desa_wisata/app/theme/app_theme.dart';
import 'package:desa_wisata/app/theme/theme_notifier.dart';

class DesaKitaApp extends StatelessWidget {
  const DesaKitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeNotifier.instance,
      builder: (context, _) {
        return MaterialApp(
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          scrollBehavior: const AppScrollBehavior(),
          title: 'DesaKita',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeNotifier.instance.mode,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
