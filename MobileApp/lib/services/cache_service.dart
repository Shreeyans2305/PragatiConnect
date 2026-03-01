import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for caching data locally for offline support
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _schemesKey = 'cached_schemes';
  static const String _schemesTimestampKey = 'cached_schemes_timestamp';
  static const String _chatHistoryKey = 'cached_chat_history';
  static const String _priceEstimatesKey = 'cached_price_estimates';

  // Cache expiry durations
  static const Duration schemesCacheExpiry = Duration(hours: 24);
  static const Duration chatHistoryExpiry = Duration(days: 7);

  // ─── Schemes Cache ────────────────────────────────────────────────────────

  /// Cache schemes list
  Future<void> cacheSchemes(List<Map<String, dynamic>> schemes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_schemesKey, json.encode(schemes));
      await prefs.setInt(
        _schemesTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error caching schemes: $e');
    }
  }

  /// Get cached schemes if not expired
  Future<List<Map<String, dynamic>>?> getCachedSchemes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_schemesTimestampKey);

      if (timestamp == null) return null;

      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cachedTime) > schemesCacheExpiry) {
        // Cache expired
        return null;
      }

      final schemesJson = prefs.getString(_schemesKey);
      if (schemesJson == null) return null;

      final decoded = json.decode(schemesJson) as List<dynamic>;
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error getting cached schemes: $e');
      return null;
    }
  }

  /// Check if schemes cache is valid
  Future<bool> hasValidSchemesCache() async {
    final schemes = await getCachedSchemes();
    return schemes != null && schemes.isNotEmpty;
  }

  // ─── Chat History Cache ───────────────────────────────────────────────────

  /// Cache conversation
  Future<void> cacheConversation(
    String conversationId,
    List<Map<String, dynamic>> messages,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing history
      final historyJson = prefs.getString(_chatHistoryKey);
      Map<String, dynamic> history = {};
      if (historyJson != null) {
        history = json.decode(historyJson) as Map<String, dynamic>;
      }

      // Keep only last 10 conversations
      if (history.length >= 10 && !history.containsKey(conversationId)) {
        // Remove oldest
        final sortedKeys = history.keys.toList()
          ..sort((a, b) {
            final aTime = (history[a] as Map)['timestamp'] as int? ?? 0;
            final bTime = (history[b] as Map)['timestamp'] as int? ?? 0;
            return aTime.compareTo(bTime);
          });
        history.remove(sortedKeys.first);
      }

      // Add/update conversation
      history[conversationId] = {
        'messages': messages,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(_chatHistoryKey, json.encode(history));
    } catch (e) {
      debugPrint('Error caching conversation: $e');
    }
  }

  /// Get cached conversation
  Future<List<Map<String, dynamic>>?> getCachedConversation(
    String conversationId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_chatHistoryKey);
      if (historyJson == null) return null;

      final history = json.decode(historyJson) as Map<String, dynamic>;
      final conversation = history[conversationId] as Map<String, dynamic>?;
      if (conversation == null) return null;

      final messages = conversation['messages'] as List<dynamic>;
      return messages.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error getting cached conversation: $e');
      return null;
    }
  }

  /// Get all cached conversation summaries
  Future<List<Map<String, dynamic>>> getCachedConversationSummaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_chatHistoryKey);
      if (historyJson == null) return [];

      final history = json.decode(historyJson) as Map<String, dynamic>;
      final summaries = <Map<String, dynamic>>[];

      for (final entry in history.entries) {
        final data = entry.value as Map<String, dynamic>;
        final messages = data['messages'] as List<dynamic>;
        if (messages.isNotEmpty) {
          final lastMessage = messages.last as Map<String, dynamic>;
          summaries.add({
            'conversation_id': entry.key,
            'last_message': lastMessage['content'] as String? ?? '',
            'message_count': messages.length,
            'timestamp': data['timestamp'],
          });
        }
      }

      // Sort by timestamp, newest first
      summaries.sort((a, b) {
        final aTime = a['timestamp'] as int? ?? 0;
        final bTime = b['timestamp'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });

      return summaries;
    } catch (e) {
      debugPrint('Error getting conversation summaries: $e');
      return [];
    }
  }

  // ─── Price Estimates Cache ────────────────────────────────────────────────

  /// Cache price estimate
  Future<void> cachePriceEstimate(Map<String, dynamic> estimate) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing estimates
      final estimatesJson = prefs.getString(_priceEstimatesKey);
      List<Map<String, dynamic>> estimates = [];
      if (estimatesJson != null) {
        final decoded = json.decode(estimatesJson) as List<dynamic>;
        estimates = decoded.map((e) => e as Map<String, dynamic>).toList();
      }

      // Keep only last 10 estimates
      if (estimates.length >= 10) {
        estimates.removeAt(0);
      }

      estimates.add({
        ...estimate,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      });

      await prefs.setString(_priceEstimatesKey, json.encode(estimates));
    } catch (e) {
      debugPrint('Error caching price estimate: $e');
    }
  }

  /// Get cached price estimates
  Future<List<Map<String, dynamic>>> getCachedPriceEstimates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final estimatesJson = prefs.getString(_priceEstimatesKey);
      if (estimatesJson == null) return [];

      final decoded = json.decode(estimatesJson) as List<dynamic>;
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error getting cached price estimates: $e');
      return [];
    }
  }

  // ─── Clear Cache ──────────────────────────────────────────────────────────

  /// Clear all cached data
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_schemesKey);
      await prefs.remove(_schemesTimestampKey);
      await prefs.remove(_chatHistoryKey);
      await prefs.remove(_priceEstimatesKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get cache size in bytes (approximate)
  Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int size = 0;

      final schemes = prefs.getString(_schemesKey);
      if (schemes != null) size += schemes.length;

      final history = prefs.getString(_chatHistoryKey);
      if (history != null) size += history.length;

      final estimates = prefs.getString(_priceEstimatesKey);
      if (estimates != null) size += estimates.length;

      return size;
    } catch (e) {
      return 0;
    }
  }
}
