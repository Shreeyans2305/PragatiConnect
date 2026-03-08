import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../l10n/app_strings.dart';
import '../services/schemes_data_service.dart';
import 'scheme_detail_screen.dart';

class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  final SchemesDataService _schemesDataService = SchemesDataService();
  List<Map<String, dynamic>> _schemes = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSchemes());
  }

  Future<void> _loadSchemes() async {
    setState(() => _loading = true);

    final schemes = await _schemesDataService.loadSchemes();
    
    setState(() {
      _schemes = schemes;
      _filtered = schemes;
      _loading = false;
    });
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _schemes;
      } else {
        _filtered = _schemes.where((s) {
          final name = (s['name'] as String).toLowerCase();
          final desc = (s['description'] as String).toLowerCase();
          final cat = (s['category'] as String? ?? '').toLowerCase();
          final tag = (s['benefitAmount'] as String? ?? '').toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || desc.contains(q) || cat.contains(q) || tag.contains(q);
        }).toList();
      }
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

  Color _categoryColor(String category) {
    switch (category) {
      case 'Agriculture':
        return Colors.green;
      case 'Housing':
        return Colors.blue;
      case 'Employment':
        return Colors.orange;
      case 'Health':
        return Colors.red;
      case 'Education':
        return Colors.purple;
      case 'Business':
        return AppColors.orange;
      case 'Social Security':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.get('schemes')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: _onSearch,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: s.get('search_schemes'),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1C1C1E)
                    : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: primary),
                        const SizedBox(height: 16),
                        Text(
                          s.get('loading_schemes'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadSchemes,
                    color: primary,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final scheme = _filtered[index];
                        return _SchemeCard(
                          scheme: scheme,
                          icon: _categoryIcon(scheme['category'] ?? ''),
                          color: _categoryColor(scheme['category'] ?? ''),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SchemeDetailScreen(
                                  schemeName: scheme['name'] as String,
                                  schemeData: scheme,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Scheme Card ─────────────────────────────────────────────────────────────

class _SchemeCard extends StatefulWidget {
  final Map<String, dynamic> scheme;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SchemeCard({
    required this.scheme,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_SchemeCard> createState() => _SchemeCardState();
}

class _SchemeCardState extends State<_SchemeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderClr = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderClr),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.scheme['name'] as String,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.scheme['description'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.scheme['benefitAmount'] as String? ?? '',
                        style: TextStyle(
                          color: widget.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
