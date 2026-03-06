import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../widgets/app_drawer.dart';
import '../services/gemini_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../config/environment.dart';
import '../l10n/app_strings.dart';

class BusinessBoostScreen extends StatefulWidget {
  const BusinessBoostScreen({super.key});

  @override
  State<BusinessBoostScreen> createState() => _BusinessBoostScreenState();
}

class _BusinessBoostScreenState extends State<BusinessBoostScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();
  final _gemini = GeminiService();
  final _apiService = ApiService();
  String? _generatedProfile;
  bool _isLoading = false;

  late AnimationController _resultController;
  late Animation<double> _resultFade;
  late Animation<Offset> _resultSlide;

  @override
  void initState() {
    super.initState();
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final localeProvider = context.read<LocaleProvider>();
        localeProvider.addListener(_onLocaleChange);
      }
    });
    _resultFade = CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOut,
    );
    _resultSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _resultController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  void _onLocaleChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _resultController.dispose();
    try {
      final localeProvider = context.read<LocaleProvider>();
      localeProvider.removeListener(_onLocaleChange);
    } catch (e) {}
    _nameController.dispose();
    _typeController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _generateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated || authProvider.accessToken == null) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('To use AI services kindly login'),
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
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
      _generatedProfile = null;
    });
    _resultController.reset();

    String result;
    
    // Get the user's preferred language
    final locale = Localizations.localeOf(context);
    final langCode = locale.languageCode;
    
    // Use backend API (Amazon Nova) when available
    if (Environment.useBackendApi) {
      result = await _generateWithBackend(langCode);
    } else {
      result = await _gemini.generateBusinessProfile(
        businessName: _nameController.text.trim(),
        businessType: _typeController.text.trim(),
        location: _locationController.text.trim(),
        description: _descController.text.trim(),
        language: langCode,
      );
    }

    HapticFeedback.lightImpact();
    setState(() {
      _generatedProfile = result;
      _isLoading = false;
    });
    _resultController.forward();
  }

  /// Generate business profile using backend API (Amazon Nova)
  Future<String> _generateWithBackend(String langCode) async {
    try {
      final authProvider = context.read<AuthProvider>();
      
      if (!authProvider.isAuthenticated) {
        debugPrint('💼 Business: Not authenticated');
        return 'Please login to continue.';
      }

      debugPrint('💼 Business: Using backend API with language: $langCode');
      
      final response = await _apiService.generateBusinessProfile(
        authToken: authProvider.accessToken!,
        businessDetails: {
          'business_name': _nameController.text.trim(),
          'trade': _typeController.text.trim(),
          'location': _locationController.text.trim(),
          'experience_years': 5, // Default
          'specialties': _descController.text.trim(),
        },
        language: langCode,
      );

      return response['content'] as String? ?? 'Could not generate profile.';
    } catch (e) {
      debugPrint('💼 Business: Backend error: $e, using Gemini fallback');
      // Fallback to Gemini
      return await _gemini.generateBusinessProfile(
        businessName: _nameController.text.trim(),
        businessType: _typeController.text.trim(),
        location: _locationController.text.trim(),
        description: _descController.text.trim(),
        language: langCode,
      );
    }
  }

  void _copyToClipboard() {
    if (_generatedProfile != null) {
      HapticFeedback.selectionClick();
      Clipboard.setData(ClipboardData(text: _generatedProfile!));
      final s = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.get('copied')),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderClr = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;
    final primary = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.get('business_boost')),
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
      drawer: const AppDrawer(currentIndex: 3),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppPadding.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(AppPadding.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.get('boost_your_business'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.get('boost_desc'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(s.get('business_name'), context),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: s.get('business_name_hint'),
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.grey.shade400,
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? s.get('required_field') : null,
                  ),
                  const SizedBox(height: 16),

                  _buildLabel(s.get('business_type'), context),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _typeController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: s.get('business_type_hint'),
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.grey.shade400,
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? s.get('required_field') : null,
                  ),
                  const SizedBox(height: 16),

                  _buildLabel(s.get('location'), context),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _locationController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: s.get('location_hint'),
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.grey.shade400,
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? s.get('required_field') : null,
                  ),
                  const SizedBox(height: 16),

                  _buildLabel(s.get('business_description'), context),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: s.get('business_description_hint'),
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.grey.shade400,
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? s.get('required_field') : null,
                  ),
                  const SizedBox(height: 24),

                  // Generate button with press effect
                  _GenerateButton(
                    isLoading: _isLoading,
                    onTap: _generateProfile,
                    strings: s,
                  ),
                ],
              ),
            ),

            // Generated Profile (animated in)
            if (_generatedProfile != null) ...[
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _resultFade,
                child: SlideTransition(
                  position: _resultSlide,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(
                        AppPadding.cardRadius,
                      ),
                      border: Border.all(color: borderClr),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.3 : 0.04,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primary.withValues(alpha: 0.14),
                                AppColors.secondary.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  color: primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.get('generated_profile'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_languageDisplayName(Localizations.localeOf(context).languageCode)} • AI',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              _CopyButton(onTap: _copyToClipboard),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: Icons.location_on_outlined,
                              text: _locationController.text.trim().isEmpty
                                  ? s.get('location')
                                  : _locationController.text.trim(),
                              isDark: isDark,
                            ),
                            _InfoChip(
                              icon: Icons.work_outline_rounded,
                              text: _typeController.text.trim(),
                              isDark: isDark,
                            ),
                            _InfoChip(
                              icon: Icons.translate_rounded,
                              text: _languageDisplayName(
                                Localizations.localeOf(context).languageCode,
                              ),
                              isDark: isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderClr),
                          ),
                          child: MarkdownBody(
                            data: _generatedProfile!,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: textColor,
                              ),
                              h1: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                              h2: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                              h3: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                              listBullet: TextStyle(
                                fontSize: 15,
                                color: textColor,
                              ),
                              blockquote: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _isLoading ? null : _generateProfile,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(s.get('generate_profile')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  String _languageDisplayName(String code) {
    switch (code) {
      case 'hi':
        return 'हिंदी';
      case 'mr':
        return 'मराठी';
      case 'bn':
        return 'বাংলা';
      case 'ta':
        return 'தமிழ்';
      case 'te':
        return 'తెలుగు';
      case 'gu':
        return 'ગુજરાતી';
      case 'pa':
        return 'ਪੰਜਾਬੀ';
      default:
        return 'English';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Generate Button with Apple spring ───────────────────────────────────────

class _GenerateButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;
  final AppStrings strings;

  const _GenerateButton({required this.isLoading, required this.onTap, required this.strings});

  @override
  State<_GenerateButton> createState() => _GenerateButtonState();
}

class _GenerateButtonState extends State<_GenerateButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTapDown: widget.isLoading
          ? null
          : (_) => _ctrl.animateTo(0.96, curve: Curves.easeOutCubic),
      onTapUp: widget.isLoading
          ? null
          : (_) {
              _ctrl.animateTo(1.0, curve: Curves.elasticOut);
              widget.onTap();
            },
      onTapCancel: () => _ctrl.animateTo(1.0, curve: Curves.elasticOut),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.isLoading ? primary.withValues(alpha: 0.6) : primary,
            borderRadius: BorderRadius.circular(AppPadding.smallRadius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              const SizedBox(width: 10),
              Text(
                widget.isLoading ? widget.strings.get('generating') : widget.strings.get('generate_profile'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Copy Button ─────────────────────────────────────────────────────────────

class _CopyButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CopyButton({required this.onTap});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTapDown: (_) => _ctrl.animateTo(0.85),
      onTapUp: (_) {
        _ctrl.animateTo(1.0, curve: Curves.elasticOut);
        widget.onTap();
        setState(() => _copied = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _copied = false);
        });
      },
      onTapCancel: () => _ctrl.animateTo(1.0),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _copied ? Icons.check_rounded : Icons.copy_rounded,
            key: ValueKey(_copied),
            size: 20,
            color: _copied ? Colors.green : primary,
          ),
        ),
      ),
    );
  }
}
