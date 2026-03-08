import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/schemes_data_service.dart';
import '../l10n/app_strings.dart';

class SchemeDetailScreen extends StatefulWidget {
  final String schemeName;
  final Map<String, dynamic>? schemeData;

  const SchemeDetailScreen({
    super.key,
    required this.schemeName,
    this.schemeData,
  });

  @override
  State<SchemeDetailScreen> createState() => _SchemeDetailScreenState();
}

class _SchemeDetailScreenState extends State<SchemeDetailScreen> {
  final SchemesDataService _schemesDataService = SchemesDataService();
  Map<String, dynamic>? _scheme;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _scheme = widget.schemeData;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetails());
  }

  Future<void> _loadDetails() async {
    setState(() => _loading = true);
    final scheme = await _schemesDataService.getSchemeByName(widget.schemeName);
    if (!mounted) return;
    setState(() {
      _scheme = scheme ?? _scheme;
      _loading = false;
    });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final s = S.of(context);
    final textColor = isDark ? Colors.white : Colors.black;
    final category = (_scheme?['category'] as String?) ?? '';
    final schemeGradient = _categoryGradient(category);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.get('scheme_details')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              if (_scheme != null) {
                final content = '${_scheme!['name'] ?? ''}\n\n'
                    '${_scheme!['detailedDescription'] ?? ''}\n\n'
                    '${_scheme!['link'] ?? ''}';
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Details copied to clipboard!'),
                    backgroundColor: primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
          ),
        ],
      ),
        body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading details...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : _scheme == null
          ? Center(
              child: Text(
                'Scheme details not found',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDetails,
              color: primary,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scheme Name Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: schemeGradient,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _categoryIcon(category),
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            (_scheme!['name'] as String?) ?? widget.schemeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Markdown Content
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: MarkdownBody(
                        data: (_scheme!['detailedDescription'] as String?) ?? '',
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: textColor,
                          ),
                          h1: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                          h2: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                          h3: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          listBullet: TextStyle(fontSize: 15, color: textColor),
                          blockquote: TextStyle(fontSize: 14, color: primary),
                          code: TextStyle(
                            fontSize: 13,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.shade100,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
                          Text(
                            'Official Link',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            (_scheme!['link'] as String?) ?? '',
                            style: TextStyle(
                              color: primary,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
