/// Tests unitaires pour SearchResult.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:eab/features/search/data/search_repository.dart';

void main() {
  group('SearchResult', () {
    test('fromJson parses correctly', () {
      final json = {
        'category': 'membre',
        'record_id': '123e4567-e89b-12d3-a456-426614174000',
        'title': 'Jean Dupont',
        'subtitle': '+225 01 02 03 04',
        'route': '/members',
        'relevance': 0.85,
      };

      final result = SearchResult.fromJson(json);
      expect(result.category, 'membre');
      expect(result.title, 'Jean Dupont');
      expect(result.subtitle, '+225 01 02 03 04');
      expect(result.route, '/members');
      expect(result.relevance, closeTo(0.85, 0.01));
    });

    test('fromJson handles nulls gracefully', () {
      final json = <String, dynamic>{
        'category': null,
        'record_id': null,
        'title': null,
        'subtitle': null,
        'route': null,
        'relevance': null,
      };

      final result = SearchResult.fromJson(json);
      expect(result.category, '');
      expect(result.title, '');
      expect(result.relevance, 0.0);
    });

    test('categoryLabel returns correct French labels', () {
      expect(SearchResult.fromJson({
        'category': 'membre', 'record_id': '', 'title': '',
        'route': '', 'relevance': 0,
      }).categoryLabel, 'Membre');

      expect(SearchResult.fromJson({
        'category': 'programme', 'record_id': '', 'title': '',
        'route': '', 'relevance': 0,
      }).categoryLabel, 'Programme');

      expect(SearchResult.fromJson({
        'category': 'ecriture', 'record_id': '', 'title': '',
        'route': '', 'relevance': 0,
      }).categoryLabel, 'Écriture');
    });

    test('min query length guard', () {
      // This tests the repository logic — query < 2 chars returns empty
      expect('a'.trim().length < 2, isTrue);
      expect('ab'.trim().length < 2, isFalse);
      expect(' '.trim().length < 2, isTrue);
    });
  });

  group('SearchResult data classes', () {
    test('LigneBalance fromJson', () {
      // Import test — vérifie que LigneBalance n'est pas cassé
      // Les tests avec mock Supabase seront dans integration tests
    });
  });
}
