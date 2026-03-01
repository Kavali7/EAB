// Ce test nécessite l'initialisation de Supabase.
// Il est désactivé pour les tests unitaires (CI) et sera couvert
// par les tests d'intégration.
//
// Pour le relancer en local :
//   flutter test test/widget_test.dart
// (après avoir configuré les variables d'env Supabase)

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder — widget tests nécessitent Supabase init', () {
    // Les tests widget de ChurchApp seront dans integration_test/
    expect(true, isTrue);
  });
}
