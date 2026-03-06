import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../l10n/app_strings.dart';
import '../providers/auth_provider.dart';
import '../services/gemini_service.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _loginPrompt = 'To use AI services kindly login';

  void _showLoginPromptDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text(_loginPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).pushNamed('/onboarding');
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  void _openProtectedFeature(String route) {
    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    if (!isAuthenticated) {
      HapticFeedback.mediumImpact();
      _showLoginPromptDialog();
      return;
    }
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.get('app_name')),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ),
        drawer: const AppDrawer(currentIndex: 0),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.screenHorizontal,
            vertical: AppPadding.screenVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _FadeSlideIn(
                delay: 0,
                child: Text(
                  s.get('welcome_back'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _FadeSlideIn(delay: 50, child: _HeroText(s: s)),
              const SizedBox(height: 28),

              // ─── Sliding Scheme Banner ─────────────────────
              _FadeSlideIn(delay: 150, child: const _SchemeBannerCarousel()),
              const SizedBox(height: 16),

              // AI Chatbot Card
              _FadeSlideIn(
                delay: 200,
                child: _PressableCard(
                  onTap: () => _openProtectedFeature('/ai-chat'),
                  child: _FeatureCardContent(
                    icon: Icons.smart_toy_rounded,
                    iconColor: Colors.deepPurple,
                    iconBgColor: isDark
                        ? Colors.deepPurple.withValues(alpha: 0.15)
                        : const Color(0xFFEDE7F6),
                    title: s.get('ai_chatbot'),
                    description: s.get('ai_chatbot_desc'),
                    isEnabled: isAuthenticated,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Voice Assistant Card
              _FadeSlideIn(
                delay: 250,
                child: _PressableCard(
                  onTap: () => _openProtectedFeature('/voice-assistant'),
                  child: _FeatureCardContent(
                    icon: Icons.mic_rounded,
                    iconColor: Colors.blue,
                    iconBgColor: isDark
                        ? Colors.blue.withValues(alpha: 0.15)
                        : const Color(0xFFE3F2FD),
                    title: s.get('voice_assistant'),
                    description: s.get('voice_assistant_desc'),
                    isEnabled: isAuthenticated,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Price Estimator Card
              _FadeSlideIn(
                delay: 300,
                child: _PressableCard(
                  onTap: () => _openProtectedFeature('/price-estimator'),
                  child: _FeatureCardContent(
                    icon: Icons.sell_rounded,
                    iconColor: Colors.green,
                    iconBgColor: isDark
                        ? Colors.green.withValues(alpha: 0.15)
                        : const Color(0xFFE8F5E9),
                    title: s.get('price_estimator'),
                    description: s.get('price_estimator_desc'),
                    isEnabled: isAuthenticated,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Business Boost Card
              _FadeSlideIn(
                delay: 350,
                child: _PressableCard(
                  onTap: () => _openProtectedFeature('/business-boost'),
                  child: _FeatureCardContent(
                    icon: Icons.store_rounded,
                    iconColor: AppColors.orange,
                    iconBgColor: isDark
                        ? AppColors.orange.withValues(alpha: 0.15)
                        : const Color(0xFFFEF3E7),
                    title: s.get('business_boost'),
                    description: s.get('business_boost_desc'),
                    isEnabled: isAuthenticated,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Impact Metrics Card
              _FadeSlideIn(delay: 450, child: _ImpactMetricsCard(s: s)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sliding Scheme Banner Carousel ──────────────────────────────────────────

class _SchemeBannerCarousel extends StatefulWidget {
  const _SchemeBannerCarousel();

  @override
  State<_SchemeBannerCarousel> createState() => _SchemeBannerCarouselState();
}

class _SchemeBannerCarouselState extends State<_SchemeBannerCarousel> {
  final GeminiService _gemini = GeminiService();
  late final PageController _pageController;
  List<Map<String, dynamic>> _schemes = [];
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSchemes());
  }

  Future<void> _loadSchemes() async {
    final lang = Localizations.localeOf(context).languageCode;
    final schemes = await _gemini.fetchGovernmentSchemes(language: lang);
    if (!mounted) return;
    setState(() {
      _schemes = schemes;
      _loading = false;
    });
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _schemes.isEmpty) return;
      _currentPage = (_currentPage + 1) % _schemes.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Agriculture':
        return Icons.agriculture_rounded;
      case 'Housing':
        return Icons.home_rounded;
      case 'Employment':
        return Icons.work_rounded;
      case 'Health':
        return Icons.health_and_safety_rounded;
      case 'Education':
        return Icons.school_rounded;
      case 'Business':
        return Icons.store_rounded;
      case 'Social Security':
        return Icons.shield_rounded;
      default:
        return Icons.policy_rounded;
    }
  }

  List<Color> _categoryGradient(String category) {
    switch (category) {
      case 'Agriculture':
        return [const Color(0xFF1B5E20), const Color(0xFF388E3C)];
      case 'Housing':
        return [const Color(0xFF0D47A1), const Color(0xFF1976D2)];
      case 'Employment':
        return [const Color(0xFFBF360C), const Color(0xFFE64A19)];
      case 'Health':
        return [const Color(0xFFB71C1C), const Color(0xFFD32F2F)];
      case 'Education':
        return [const Color(0xFF4A148C), const Color(0xFF7B1FA2)];
      case 'Business':
        return [const Color(0xFFE65100), const Color(0xFFF57C00)];
      case 'Social Security':
        return [const Color(0xFF004D40), const Color(0xFF00897B)];
      default:
        return [const Color(0xFF1A1A2E), const Color(0xFF2D1B69)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    if (_loading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF2D1B69)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_schemes.isEmpty) {
      return _PressableCard(
        onTap: () => Navigator.pushNamed(context, '/schemes'),
        child: _GovernmentSchemesContent(s: s),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _startAutoScroll();
            },
            itemCount: _schemes.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final scheme = _schemes[index];
              final category = scheme['category'] as String? ?? '';
              final gradient = _categoryGradient(category);
              final benefitText = scheme['benefitAmount'] as String? ?? '';
              final ministry = scheme['ministry'] as String? ?? '';

              // Apple-style scale + opacity for non-active cards
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double pageOffset = 0;
                  if (_pageController.position.haveDimensions) {
                    pageOffset = (_pageController.page ?? 0) - index;
                  }
                  final scale = (1 - pageOffset.abs() * 0.07).clamp(0.93, 1.0);
                  final opacity = (1 - pageOffset.abs() * 0.3).clamp(0.7, 1.0);

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(opacity: opacity, child: child),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(
                      context,
                      '/scheme-detail',
                      arguments: scheme['name'] as String,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.first.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          // Apple-style: smooth radial gradient overlay
                          gradient: RadialGradient(
                            center: const Alignment(-0.8, -0.6),
                            radius: 1.8,
                            colors: [
                              gradient.last.withValues(alpha: 0.95),
                              gradient.first,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Top row: icon + benefit pill + arrow
                            Row(
                              children: [
                                // Category icon
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _categoryIcon(category),
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Benefit pill — clear and readable
                                if (benefitText.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.22,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      benefitText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Scheme name
                            Text(
                              scheme['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                height: 1.2,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Description
                            Text(
                              scheme['description'] as String,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Ministry tag at the bottom
                            if (ministry.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                ministry,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_schemes.length.clamp(0, 8), (i) {
            final isActive = i == (_currentPage % _schemes.length.clamp(1, 8));
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Apple-style pressable card ──────────────────────────────────────────────

class _PressableCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _PressableCard({required this.onTap, required this.child});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─── Fade + slide-in stagger animation ──────────────────────────────────────

class _FadeSlideIn extends StatefulWidget {
  final int delay;
  final Widget child;

  const _FadeSlideIn({required this.delay, required this.child});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(position: _slideAnim, child: widget.child),
    );
  }
}

// ─── Hero text ───────────────────────────────────────────────────────────────

class _HeroText extends StatelessWidget {
  final AppStrings s;
  const _HeroText({required this.s});

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.headlineLarge!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.get('empowering'), style: baseStyle),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(s.get('informal_workforce'), style: baseStyle),
        ),
      ],
    );
  }
}

// ─── Government Schemes Card Content (fallback) ──────────────────────────────

class _GovernmentSchemesContent extends StatelessWidget {
  final AppStrings s;
  const _GovernmentSchemesContent({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppPadding.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF2D1B69), Color(0xFF1A1A3E)],
        ),
        borderRadius: BorderRadius.circular(AppPadding.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppPadding.iconContainerSize,
            height: AppPadding.iconContainerSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.get('government_schemes'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 24,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.get('government_schemes_desc'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature Card Content (dark-mode aware) ──────────────────────────────────

class _FeatureCardContent extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String description;
  final bool isEnabled;

  const _FeatureCardContent({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.description,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderClr = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;
    final chevronBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade100;
    final chevronClr = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : Colors.grey.shade600;

    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppPadding.cardPadding),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppPadding.cardRadius),
          border: Border.all(color: borderClr),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppPadding.iconContainerSize,
              height: AppPadding.iconContainerSize,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: chevronBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEnabled ? Icons.chevron_right_rounded : Icons.lock_rounded,
                  color: chevronClr,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Impact Metrics Card ─────────────────────────────────────────────────────

class _ImpactMetricsCard extends StatelessWidget {
  final AppStrings s;
  const _ImpactMetricsCard({required this.s});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderClr = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppPadding.cardPadding),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppPadding.cardRadius),
        border: Border.all(color: borderClr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.get('impact_metrics'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            s.get('impact_desc'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _CountUpMetric(
                  value: 20,
                  suffix: '%',
                  label: s.get('income_uplift'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CountUpMetric(
                  value: 50,
                  suffix: '%',
                  label: s.get('awareness'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Animated count-up metric ────────────────────────────────────────────────

class _CountUpMetric extends StatefulWidget {
  final int value;
  final String suffix;
  final String label;

  const _CountUpMetric({
    required this.value,
    required this.suffix,
    required this.label,
  });

  @override
  State<_CountUpMetric> createState() => _CountUpMetricState();
}

class _CountUpMetricState extends State<_CountUpMetric>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _anim,
          builder: (context, _) => Text(
            '${_anim.value.toInt()}${widget.suffix}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 36,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(widget.label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
