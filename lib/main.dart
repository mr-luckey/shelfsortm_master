import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app/theme/app_theme.dart';
import 'data/level_repository.dart';
import 'providers/progress_provider.dart';
import 'providers/settings_provider.dart';
import 'services/ad_service.dart';
import 'services/audio_service.dart';
import 'services/iap_service.dart';
import 'services/save_service.dart';
import 'ui/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final save = SaveService();
  final audio = AudioService();
  await audio.init();
  final ads = AdService();
  final iap = IapService();
  await ads.init();
  await iap.init();
  final progress = ProgressProvider(
    saveService: save,
    adService: ads,
    iapService: iap,
  );
  await progress.init();
  await LevelRepository.instance.preload();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: save),
        Provider.value(value: audio),
        Provider.value(value: ads),
        Provider.value(value: iap),
        ChangeNotifierProvider.value(value: progress),
        ChangeNotifierProvider(create: (_) => SettingsProvider(audio)),
      ],
      child: const ShelfSortApp(),
    ),
  );
}

class ShelfSortApp extends StatelessWidget {
  const ShelfSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShelfSort Master',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
