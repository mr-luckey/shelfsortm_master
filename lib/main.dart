import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'app/theme/app_theme.dart';
import 'bloc/audio_cubit.dart';
import 'data/level_repository.dart';
import 'providers/progress_provider.dart';
import 'providers/settings_provider.dart';
import 'services/ad_service.dart';
import 'services/analytics_service.dart';
import 'services/iap_service.dart';
import 'services/local_notification_service.dart';
import 'services/save_service.dart';
import 'ui/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final save = SaveService();
  final audio = AudioCubit();
  await audio.init();
  final analytics = AnalyticsService();
  // Firebase.initializeApp requires google-services.json / GoogleService-Info.plist
  // (and typically firebase_options.dart from FlutterFire). Until those exist,
  // AnalyticsService stays idle and never blocks gameplay.
  await analytics.init();

  final notifications = LocalNotificationService(
    onTap: (payload) {
      unawaited(
        analytics.logNotificationOpened(
          notificationId: payload,
          source: 'local',
        ),
      );
    },
  );
  // Init only here. Permission + schedule run after first UI frame (Splash)
  // so Android 13+ can show the notification permission dialog.
  await notifications.init();

  final ads = AdService();
  final iap = IapService();
  await ads.init();
  await iap.init();
  final progress = ProgressProvider(
    saveService: save,
    adService: ads,
    iapService: iap,
    analytics: analytics,
  );
  await progress.init();
  await LevelRepository.instance.preload();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AudioCubit>.value(value: audio),
      ],
      child: MultiProvider(
        providers: [
          Provider.value(value: save),
          Provider<AnalyticsService>.value(value: analytics),
          Provider<LocalNotificationService>.value(value: notifications),
          ChangeNotifierProvider<AdService>.value(value: ads),
          Provider.value(value: iap),
          ChangeNotifierProvider.value(value: progress),
          ChangeNotifierProvider(create: (_) => SettingsProvider(audio)),
        ],
        child: const ShelfSortApp(),
      ),
    ),
  );
}

class ShelfSortApp extends StatelessWidget {
  const ShelfSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'ShelfSort Master',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: child,
        );
      },
      child: const SplashScreen(),
    );
  }
}
