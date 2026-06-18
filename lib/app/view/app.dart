import 'package:cabina/app/widgets/app_dependency_injection.dart';
import 'package:cabina/common/router/router.dart';
import 'package:cabina/common/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CabinaApp extends StatefulWidget {
  const CabinaApp({required this.prefs, super.key});

  final SharedPreferences prefs;

  @override
  State<CabinaApp> createState() => _CabinaAppState();
}

class _CabinaAppState extends State<CabinaApp> {
  final GoRouter _router = RouterBuilder.build();

  @override
  Widget build(BuildContext context) {
    return AppDependencyInjection(
      prefs: widget.prefs,
      child: MaterialApp.router(
        title: 'Cabina',
        debugShowCheckedModeBanner: false,
        theme: AppTheme(isDark: false).toThemeData(),
        darkTheme: AppTheme(isDark: true).toThemeData(),
        routerConfig: _router,
      ),
    );
  }
}
