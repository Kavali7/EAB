/// Tests unitaires pour app_exceptions.dart
///
/// Vérifie que toAppException() traduit correctement les erreurs
/// Supabase/PG en messages utilisateur lisibles.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:eab/core/errors/app_exceptions.dart';

void main() {
  group('toAppException', () {
    test('erreur réseau → NetworkException', () {
      final e = toAppException(Exception('SocketException: Connection refused'));
      expect(e, isA<NetworkException>());
      expect(e.userMessage, contains('connexion'));
    });

    test('erreur timeout → NetworkException', () {
      final e = toAppException(Exception('TimeoutException after 30s'));
      expect(e, isA<NetworkException>());
    });

    test('RLS violation → PermissionException', () {
      final e = toAppException(
        Exception('PostgrestException: new row violates row-level security policy'),
      );
      expect(e, isA<PermissionException>());
      expect(e.userMessage, contains('droits'));
    });

    test('permission denied → PermissionException', () {
      final e = toAppException(Exception('permission denied for table membres'));
      expect(e, isA<PermissionException>());
    });

    test('RAISE EXCEPTION exercice → BusinessRuleException', () {
      final e = toAppException(
        Exception("PostgrestException(message: 'Seul un exercice en brouillon peut être ouvert')"),
      );
      expect(e, isA<BusinessRuleException>());
      expect(e.userMessage, contains('brouillon'));
    });

    test('RAISE EXCEPTION admin → BusinessRuleException', () {
      final e = toAppException(
        Exception("message: 'Seul l'administrateur national peut clôturer un exercice'"),
      );
      expect(e, isA<BusinessRuleException>());
      expect(e.userMessage, contains('administrateur national'));
    });

    test('duplicate key → BusinessRuleException doublon', () {
      final e = toAppException(
        Exception('duplicate key value violates unique constraint'),
      );
      expect(e, isA<BusinessRuleException>());
      expect(e.userMessage, contains('doublon'));
    });

    test('CHECK violation → BusinessRuleException validation', () {
      final e = toAppException(
        Exception('new row violates check constraint "chk_exercice_dates"'),
      );
      expect(e, isA<BusinessRuleException>());
      expect(e.userMessage, contains('validation'));
    });

    test('FK violation → BusinessRuleException utilisé ailleurs', () {
      final e = toAppException(
        Exception('violates foreign key constraint'),
      );
      expect(e, isA<BusinessRuleException>());
      expect(e.userMessage, contains('utilisé ailleurs'));
    });

    test('erreur inconnue → UnknownException', () {
      final e = toAppException(Exception('something random happened'));
      expect(e, isA<UnknownException>());
      expect(e.userMessage, contains('inattendue'));
    });

    test('les AppException passent directement', () {
      const original = BusinessRuleException('Test message');
      final e = toAppException(original);
      expect(e, isA<BusinessRuleException>());
      // toAppException retourne une nouvelle instance si l'input n'est pas AppException
      // mais le sealed class check devrait fonctionner
    });
  });

  group('AppException classes', () {
    test('toString retourne userMessage', () {
      const e = PermissionException();
      expect(e.toString(), equals(e.userMessage));
    });

    test('technicalDetail est optionnel', () {
      const e = NetworkException();
      expect(e.technicalDetail, isNull);

      final e2 = NetworkException('Custom message', 'detail');
      expect(e2.technicalDetail, equals('detail'));
    });
  });
}
