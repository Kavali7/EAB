import 'dart:convert';
import 'dart:math' as math;

import 'syscebnl_excel_mapping.dart';

class FiscalExportAdjustmentLine {
  const FiscalExportAdjustmentLine({
    required this.accountNumber,
    required this.accountLabel,
    this.nature,
    this.debitDelta = 0,
    this.creditDelta = 0,
  });

  final String accountNumber;
  final String accountLabel;
  final String? nature;
  final double debitDelta;
  final double creditDelta;

  Map<String, dynamic> toJson() => {
    'account_number': accountNumber,
    'account_label': accountLabel,
    if (nature != null && nature!.trim().isNotEmpty) 'nature': nature,
    'debit_delta': debitDelta,
    'credit_delta': creditDelta,
  };

  factory FiscalExportAdjustmentLine.fromJson(Map<String, dynamic> json) {
    return FiscalExportAdjustmentLine(
      accountNumber: _stringValue(json['account_number'] ?? json['numero']),
      accountLabel: _stringValue(json['account_label'] ?? json['intitule']),
      nature: _nullableString(json['nature']),
      debitDelta: _doubleValue(json['debit_delta']),
      creditDelta: _doubleValue(json['credit_delta']),
    );
  }
}

class FiscalExportAdjustment {
  const FiscalExportAdjustment({
    required this.id,
    required this.label,
    required this.reason,
    required this.lines,
    required this.createdAt,
  });

  final String id;
  final String label;
  final String reason;
  final List<FiscalExportAdjustmentLine> lines;
  final DateTime createdAt;

  factory FiscalExportAdjustment.balancedEntry({
    required String id,
    required String label,
    required String reason,
    required String debitAccountNumber,
    required String debitAccountLabel,
    required String creditAccountNumber,
    required String creditAccountLabel,
    required double amount,
  }) {
    return FiscalExportAdjustment(
      id: id,
      label: label,
      reason: reason,
      createdAt: DateTime.now().toUtc(),
      lines: [
        FiscalExportAdjustmentLine(
          accountNumber: debitAccountNumber,
          accountLabel: debitAccountLabel,
          debitDelta: amount,
        ),
        FiscalExportAdjustmentLine(
          accountNumber: creditAccountNumber,
          accountLabel: creditAccountLabel,
          creditDelta: amount,
        ),
      ],
    );
  }

  factory FiscalExportAdjustment.debitReclassification({
    required String id,
    required String label,
    required String reason,
    required String sourceAccountNumber,
    required String sourceAccountLabel,
    required String targetAccountNumber,
    required String targetAccountLabel,
    required double amount,
  }) {
    return FiscalExportAdjustment(
      id: id,
      label: label,
      reason: reason,
      createdAt: DateTime.now().toUtc(),
      lines: [
        FiscalExportAdjustmentLine(
          accountNumber: sourceAccountNumber,
          accountLabel: sourceAccountLabel,
          debitDelta: -amount,
        ),
        FiscalExportAdjustmentLine(
          accountNumber: targetAccountNumber,
          accountLabel: targetAccountLabel,
          debitDelta: amount,
        ),
      ],
    );
  }

  factory FiscalExportAdjustment.creditReclassification({
    required String id,
    required String label,
    required String reason,
    required String sourceAccountNumber,
    required String sourceAccountLabel,
    required String targetAccountNumber,
    required String targetAccountLabel,
    required double amount,
  }) {
    return FiscalExportAdjustment(
      id: id,
      label: label,
      reason: reason,
      createdAt: DateTime.now().toUtc(),
      lines: [
        FiscalExportAdjustmentLine(
          accountNumber: sourceAccountNumber,
          accountLabel: sourceAccountLabel,
          creditDelta: -amount,
        ),
        FiscalExportAdjustmentLine(
          accountNumber: targetAccountNumber,
          accountLabel: targetAccountLabel,
          creditDelta: amount,
        ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'reason': reason,
    'created_at': createdAt.toIso8601String(),
    'lines': lines.map((line) => line.toJson()).toList(growable: false),
  };

  factory FiscalExportAdjustment.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];
    return FiscalExportAdjustment(
      id: _stringValue(json['id']),
      label: _stringValue(json['label']),
      reason: _stringValue(json['reason']),
      createdAt:
          DateTime.tryParse(_stringValue(json['created_at'])) ??
          DateTime.now().toUtc(),
      lines: rawLines is List
          ? rawLines
                .whereType<Map>()
                .map(
                  (line) => FiscalExportAdjustmentLine.fromJson(
                    Map<String, dynamic>.from(line),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }
}

class FiscalExportAdjustmentCodec {
  const FiscalExportAdjustmentCodec._();

  static const fieldKey = 'export.adjustments';

  static List<FiscalExportAdjustment> decode(dynamic value) {
    if (value == null) return const [];
    dynamic normalized = value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return const [];
      normalized = jsonDecode(trimmed);
    }
    if (normalized is Map) {
      normalized = normalized['adjustments'] ?? normalized['items'] ?? const [];
    }
    if (normalized is! List) return const [];
    return normalized
        .whereType<Map>()
        .map(
          (entry) =>
              FiscalExportAdjustment.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> encode(
    List<FiscalExportAdjustment> adjustments,
  ) {
    return adjustments
        .map((adjustment) => adjustment.toJson())
        .toList(growable: false);
  }
}

class FiscalExportAdjustmentResult {
  const FiscalExportAdjustmentResult({
    required this.lines,
    required this.adjustmentCount,
    required this.adjustmentLineCount,
    required this.totalDebit,
    required this.totalCredit,
  });

  final List<SyscebnlBalanceLine> lines;
  final int adjustmentCount;
  final int adjustmentLineCount;
  final double totalDebit;
  final double totalCredit;
}

class FiscalExportAdjustmentEngine {
  const FiscalExportAdjustmentEngine._();

  static FiscalExportAdjustmentResult apply({
    required List<SyscebnlBalanceLine> balanceLines,
    required List<FiscalExportAdjustment> adjustments,
  }) {
    _validateAdjustments(adjustments);

    final byAccount = <String, SyscebnlBalanceLine>{};
    for (final line in balanceLines) {
      final account = line.numero.trim();
      if (account.isEmpty) continue;
      final existing = byAccount[account];
      byAccount[account] = existing == null
          ? line
          : _merge(existing, line.totalDebit, line.totalCredit, line.intitule);
    }

    for (final adjustment in adjustments) {
      for (final line in adjustment.lines) {
        final account = line.accountNumber.trim();
        final existing = byAccount[account];
        if (existing == null) {
          byAccount[account] = SyscebnlBalanceLine(
            numero: account,
            intitule: line.accountLabel.trim().isEmpty
                ? 'Ajustement export $account'
                : line.accountLabel.trim(),
            nature:
                line.nature ??
                _natureFromAccount(account, line.debitDelta, line.creditDelta),
            totalDebit: _round(line.debitDelta),
            totalCredit: _round(line.creditDelta),
          );
        } else {
          byAccount[account] = _merge(
            existing,
            line.debitDelta,
            line.creditDelta,
            line.accountLabel,
          );
        }
      }
    }

    final adjusted = byAccount.values.toList(growable: false)
      ..sort((a, b) => a.numero.compareTo(b.numero));
    for (final line in adjusted) {
      if (line.totalDebit < -_epsilon || line.totalCredit < -_epsilon) {
        throw StateError(
          'Ajustement export refuse : le compte ${line.numero} devient negatif.',
        );
      }
    }

    final totalDebit = _round(
      adjusted.fold<double>(0, (sum, line) => sum + line.totalDebit),
    );
    final totalCredit = _round(
      adjusted.fold<double>(0, (sum, line) => sum + line.totalCredit),
    );
    if (!_same(totalDebit, totalCredit)) {
      throw StateError(
        'Export refuse : la balance ajustee n est pas equilibree '
        '(debit $totalDebit, credit $totalCredit).',
      );
    }

    return FiscalExportAdjustmentResult(
      lines: adjusted,
      adjustmentCount: adjustments.length,
      adjustmentLineCount: adjustments.fold<int>(
        0,
        (sum, adjustment) => sum + adjustment.lines.length,
      ),
      totalDebit: totalDebit,
      totalCredit: totalCredit,
    );
  }

  static void validate(List<FiscalExportAdjustment> adjustments) {
    _validateAdjustments(adjustments);
  }

  static void _validateAdjustments(List<FiscalExportAdjustment> adjustments) {
    for (final adjustment in adjustments) {
      if (adjustment.label.trim().isEmpty) {
        throw StateError('Chaque ajustement doit avoir un libelle.');
      }
      if (adjustment.reason.trim().isEmpty) {
        throw StateError('Chaque ajustement doit avoir une justification.');
      }
      if (adjustment.lines.length < 2) {
        throw StateError(
          'Chaque ajustement doit contenir au moins deux lignes.',
        );
      }

      var debitDelta = 0.0;
      var creditDelta = 0.0;
      for (final line in adjustment.lines) {
        final account = line.accountNumber.trim();
        if (account.isEmpty || !RegExp(r'^\d+').hasMatch(account)) {
          throw StateError('Compte SYSCEBNL invalide dans un ajustement.');
        }
        final hasDebit = !_same(line.debitDelta, 0);
        final hasCredit = !_same(line.creditDelta, 0);
        if (hasDebit && hasCredit) {
          throw StateError(
            'Une ligne d ajustement ne peut pas modifier debit et credit en meme temps.',
          );
        }
        if (!hasDebit && !hasCredit) {
          throw StateError('Une ligne d ajustement ne peut pas etre nulle.');
        }
        debitDelta += line.debitDelta;
        creditDelta += line.creditDelta;
      }

      if (!_same(debitDelta, creditDelta)) {
        throw StateError(
          'Ajustement "${adjustment.label}" refuse : debit et credit ne '
          'restent pas equilibres.',
        );
      }
    }
  }

  static SyscebnlBalanceLine _merge(
    SyscebnlBalanceLine line,
    double debitDelta,
    double creditDelta,
    String fallbackLabel,
  ) {
    return SyscebnlBalanceLine(
      numero: line.numero,
      intitule: line.intitule.trim().isEmpty ? fallbackLabel : line.intitule,
      nature: line.nature,
      totalDebit: _round(line.totalDebit + debitDelta),
      totalCredit: _round(line.totalCredit + creditDelta),
    );
  }

  static String _natureFromAccount(
    String account,
    double debitDelta,
    double creditDelta,
  ) {
    if (account.startsWith('6')) return 'charge';
    if (account.startsWith('7')) return 'produit';
    if (account.startsWith('1')) return 'passif';
    if (account.startsWith('2') || account.startsWith('3')) return 'actif';
    if (account.startsWith('4') || account.startsWith('5')) {
      return debitDelta >= creditDelta ? 'actif' : 'passif';
    }
    if (account.startsWith('8')) {
      return debitDelta >= creditDelta ? 'charge' : 'produit';
    }
    return debitDelta >= creditDelta ? 'actif' : 'passif';
  }

  static double _round(double value) => (value * 100).roundToDouble() / 100;

  static bool _same(double a, double b) => (a - b).abs() <= _epsilon;
}

const _epsilon = 0.005;

String _stringValue(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

String? _nullableString(dynamic value) {
  final string = _stringValue(value);
  return string.isEmpty ? null : string;
}

double _doubleValue(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  final normalized = value.toString().replaceAll(' ', '').replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}

double fiscalExportAdjustmentAmountFromText(String value) {
  final normalized = value.replaceAll(' ', '').replaceAll(',', '.').trim();
  final amount = double.tryParse(normalized);
  if (amount == null || !amount.isFinite || amount <= 0) {
    throw StateError('Le montant de l ajustement doit etre positif.');
  }
  return (amount * math.pow(10, 2)).roundToDouble() / math.pow(10, 2);
}
