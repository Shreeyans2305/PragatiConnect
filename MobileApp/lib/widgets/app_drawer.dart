import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../l10n/app_strings.dart';
import '../providers/user_provider.dart';
import '../providers/locale_provider.dart';
import '../models/user_profile.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;

  const AppDrawer({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF6AAFD4) : AppColors.primary;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : AppColors.textSecondary;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;
    final infoBgColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : AppColors.tertiary.withValues(alpha: 0.15);
    final s = S.of(context);
    final userProvider = context.watch<UserProvider>();
    final profile = userProvider.profile;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Header (if logged in)
            if (profile != null) ...[
              _buildUserHeader(context, profile, isDark, primaryColor, textColor, subtitleColor),
            ] else ...[
              // Default header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s.get('app_name'),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            fontSize: 20,
                          ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  s.get('empowering').replaceAll('\n', ' '),
                  style: TextStyle(color: subtitleColor, fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Divider(color: dividerColor, height: 1),
            const SizedBox(height: 12),

            // Nav Items
            _NavItem(
              icon: Icons.dashboard_rounded,
              label: s.get('dashboard'),
              isSelected: currentIndex == 0,
              onTap: () => _navigate(context, '/dashboard'),
            ),
            _NavItem(
              icon: Icons.policy_rounded,
              label: s.get('schemes'),
              isSelected: currentIndex == 1,
              onTap: () => _navigate(context, '/schemes'),
            ),
            _NavItem(
              icon: Icons.smart_toy_rounded,
              label: s.get('ai_chat'),
              isSelected: currentIndex == 2,
              onTap: () => _navigate(context, '/ai-chat'),
            ),
            _NavItem(
              icon: Icons.mic_rounded,
              label: s.get('voice_assistant'),
              isSelected: currentIndex == 3,
              onTap: () => _navigate(context, '/voice-assistant'),
            ),
            _NavItem(
              icon: Icons.sell_rounded,
              label: s.get('price_estimator'),
              isSelected: currentIndex == 4,
              onTap: () => _navigate(context, '/price-estimator'),
            ),
            _NavItem(
              icon: Icons.store_rounded,
              label: s.get('business_boost'),
              isSelected: currentIndex == 5,
              onTap: () => _navigate(context, '/business-boost'),
            ),

            const Spacer(),

            _NavItem(
              icon: Icons.settings_rounded,
              label: s.get('settings'),
              isSelected: currentIndex == 6,
              onTap: () => _navigate(context, '/settings'),
            ),
            const SizedBox(height: 8),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: infoBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${s.get('app_name')} v1.0',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(
    BuildContext context,
    UserProfile profile,
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtitleColor,
  ) {
    final localeProvider = context.watch<LocaleProvider>();
    final isHindi = localeProvider.isHindi;

    final effectiveUrl = profile.effectivePhotoUrl;
    final hasPhoto = effectiveUrl != null && effectiveUrl.isNotEmpty;
    final isNetworkPhoto = hasPhoto && (effectiveUrl.startsWith('http://') || effectiveUrl.startsWith('https://'));
    final isLocalPhoto = hasPhoto && !isNetworkPhoto && File(effectiveUrl).existsSync();

    ImageProvider? photoProvider;
    if (isNetworkPhoto) {
      photoProvider = NetworkImage(effectiveUrl);
    } else if (isLocalPhoto) {
      photoProvider = FileImage(File(effectiveUrl));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: photoProvider == null ? LinearGradient(
                colors: [primaryColor, AppColors.secondary],
              ) : null,
              borderRadius: BorderRadius.circular(14),
              image: photoProvider != null
                  ? DecorationImage(
                      image: photoProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photoProvider != null
                ? null
                : Center(
                    child: Text(
                      profile.tradeIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name ?? (isHindi ? 'उपयोगकर्ता' : 'User'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  profile.getTradeDisplayName(hindi: isHindi),
                  style: TextStyle(color: subtitleColor, fontSize: 13),
                ),
                Text(
                  '${profile.location}, ${profile.state}',
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    HapticFeedback.selectionClick();
    Navigator.pop(context); // close drawer

    // From dashboard, push. From sub-screen, pop back to dashboard then push.
    if (route == '/dashboard' || route == '/') {
      // Going to dashboard — pop to root
      Navigator.popUntil(context, (r) => r.isFirst);
    } else {
      // Pop to root first, then push the new route
      Navigator.popUntil(context, (r) => r.isFirst);
      Navigator.pushNamed(context, route);
    }
  }
}

// ─── Nav item with Apple-style press highlight ──────────────────────────────

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF6AAFD4) : AppColors.primary;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _pressed
                ? primaryColor.withValues(alpha: 0.12)
                : widget.isSelected
                ? primaryColor.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: widget.isSelected ? primaryColor : secondaryTextColor,
                size: 22,
              ),
              const SizedBox(width: 14),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected ? primaryColor : textColor,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              if (widget.isSelected) ...[
                const Spacer(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
