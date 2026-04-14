import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: CheckinCheckOutApp(),
    ),
  );
}

class CheckinCheckOutApp extends ConsumerWidget {
  const CheckinCheckOutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'CheckinCheckOut',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('ru'),
        Locale('kk'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
