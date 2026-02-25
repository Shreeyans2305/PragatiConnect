import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeProvider themeProvider;
  final LocaleProvider localeProvider;

  const SettingsScreen({
    super.key,
    required this.themeProvider,
    required this.localeProvider,
  });

  @override
  Widget build(BuildContext context) {
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
                    isSelected: !localeProvider.isHindi,
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
                    isSelected: localeProvider.isHindi,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      localeProvider.setLocale(const Locale('hi'));
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

// ─── Action tile ─────────────────────────────────────────────────────────────

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
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
                color:
                    (widget.isDark
                            ? const Color(0xFF6AAFD4)
                            : const Color(0xFF355872))
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon,
                color: widget.isDark
                    ? const Color(0xFF6AAFD4)
                    : const Color(0xFF355872),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black,
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
