/// Service d'import de balance CSV pour le module Dossier Fiscal.
///
/// Fonctionnalités :
/// - Détection automatique du séparateur (; ou ,)
/// - Normalisation des nombres (espaces, virgule décimale)
/// - Contrôle débit = crédit (±1 FCFA tolérance)
/// - Mapping colonnes tolérant
library;

import 'package:csv/csv.dart';

class CsvImportResult {
  final List<CsvBalanceLine> lines;
  final double totalDebit;
  final double totalCredit;
  final bool isBalanced;
  final double difference;
  final String? error;
  final String detectedSeparator;

  const CsvImportResult({
    required this.lines,
    required this.totalDebit,
    required this.totalCredit,
    required this.isBalanced,
    required this.difference,
    this.error,
    required this.detectedSeparator,
  });
}

class CsvBalanceLine {
  final String accountNumber;
  final String? accountLabel;
  final double debit;
  final double credit;
  final double? solde;

  const CsvBalanceLine({
    required this.accountNumber,
    this.accountLabel,
    required this.debit,
    required this.credit,
    this.solde,
  });

  Map<String, dynamic> toInsertMap() => {
        'account_number': accountNumber,
        'account_label': accountLabel,
        'debit': debit,
        'credit': credit,
        if (solde != null) 'solde': solde,
      };
}

class CsvImportService {
  /// Parse un fichier CSV de balance comptable.
  ///
  /// Colonnes attendues (tolérantes) :
  /// account_number / numero / compte, account_label / intitulé / libellé,
  /// debit / débit, credit / crédit, solde (optionnel).
  CsvImportResult parseBalance(String csvContent) {
    try {
      // 1) Détecter le séparateur
      final separator = _detectSeparator(csvContent);

      // 2) Parser le CSV
      final converter = CsvToListConverter(
        fieldDelimiter: separator,
        eol: '\n',
        shouldParseNumbers: false,
      );

      // Normaliser les fins de ligne
      final normalized = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      final rows = converter.convert(normalized);

      if (rows.isEmpty) {
        return const CsvImportResult(
          lines: [],
          totalDebit: 0,
          totalCredit: 0,
          isBalanced: true,
          difference: 0,
          error: 'Le fichier CSV est vide.',
          detectedSeparator: ',',
        );
      }

      // 3) Identifier les colonnes depuis l'en-tête
      final header = rows.first.map((e) => _normalizeHeader(e.toString())).toList();
      final colAccount = _findColumn(header, ['account_number', 'numero', 'compte', 'num_compte', 'n_compte', 'no_compte']);
      final colLabel = _findColumn(header, ['account_label', 'intitule', 'libelle', 'label', 'designation']);
      final colDebit = _findColumn(header, ['debit', 'debit_montant', 'total_debit', 'mouvement_debit']);
      final colCredit = _findColumn(header, ['credit', 'credit_montant', 'total_credit', 'mouvement_credit']);
      final colSolde = _findColumn(header, ['solde', 'solde_final', 'net']);

      if (colAccount == -1) {
        return CsvImportResult(
          lines: const [],
          totalDebit: 0,
          totalCredit: 0,
          isBalanced: true,
          difference: 0,
          error: 'Colonne "numéro de compte" non trouvée. Colonnes détectées : ${header.join(", ")}',
          detectedSeparator: separator,
        );
      }

      if (colDebit == -1 || colCredit == -1) {
        return CsvImportResult(
          lines: const [],
          totalDebit: 0,
          totalCredit: 0,
          isBalanced: true,
          difference: 0,
          error: 'Colonnes "débit" et/ou "crédit" non trouvées. Colonnes détectées : ${header.join(", ")}',
          detectedSeparator: separator,
        );
      }

      // 4) Parser les données (lignes 1+)
      final lines = <CsvBalanceLine>[];
      double totalDebit = 0;
      double totalCredit = 0;

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        final accountNumber = _cellStr(row, colAccount).trim();
        if (accountNumber.isEmpty) continue; // Ignorer les lignes sans numéro de compte

        final label = colLabel >= 0 ? _cellStr(row, colLabel).trim() : null;
        final debit = _parseNumber(_cellStr(row, colDebit));
        final credit = _parseNumber(_cellStr(row, colCredit));
        final solde = colSolde >= 0 ? _parseNumber(_cellStr(row, colSolde)) : null;

        lines.add(CsvBalanceLine(
          accountNumber: accountNumber,
          accountLabel: label,
          debit: debit,
          credit: credit,
          solde: solde,
        ));

        totalDebit += debit;
        totalCredit += credit;
      }

      final difference = (totalDebit - totalCredit).abs();
      final isBalanced = difference <= 1.0; // Tolérance ±1 FCFA

      return CsvImportResult(
        lines: lines,
        totalDebit: totalDebit,
        totalCredit: totalCredit,
        isBalanced: isBalanced,
        difference: difference,
        detectedSeparator: separator,
      );
    } catch (e) {
      return CsvImportResult(
        lines: const [],
        totalDebit: 0,
        totalCredit: 0,
        isBalanced: false,
        difference: 0,
        error: 'Erreur de parsing CSV : $e',
        detectedSeparator: ',',
      );
    }
  }

  /// Détecte le séparateur (si ; est plus fréquent que , → ;)
  String _detectSeparator(String content) {
    final firstLine = content.split('\n').first;
    final semicolons = ';'.allMatches(firstLine).length;
    final commas = ','.allMatches(firstLine).length;
    return semicolons > commas ? ';' : ',';
  }

  /// Normalise un en-tête (lowercase, sans accents, sans espaces)
  String _normalizeHeader(String s) {
    return s
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[\s_\-\.]+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  /// Recherche une colonne par noms possibles.
  int _findColumn(List<String> header, List<String> candidates) {
    for (int i = 0; i < header.length; i++) {
      for (final candidate in candidates) {
        if (header[i] == candidate || header[i].contains(candidate)) {
          return i;
        }
      }
    }
    return -1;
  }

  /// Extrait une cellule en tant que String.
  String _cellStr(List<dynamic> row, int index) {
    if (index >= row.length) return '';
    return row[index]?.toString() ?? '';
  }

  /// Parse un nombre depuis une chaîne (gère espaces, virgule décimale, etc.)
  double _parseNumber(String s) {
    if (s.trim().isEmpty) return 0;
    // Supprimer espaces (séparateur de milliers)
    String cleaned = s.replaceAll(RegExp(r'\s'), '');
    // Si la virgule est utilisée comme séparateur décimal
    // Heuristique : si un seul "," et aucun "." → virgule décimale
    if (cleaned.contains(',') && !cleaned.contains('.')) {
      cleaned = cleaned.replaceAll(',', '.');
    } else if (cleaned.contains(',') && cleaned.contains('.')) {
      // Format "1.234,56" → virgule est décimale
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(cleaned) ?? 0;
  }
}
