import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/environment.dart';
import 'theme.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/user_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/scheme_assistant_screen.dart';
import 'screens/voice_assistant_screen.dart';
import 'screens/business_boost_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/schemes_screen.dart';
import 'screens/scheme_detail_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  await Environment.initialize();

  // Initialize providers
  final themeProvider = ThemeProvider();
  final localeProvider = LocaleProvider();
  final userProvider = UserProvider();

  await Future.wait([
    themeProvider.initialize(),
    localeProvider.initialize(),
    userProvider.initialize(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: userProvider),
      ],
      child: const PragatiConnectApp(),
    ),
  );
}

class PragatiConnectApp extends StatelessWidget {
  const PragatiConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final userProvider = context.watch<UserProvider>();

    return MaterialApp(
      title: 'Pragati Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(localeProvider.isHindi),
      darkTheme: AppTheme.darkTheme(localeProvider.isHindi),
      themeMode: themeProvider.themeMode,
      locale: localeProvider.locale,
      supportedLocales: LocaleProvider.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Start with onboarding if not completed
      home: userProvider.onboardingComplete
          ? const DashboardScreen()
          : const OnboardingScreen(),
      onGenerateRoute: (settings) {
        final routes = <String, WidgetBuilder>{
          '/': (_) => userProvider.onboardingComplete
              ? const DashboardScreen()
              : const OnboardingScreen(),
          '/dashboard': (_) => const DashboardScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/scheme-assistant': (_) => const SchemeAssistantScreen(),
          '/voice-assistant': (_) => const VoiceAssistantScreen(),
          '/business-boost': (_) => const BusinessBoostScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/schemes': (_) => const SchemesScreen(),
          '/ai-chat': (_) => const AiChatScreen(),
          '/scheme-detail': (_) => SchemeDetailScreen(
                schemeName: settings.arguments as String? ?? '',
              ),
        };

        final builder = routes[settings.name];
        if (builder == null) {
          return MaterialPageRoute(
            builder: (_) => const DashboardScreen(),
            settings: settings,
          );
        }

        // Dashboard = no transition; it's the root
        if (settings.name == '/') {
          return MaterialPageRoute(builder: builder, settings: settings);
        }

        return _ApplePageRoute(builder: builder, settings: settings);
      },
    );
  }
}

/// Custom page route mimicking Apple's iOS page transition.
class _ApplePageRoute extends PageRouteBuilder {
  final WidgetBuilder builder;

  _ApplePageRoute({required this.builder, required RouteSettings settings})
    : super(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideIn =
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          final fadeIn = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          );

          return SlideTransition(
            position: slideIn,
            child: FadeTransition(
              opacity: Tween(begin: 0.85, end: 1.0).animate(fadeIn),
              child: child,
            ),
          );
        },
      );
}
