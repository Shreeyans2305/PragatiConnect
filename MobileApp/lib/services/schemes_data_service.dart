import 'dart:convert';

import 'package:flutter/services.dart';

class SchemesDataService {
  static const String _assetPath = 'indian_schemes_informal_workers_expanded.json';
  static List<Map<String, dynamic>>? _cache;

  Future<List<Map<String, dynamic>>> loadSchemes() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;

    _cache = decoded
        .whereType<Map<String, dynamic>>()
        .map(_normalizeScheme)
        .toList(growable: false);

    return _cache!;
  }

  Future<Map<String, dynamic>?> getSchemeByName(String name) async {
    final schemes = await loadSchemes();
    final lower = name.trim().toLowerCase();

    for (final scheme in schemes) {
      final schemeName = (scheme['name'] as String? ?? '').trim().toLowerCase();
      if (schemeName == lower) return scheme;
    }
    return null;
  }

  Map<String, dynamic> _normalizeScheme(Map<String, dynamic> source) {
    final title = (source['Title'] ?? '').toString().trim();
    final oneLine = (source['OneLineDescription'] ?? '').toString().trim();
    final detailed = (source['DetailedDescription'] ?? '').toString().trim();
    final tag = (source['Tag'] ?? '').toString().trim();
    final link = (source['Link'] ?? '').toString().trim();

    final category = _detectCategory('$title $oneLine $tag');

    return {
      'name': title,
      'description': oneLine,
      'detailedDescription': detailed,
      'benefitAmount': tag,
      'category': category,
      'link': link,
    };
  }

  String _detectCategory(String text) {
    final v = text.toLowerCase();
    if (v.contains('health') || v.contains('ayushman')) return 'Health';
    if (v.contains('skill') || v.contains('training') || v.contains('education')) {
      return 'Education';
    }
    if (v.contains('housing')) return 'Housing';
    if (v.contains('pension') || v.contains('insurance') || v.contains('social security')) {
      return 'Social Security';
    }
    if (v.contains('employment') || v.contains('livelihood')) return 'Employment';
    if (v.contains('farm') || v.contains('agri') || v.contains('kisan')) {
      return 'Agriculture';
    }
    if (v.contains('loan') || v.contains('credit') || v.contains('enterprise') || v.contains('vendor') || v.contains('msme') || v.contains('business')) {
      return 'Business';
    }
    return 'Social Security';
  }
}
