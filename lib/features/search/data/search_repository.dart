/// Repository pour la recherche globale (Ctrl+K).
library;

import 'package:eab/core/services/supabase_data_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Résultat de recherche globale.
class SearchResult {
  final String category; // 'membre', 'programme', 'ecriture'
  final String recordId;
  final String title;
  final String? subtitle;
  final String route;
  final double relevance;

  const SearchResult({
    required this.category,
    required this.recordId,
    required this.title,
    this.subtitle,
    required this.route,
    required this.relevance,
  });

  factory SearchResult.fromJson(Map<String, dynamic> j) => SearchResult(
        category: j['category'] ?? '',
        recordId: j['record_id'] ?? '',
        title: j['title'] ?? '',
        subtitle: j['subtitle'],
        route: j['route'] ?? '',
        relevance: (j['relevance'] as num?)?.toDouble() ?? 0,
      );

  /// Icône par catégorie.
  String get categoryLabel => switch (category) {
        'membre' => 'Membre',
        'programme' => 'Programme',
        'ecriture' => 'Écriture',
        _ => category,
      };
}

/// Repository de recherche globale.
class SearchRepository {
  const SearchRepository(this._dataService);
  final SupabaseDataService _dataService;

  SupabaseClient get _sb => _dataService.client;

  Future<List<SearchResult>> search(String orgId, String query,
      {int limit = 20}) async {
    if (query.trim().length < 2) return [];
    final data = await _sb.rpc('global_search', params: {
      'p_org_id': orgId,
      'p_query': query.trim(),
      'p_limit': limit,
    });
    return (data as List).map((e) => SearchResult.fromJson(e)).toList();
  }
}
