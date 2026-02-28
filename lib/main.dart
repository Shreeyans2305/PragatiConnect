import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/user_profile_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/scheme_assistant_screen.dart';
import 'screens/voice_assistant_screen.dart';
import 'screens/business_boost_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/schemes_screen.dart';
import 'screens/scheme_detail_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PragatiConnectApp());
}

class PragatiConnectApp extends StatefulWidget {
  const PragatiConnectApp({super.key});

  @override
  State<PragatiConnectApp> createState() => _PragatiConnectAppState();
}

class _PragatiConnectAppState extends State<PragatiConnectApp> {
  final ThemeProvider _themeProvider = ThemeProvider();
  final LocaleProvider _localeProvider = LocaleProvider();
  final UserProfileProvider _profileProvider = UserProfileProvider();

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(() => setState(() {}));
    _localeProvider.addListener(() => setState(() {}));
    _profileProvider.addListener(() => setState(() {}));
    _profileProvider.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pragati Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(_localeProvider.isHindi),
      darkTheme: AppTheme.darkTheme(_localeProvider.isHindi),
      themeMode: _themeProvider.themeMode,
      locale: _localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: (settings) {
        final routes = <String, WidgetBuilder>{
          '/': (_) => DashboardScreen(profileProvider: _profileProvider),
          '/scheme-assistant': (_) => const SchemeAssistantScreen(),
          '/voice-assistant': (_) =>
              VoiceAssistantScreen(profileProvider: _profileProvider),
          '/business-boost': (_) => const BusinessBoostScreen(),
          '/settings': (_) => SettingsScreen(
            themeProvider: _themeProvider,
            localeProvider: _localeProvider,
          ),
          '/schemes': (_) => const SchemesScreen(),
          '/ai-chat': (_) => AiChatScreen(profileProvider: _profileProvider),
          '/scheme-detail': (_) => SchemeDetailScreen(
            schemeName: settings.arguments as String? ?? '',
          ),
          '/profile': (_) => ProfileScreen(profileProvider: _profileProvider),
        };

        final builder = routes[settings.name];
        if (builder == null) {
          return MaterialPageRoute(
            builder: (_) => DashboardScreen(profileProvider: _profileProvider),
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
