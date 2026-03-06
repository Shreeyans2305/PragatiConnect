import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../l10n/app_strings.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class PriceEstimatorScreen extends StatefulWidget {
  const PriceEstimatorScreen({super.key});

  @override
  State<PriceEstimatorScreen> createState() => _PriceEstimatorScreenState();
}

class _PriceEstimatorScreenState extends State<PriceEstimatorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  File? _selectedImage;
  bool _isAnalyzing = false;
  String? _analysisResult;
  int? _priceMin;
  int? _priceMax;
  String? _productCategory;
  int? _craftsmanshipScore;
  List<String> _pricingFactors = [];
  List<String> _sellingTips = [];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Listen to locale changes to rebuild when language changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final localeProvider = context.read<LocaleProvider>();
        localeProvider.addListener(_onLocaleChange);
      }
    });
  }

  void _onLocaleChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    
    // Remove locale change listener
    try {
      final localeProvider = context.read<LocaleProvider>();
      localeProvider.removeListener(_onLocaleChange);
    } catch (e) {
      // Ignore errors when context is no longer available
    }
    
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _analysisResult = null;
          _priceMin = null;
          _priceMax = null;
          _productCategory = null;
          _craftsmanshipScore = null;
          _pricingFactors = [];
          _sellingTips = [];
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to pick image: $e');
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isAnalyzing = true;
      _pulseController.repeat(reverse: true);
    });

    try {
      final authProvider = context.read<AuthProvider>();
      if (!authProvider.isAuthenticated || authProvider.accessToken == null) {
        if (mounted) {
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
        }
        return;
      }

      final apiService = ApiService();
      final localeProvider = context.read<LocaleProvider>();
      final langCode = localeProvider.languageCode;
      final result = await apiService.analyzeImage(
        authToken: authProvider.accessToken!,
        image: _selectedImage!,
        language: langCode,
      );

      final strings = AppStrings.of(context);

      if (!mounted) return;

      setState(() {
        // Map backend response fields to frontend state variables
        _analysisResult = result['craftsmanship_description'] ?? 'Analysis complete';
        _priceMin = result['price_min'] is num ? (result['price_min'] as num).toInt() : null;
        _priceMax = result['price_max'] is num ? (result['price_max'] as num).toInt() : null;
        _productCategory = result['product_category']?.toString();
        _craftsmanshipScore = result['craftsmanship_score'] is num
          ? (result['craftsmanship_score'] as num).toInt()
          : null;
        _pricingFactors = ((result['pricing_factors'] as List?) ?? [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
        _sellingTips = ((result['selling_tips'] as List?) ?? [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
        _isAnalyzing = false;
        _pulseController.stop();
      });
    } catch (e) {
      if (mounted) {
        _showError('Analysis failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _pulseController.stop();
        });
      }
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _resetForm() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedImage = null;
      _analysisResult = null;
      _priceMin = null;
      _priceMax = null;
      _productCategory = null;
      _craftsmanshipScore = null;
      _pricingFactors = [];
      _sellingTips = [];
      _isAnalyzing = false;
    });
    _pulseController.stop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.get('price_estimator')),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: strings.get('reset'),
              onPressed: _resetForm,
            ),
        ],
      ),
      drawer: const AppDrawer(currentIndex: 4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.screenHorizontal),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Header
            Text(
              strings.get('upload_product_image'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.get('upload_product_desc'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 24),

            // Image Selection / Preview Section
            if (_selectedImage == null)
              _ImagePickerSection(
                isDark: isDark,
                onCameraTap: () => _pickImage(ImageSource.camera),
                onGalleryTap: () => _pickImage(ImageSource.gallery),
                strings: strings,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Analyze Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _analyzeImage,
                      icon: _isAnalyzing
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(Icons.analytics_rounded),
                      label: Text(
                        _isAnalyzing ? strings.get('analyzing') : strings.get('analyze_estimate_price'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  // Analysis Results
                  if (_analysisResult != null) ...[
                    const SizedBox(height: 24),
                    _ResultCard(
                      isDark: isDark,
                      priceMin: _priceMin,
                      priceMax: _priceMax,
                      productCategory: _productCategory,
                      craftsmanshipScore: _craftsmanshipScore,
                      pricingFactors: _pricingFactors,
                      sellingTips: _sellingTips,
                      analysisResult: _analysisResult,
                      strings: strings,
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerSection extends StatelessWidget {
  final bool isDark;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final AppStrings strings;

  const _ImagePickerSection({
    required this.isDark,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Camera Option
        _PickerOption(
          icon: Icons.camera_alt_rounded,
          title: strings.get('take_photo'),
          subtitle: strings.get('capture_camera'),
          onTap: onCameraTap,
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // Gallery Option
        _PickerOption(
          icon: Icons.image_rounded,
          title: strings.get('choose_from_gallery'),
          subtitle: strings.get('select_device'),
          onTap: onGalleryTap,
          isDark: isDark,
        ),

        const SizedBox(height: 24),

        // Info Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.blue[400],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.get('best_results_hint'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[400],
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickerOption extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _PickerOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_PickerOption> createState() => _PickerOptionState();
}

class _PickerOptionState extends State<_PickerOption> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isPressed
              ? (widget.isDark
                  ? Colors.grey[700]
                  : Colors.grey[200])
              : (widget.isDark
                  ? Colors.grey[850]
                  : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.icon,
                color: Colors.orange[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.orange[600],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final bool isDark;
  final int? priceMin;
  final int? priceMax;
  final String? productCategory;
  final int? craftsmanshipScore;
  final List<String> pricingFactors;
  final List<String> sellingTips;
  final String? analysisResult;
  final AppStrings strings;

  const _ResultCard({
    required this.isDark,
    required this.priceMin,
    required this.priceMax,
    required this.productCategory,
    required this.craftsmanshipScore,
    required this.pricingFactors,
    required this.sellingTips,
    required this.analysisResult,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF1F1F22) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green[400]!.withValues(alpha: 0.16),
                Colors.teal[500]!.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.get('estimated_price_range'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.green[700],
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        strings.get('min_price'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green[700],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        priceMin != null ? '₹ $priceMin' : strings.get('na'),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.green.withValues(alpha: 0.2),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        strings.get('max_price'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green[700],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        priceMax != null ? '₹ $priceMax' : strings.get('na'),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Product summary tiles
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.category_rounded,
                label: strings.get('category'),
                value: productCategory ?? strings.get('na'),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.workspace_premium_rounded,
                label: strings.get('craftsmanship_score'),
                value: craftsmanshipScore != null
                    ? '$craftsmanshipScore/10'
                    : strings.get('na'),
                isDark: isDark,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _InsightCard(
          title: strings.get('pricing_factors'),
          icon: Icons.insights_rounded,
          points: pricingFactors,
          isDark: isDark,
          fallback: strings.get('na'),
        ),

        const SizedBox(height: 12),

        _InsightCard(
          title: strings.get('selling_tips'),
          icon: Icons.campaign_rounded,
          points: sellingTips,
          isDark: isDark,
          fallback: strings.get('na'),
        ),

        const SizedBox(height: 16),

        // Full Analysis
        if (analysisResult != null && analysisResult!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          strings.get('detailed_analysis'),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      analysisResult ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> points;
  final bool isDark;
  final String fallback;

  const _InsightCard({
    required this.title,
    required this.icon,
    required this.points,
    required this.isDark,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F22) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (points.isEmpty)
            Text(fallback, style: Theme.of(context).textTheme.bodyMedium)
          else
            ...points.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        point,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
