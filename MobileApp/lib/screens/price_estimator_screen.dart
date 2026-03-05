import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../l10n/app_strings.dart';
import '../providers/auth_provider.dart';
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
  String? _priceMin;
  String? _priceMax;
  String? _productDescription;
  String? _marketAnalysis;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
          _productDescription = null;
          _marketAnalysis = null;
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
          _showError('Please sign in to use price estimator');
        }
        return;
      }

      final apiService = ApiService();
      final result = await apiService.analyzeImage(
        authToken: authProvider.accessToken!,
        image: _selectedImage!,
        language: 'en',
      );

      if (!mounted) return;

      setState(() {
        // Map backend response fields to frontend state variables
        _analysisResult = result['craftsmanship_description'] ?? 'Analysis complete';
        _priceMin = result['price_min']?.toString() ?? 'N/A';
        _priceMax = result['price_max']?.toString() ?? 'N/A';
        _productDescription = 'Category: ${result['product_category'] ?? 'Unknown'}\n'
            'Craftsmanship Score: ${result['craftsmanship_score']}/10';
        _marketAnalysis = 'Pricing Factors: ${(result['pricing_factors'] as List?)?.join(", ") ?? 'N/A'}\n\n'
            'Selling Tips: ${(result['selling_tips'] as List?)?.join(", ") ?? 'N/A'}';
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
      _productDescription = null;
      _marketAnalysis = null;
      _isAnalyzing = false;
    });
    _pulseController.stop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Estimator'),
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
              tooltip: 'Reset',
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
              'Upload Product Image',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo or upload an image to get a fair price estimate',
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
                        _isAnalyzing ? 'Analyzing...' : 'Analyze & Estimate Price',
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
                      productDescription: _productDescription,
                      marketAnalysis: _marketAnalysis,
                      analysisResult: _analysisResult,
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

  const _ImagePickerSection({
    required this.isDark,
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Camera Option
        _PickerOption(
          icon: Icons.camera_alt_rounded,
          title: 'Take Photo',
          subtitle: 'Capture with your camera',
          onTap: onCameraTap,
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // Gallery Option
        _PickerOption(
          icon: Icons.image_rounded,
          title: 'Choose from Gallery',
          subtitle: 'Select from your device',
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
                  'For best results, upload clear photos of the product with good lighting. Supports: JPG, PNG, WebP, GIF, BMP, TIFF, SVG, HEIF.',
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
  final String? priceMin;
  final String? priceMax;
  final String? productDescription;
  final String? marketAnalysis;
  final String? analysisResult;

  const _ResultCard({
    required this.isDark,
    required this.priceMin,
    required this.priceMax,
    required this.productDescription,
    required this.marketAnalysis,
    required this.analysisResult,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price Range Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green[400]!.withValues(alpha: 0.15),
                Colors.green[600]!.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estimated Price Range',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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
                        'Min Price',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹ ${priceMin ?? 'N/A'}',
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
                        'Max Price',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹ ${priceMax ?? 'N/A'}',
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

        // Product Description
        if (productDescription != null && productDescription!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  productDescription ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

        // Market Analysis
        if (marketAnalysis != null && marketAnalysis!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Market Analysis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  marketAnalysis ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

        // Full Analysis
        if (analysisResult != null && analysisResult!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detailed Analysis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  analysisResult ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
