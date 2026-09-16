import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/acupuncture_repository.dart';
import 'data/acupoint_repository.dart';
import 'data/changelog_repository.dart';
import 'data/formula_oral_hint_repository.dart';
import 'data/formula_repository.dart';
import 'data/herb_repository.dart';
import 'data/settings_repository.dart';
import 'data/ziwei_rules_repository.dart';
import 'screens/home_screen.dart';
import 'screens/activation_screen.dart';
import 'services/license_service.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FormulaRepository.load();
  await FormulaOralHintRepository.load();
  await HerbRepository.load();
  await AcupunctureRepository.load();
  await AcupointRepository.load();
  await ChangelogRepository.load();
  await SettingsRepository.instance.load();
  // 紫微解读层外置规则；加载失败会在仓库内部静默降级为内建默认值，不影响启动。
  await ZiweiRulesRepository.load();
  runApp(const NiHaishaApp());
}

class NiHaishaApp extends StatefulWidget {
  const NiHaishaApp({super.key});

  @override
  State<NiHaishaApp> createState() => _NiHaishaAppState();
}

class _NiHaishaAppState extends State<NiHaishaApp> {
  late Future<LicenseInfo> _license = LicenseService.current();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsRepository.instance,
      builder: (context, _) {
        final settings = SettingsRepository.instance;
        return MaterialApp(
          title: '岐黄经方',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8B4513),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            extensions: [AppColors.light],
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8B4513),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            extensions: [AppColors.dark],
          ),
          home: FutureBuilder<LicenseInfo>(
            future: _license,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final child = snapshot.data!.isValid
                  ? HomeScreen(textScaleFactor: settings.textScaleFactor)
                  : ActivationScreen(
                      onActivated: (_) =>
                          setState(() => _license = LicenseService.current()),
                    );
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(settings.textScaleFactor),
                ),
                child: child,
              );
            },
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
          locale: const Locale('zh', 'CN'),
        );
      },
    );
  }
}
