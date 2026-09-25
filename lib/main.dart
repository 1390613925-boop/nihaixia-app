import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/distribution_config.dart';
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

class _NiHaishaAppState extends State<NiHaishaApp> with WidgetsBindingObserver {
  late Future<LicenseInfo> _license = LicenseService.current();
  Timer? _licenseTimer;

  @override
  void initState() {
    super.initState();
    if (licenseGateEnabled) {
      WidgetsBinding.instance.addObserver(this);
      _licenseTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _refreshLicense(),
      );
    }
  }

  void _refreshLicense() {
    if (mounted) setState(() => _license = LicenseService.current());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (licenseGateEnabled && state == AppLifecycleState.resumed) {
      _refreshLicense();
    }
  }

  @override
  void dispose() {
    _licenseTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsRepository.instance,
      builder: (context, _) {
        final settings = SettingsRepository.instance;
        return MaterialApp(
          title: '覓源方',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF176B68),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF3F7F6),
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                side: BorderSide(color: Color(0xFFD7E3E1)),
              ),
            ),
            navigationBarTheme: const NavigationBarThemeData(
              height: 72,
              indicatorColor: Color(0xFFD2EAE6),
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Color(0xFFF3F7F6),
              foregroundColor: Color(0xFF172321),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFFFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFC4D4D1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFC4D4D1)),
              ),
            ),
            dividerTheme: const DividerThemeData(color: Color(0xFFD7E3E1)),
            extensions: [AppColors.light],
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF63C7BF),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF101B1F),
            cardTheme: const CardThemeData(elevation: 0),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Color(0xFF101B1F),
            ),
            extensions: [AppColors.dark],
          ),
          home: licenseGateEnabled
              ? FutureBuilder<LicenseInfo>(
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
                            onActivated: (_) => _refreshLicense(),
                          );
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(settings.textScaleFactor),
                      ),
                      child: child,
                    );
                  },
                )
              : MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(settings.textScaleFactor),
                  ),
                  child: HomeScreen(textScaleFactor: settings.textScaleFactor),
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
