import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_strings.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final userProvider = context.watch<UserProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.get('settings')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section (if logged in)
            if (userProvider.hasProfile) ...[
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) {
                          final photoPath = userProvider.profile?.profilePhotoPath;
                          final hasValidPhoto = photoPath != null && File(photoPath).existsSync();
                          return CircleAvatar(
                            radius: 28,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            backgroundImage: hasValidPhoto
                                ? FileImage(File(photoPath))
                                : null,
                            child: !hasValidPhoto
                                ? Text(
                                    (userProvider.profile?.name?.isNotEmpty == true)
                                        ? userProvider.profile!.name![0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProvider.profile?.name ?? 'User',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userProvider.profile?.tradeName ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: subtitleColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Section: Appearance
            _SectionHeader(title: s.get('appearance'), isDark: isDark),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _OptionTile(
                    icon: Icons.light_mode_rounded,
                    iconColor: const Color(0xFFFBBF24),
                    title: s.get('light'),
                    subtitle: s.get('light_desc'),
                    isSelected: !themeProvider.isDark,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      themeProvider.setThemeMode(ThemeMode.light);
                    },
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _OptionTile(
                    icon: Icons.dark_mode_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: s.get('dark'),
                    subtitle: s.get('dark_desc'),
                    isSelected: themeProvider.isDark,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      themeProvider.setThemeMode(ThemeMode.dark);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Section: Language
            _SectionHeader(title: s.get('language'), isDark: isDark),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _OptionTile(
                    icon: Icons.language_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: s.get('english'),
                    subtitle: s.get('english_desc'),
                    isSelected: localeProvider.languageCode == 'en',
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      localeProvider.setLocale(const Locale('en'));
                    },
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _OptionTile(
                    icon: Icons.translate_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: s.get('hindi'),
                    subtitle: s.get('hindi_desc'),
                    isSelected: localeProvider.languageCode == 'hi',
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      localeProvider.setLocale(const Locale('hi'));
                    },
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _OptionTile(
                    icon: Icons.translate_rounded,
                    iconColor: const Color(0xFFFF6B35),
                    title: s.get('marathi'),
                    subtitle: s.get('marathi_desc'),
                    isSelected: localeProvider.languageCode == 'mr',
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      localeProvider.setLocale(const Locale('mr'));
                    },
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _OptionTile(
                    icon: Icons.translate_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: s.get('tamil'),
                    subtitle: s.get('tamil_desc'),
                    isSelected: localeProvider.languageCode == 'ta',
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      localeProvider.setLocale(const Locale('ta'));
                    },
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _OptionTile(
                    icon: Icons.translate_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: s.get('telugu'),
                    subtitle: s.get('telugu_desc'),
                    isSelected: localeProvider.languageCode == 'te',
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      localeProvider.setLocale(const Locale('te'));
                    },
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _OptionTile(
                    icon: Icons.translate_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: s.get('bengali'),
                    subtitle: s.get('bengali_desc'),
                    isSelected: localeProvider.languageCode == 'bn',
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      localeProvider.setLocale(const Locale('bn'));
                    },
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _OptionTile(
                    icon: Icons.translate_rounded,
                    iconColor: const Color(0xFFEC4899),
                    title: s.get('gujarati'),
                    subtitle: s.get('gujarati_desc'),
                    isSelected: localeProvider.languageCode == 'gu',
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      localeProvider.setLocale(const Locale('gu'));
                    },
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _OptionTile(
                    icon: Icons.translate_rounded,
                    iconColor: const Color(0xFF06B6D4),
                    title: s.get('punjabi'),
                    subtitle: s.get('punjabi_desc'),
                    isSelected: localeProvider.languageCode == 'pa',
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      localeProvider.setLocale(const Locale('pa'));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Section: About
            _SectionHeader(title: s.get('about'), isDark: isDark),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.info_outline_rounded,
                    title: s.get('version'),
                    trailing: Text(
                      '1.0.0',
                      style: TextStyle(color: subtitleColor, fontSize: 15),
                    ),
                    isDark: isDark,
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _InfoTile(
                    icon: Icons.auto_awesome_rounded,
                    title: s.get('ai_engine'),
                    trailing: Text(
                      'Gemini 2.0 Flash',
                      style: TextStyle(color: subtitleColor, fontSize: 15),
                    ),
                    isDark: isDark,
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _InfoTile(
                    icon: Icons.favorite_rounded,
                    title: s.get('made_with'),
                    trailing: Text(
                      'Flutter & Dart',
                      style: TextStyle(color: subtitleColor, fontSize: 15),
                    ),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Section: Support
            _SectionHeader(title: s.get('support'), isDark: isDark),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.help_outline_rounded,
                    title: s.get('help_faq'),
                    isDark: isDark,
                    onTap: () => HapticFeedback.lightImpact(),
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _ActionTile(
                    icon: Icons.privacy_tip_outlined,
                    title: s.get('privacy_policy'),
                    isDark: isDark,
                    onTap: () => HapticFeedback.lightImpact(),
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _ActionTile(
                    icon: Icons.description_outlined,
                    title: s.get('terms'),
                    isDark: isDark,
                    onTap: () => HapticFeedback.lightImpact(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Section: Account
            _SectionHeader(title: s.get('account'), isDark: isDark),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  // Show auth status
                  Builder(
                    builder: (context) {
                      final authProvider = context.watch<AuthProvider>();
                      return _InfoTile(
                        icon: authProvider.isAuthenticated 
                            ? Icons.verified_user_rounded 
                            : Icons.person_off_rounded,
                        title: s.get('auth_status'),
                        trailing: Text(
                          authProvider.isAuthenticated 
                              ? (localeProvider.languageCode == 'hi' ? 'लॉग इन' : 'Logged In')
                              : (localeProvider.languageCode == 'hi' ? 'लॉग आउट' : 'Not Logged In'),
                          style: TextStyle(
                            color: authProvider.isAuthenticated 
                                ? Colors.green 
                                : subtitleColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        isDark: isDark,
                      );
                    },
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _ActionTile(
                    icon: Icons.logout_rounded,
                    title: s.get('logout'),
                    isDark: isDark,
                    isDestructive: true,
                    onTap: () => _showLogoutConfirmation(context, s, localeProvider),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Center(
              child: Text(
                'Pragati Connect © 2025',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.grey.shade500,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Reusable option tile (for both theme and language) ──────────────────────

class _OptionTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        color: _pressed
            ? (widget.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade100)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: widget.isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: widget.isSelected
                  ? Icon(
                      Icons.check_circle_rounded,
                      key: const ValueKey('selected'),
                      color: widget.isDark
                          ? const Color(0xFF6AAFD4)
                          : const Color(0xFF355872),
                      size: 24,
                    )
                  : Icon(
                      Icons.circle_outlined,
                      key: const ValueKey('unselected'),
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.grey.shade300,
                      size: 24,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info tile ───────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final bool isDark;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  (isDark ? const Color(0xFF6AAFD4) : const Color(0xFF355872))
                      .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFF6AAFD4) : const Color(0xFF355872),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// ─── Logout confirmation dialog ──────────────────────────────────────────────

void _showLogoutConfirmation(BuildContext context, S s, LocaleProvider localeProvider) {
  HapticFeedback.lightImpact();
  final isHindi = localeProvider.languageCode == 'hi';
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isHindi ? 'लॉग आउट करें?' : 'Log Out?'),
      content: Text(
        isHindi 
            ? 'आप लॉग आउट हो जाएंगे और ऑनबोर्डिंग पर वापस जाएंगे। क्या आप जारी रखना चाहते हैं?'
            : 'You will be logged out and taken back to onboarding. Do you want to continue?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            
            // Clear auth state
            final authProvider = context.read<AuthProvider>();
            await authProvider.logout();
            
            // Clear user profile
            final userProvider = context.read<UserProvider>();
            await userProvider.clearProfile();
            
            // Navigate to onboarding
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/onboarding',
                (route) => false,
              );
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: Text(isHindi ? 'लॉग आउट' : 'Log Out'),
        ),
      ],
    ),
  );
}

// ─── Action tile ─────────────────────────────────────────────────────────────

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isDestructive 
        ? Colors.red 
        : (widget.isDark ? const Color(0xFF6AAFD4) : const Color(0xFF355872));
    final textColor = widget.isDestructive 
        ? Colors.red 
        : (widget.isDark ? Colors.white : Colors.black);
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        color: _pressed
            ? (widget.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade100)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
