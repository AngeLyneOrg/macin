import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:macin/features/ai_tutor/presentation/pages/ai_tutor_page.dart';
import 'package:macin/features/auth/presentation/pages/register_page.dart';
import 'package:macin/features/profile/presentation/pages/profile_page.dart';
import 'package:macin/features/wallet/presentation/pages/wallet_page.dart';
import 'package:macin/shared/services/local_auth_cache.dart';
import 'core/constants/app_theme.dart';
import 'router/app_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation portrait uniquement (application mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Couleur de la status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await LocalAuthCache.init();

  runApp(const MacinApp());
}

/// Widget racine de l'application MACIN.
///
/// Ce widget est le seul à connaître le [AppRouter] et le [AppTheme].
/// Toutes les autres pages reçoivent le thème via le contexte.
class MacinApp extends StatelessWidget {
  const MacinApp({super.key});

  @override
  Widget build(BuildContext context) {
    // return MaterialApp.router(
    //   title: 'MACIN',
    //   debugShowCheckedModeBanner: false,
    //
    //   // ── Thème ─────────────────────────────────────────────
    //   theme: AppTheme.light(),
    //   darkTheme: AppTheme.dark(),
    //   themeMode: ThemeMode.system,
    //
    //   // ── Navigation ────────────────────────────────────────
    //   routerConfig: AppRouter.router,
    // );

    return MaterialApp(
      title: 'MACIN',
      debugShowCheckedModeBanner: true,

      // ── Thème ─────────────────────────────────────────────
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: WalletPage(),
    );
  }
}
