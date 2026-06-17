/// Mapping SYSCEBNL vers les cellules du classeur fiscal Excel.
///
/// Cette couche ne manipule pas encore le fichier .xlsx. Elle transforme une
/// balance comptable en valeurs et formules cibles, afin que la generation
/// Excel reste separee des regles comptables.
library;

import 'dart:math' as math;

class SyscebnlBalanceLine {
  const SyscebnlBalanceLine({
    required this.numero,
    required this.intitule,
    required this.nature,
    required this.totalDebit,
    required this.totalCredit,
  });

  final String numero;
  final String intitule;
  final String nature;
  final double totalDebit;
  final double totalCredit;

  double get soldeDebiteur => math.max(totalDebit - totalCredit, 0);
  double get soldeCrediteur => math.max(totalCredit - totalDebit, 0);
}

class FiscalExcelCellValue {
  const FiscalExcelCellValue({
    required this.sheet,
    required this.cell,
    required this.fieldKey,
    required this.label,
    required this.value,
  });

  final String sheet;
  final String cell;
  final String fieldKey;
  final String label;
  final double value;

  String get address => '$sheet!$cell';
}

class FiscalExcelFormula {
  const FiscalExcelFormula({
    required this.sheet,
    required this.cell,
    required this.formula,
    required this.label,
  });

  final String sheet;
  final String cell;
  final String formula;
  final String label;

  String get address => '$sheet!$cell';
}

class SyscebnlFiscalExcelMapping {
  const SyscebnlFiscalExcelMapping({
    required this.values,
    required this.formulas,
  });

  final List<FiscalExcelCellValue> values;
  final List<FiscalExcelFormula> formulas;

  double valueFor(String sheet, String cell) {
    return values
        .firstWhere(
          (entry) => entry.sheet == sheet && entry.cell == cell,
          orElse: () => FiscalExcelCellValue(
            sheet: sheet,
            cell: cell,
            fieldKey: '',
            label: '',
            value: 0,
          ),
        )
        .value;
  }

  String? formulaFor(String sheet, String cell) {
    for (final formula in formulas) {
      if (formula.sheet == sheet && formula.cell == cell) {
        return formula.formula;
      }
    }
    return null;
  }
}

class SyscebnlFiscalExcelMapper {
  const SyscebnlFiscalExcelMapper._();

  static SyscebnlFiscalExcelMapping fromBalance(
    List<SyscebnlBalanceLine> lines,
  ) {
    final values = <FiscalExcelCellValue>[
      // ACTIF - seules les cellules sources sont alimentees. Les totaux et
      // nets restent des formules du classeur.
      _value(
        'ACTIF',
        'D16',
        'excel.actif.terrains.brut',
        'Terrains',
        _debitBySelector(
          lines,
          const _AccountSelector(
            prefixes: ['21'],
            excludePrefixes: ['213', '214', '215', '216', '217', '218', '28'],
          ),
        ),
      ),
      _value(
        'ACTIF',
        'D18',
        'excel.actif.batiments.brut',
        'Batiments',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['213'])),
      ),
      _value(
        'ACTIF',
        'E18',
        'excel.actif.batiments.amortissements',
        'Amortissements batiments',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['2813'])),
      ),
      _value(
        'ACTIF',
        'D20',
        'excel.actif.amenagements.brut',
        'Amenagements, agencements et installations',
        _debitBySelector(
          lines,
          const _AccountSelector(prefixes: ['214', '215', '216', '217']),
        ),
      ),
      _value(
        'ACTIF',
        'D21',
        'excel.actif.materiel_mobilier.brut',
        'Materiel, mobilier et actifs assimilables',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['218'])),
      ),
      _value(
        'ACTIF',
        'E21',
        'excel.actif.materiel_mobilier.amortissements',
        'Amortissements materiel et mobilier',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['2818'])),
      ),
      _value(
        'ACTIF',
        'D29',
        'excel.actif.stocks.brut',
        'Stocks et en-cours',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['3'])),
      ),
      _value(
        'ACTIF',
        'D32',
        'excel.actif.creances_membres.brut',
        'Creances membres, adherents et tiers debiteurs',
        _debitBySelector(
          lines,
          const _AccountSelector(prefixes: ['4'], nature: 'actif'),
        ),
      ),
      _value(
        'ACTIF',
        'D37',
        'excel.actif.tresorerie.brut',
        'Banques, caisses, mobile money et assimiles',
        _debitBySelector(
          lines,
          const _AccountSelector(prefixes: ['5'], nature: 'actif'),
        ),
      ),

      // PASSIF - le resultat est injecte par formule depuis RESULTAT!E50.
      _value(
        'PASSIF',
        'D12',
        'excel.passif.fonds_associatifs',
        'Fonds associatifs, dotations et ressources durables',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['1'])),
      ),
      _value(
        'PASSIF',
        'D30',
        'excel.passif.fournisseurs',
        'Fournisseurs et comptes rattaches',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['40'])),
      ),
      _value(
        'PASSIF',
        'D31',
        'excel.passif.dettes_fiscales_sociales',
        'Dettes fiscales, sociales et assimilables',
        _creditBySelector(
          lines,
          const _AccountSelector(prefixes: ['42', '43', '44']),
        ),
      ),
      _value(
        'PASSIF',
        'D32',
        'excel.passif.autres_dettes',
        'Autres dettes et tiers crediteurs',
        _creditBySelector(
          lines,
          const _AccountSelector(prefixes: ['45', '46', '47', '48']),
        ),
      ),
      _value(
        'PASSIF',
        'D36',
        'excel.passif.tresorerie_passive',
        'Decouverts et tresorerie passive',
        _creditBySelector(
          lines,
          const _AccountSelector(prefixes: ['5'], nature: 'passif'),
        ),
      ),

      // RESULTAT - les produits d'eglise ne sont pas des ventes commerciales.
      // Ils alimentent la ligne source "Autres produits", puis les formules
      // du modele calculent les soldes intermediaires.
      _value(
        'RESULTAT',
        'E20',
        'excel.resultat.ressources_eglise',
        'Dimes, offrandes, dons, cotisations et autres produits',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['7'])),
      ),
      _value(
        'RESULTAT',
        'E26',
        'excel.resultat.transports',
        'Transports',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['624'])),
      ),
      _value(
        'RESULTAT',
        'E27',
        'excel.resultat.services_exterieurs',
        'Services exterieurs',
        _debitBySelector(
          lines,
          const _AccountSelector(
            prefixes: ['61', '62'],
            excludePrefixes: ['624'],
          ),
        ),
      ),
      _value(
        'RESULTAT',
        'E29',
        'excel.resultat.autres_charges',
        'Autres charges de gestion et aides',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['64', '65'])),
      ),
      _value(
        'RESULTAT',
        'E31',
        'excel.resultat.personnel',
        'Charges de personnel',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['66'])),
      ),
      _value(
        'RESULTAT',
        'E34',
        'excel.resultat.dotations',
        'Dotations aux amortissements et depreciations',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['68'])),
      ),
      _value(
        'RESULTAT',
        'E39',
        'excel.resultat.charges_financieres',
        'Frais financiers et charges assimilees',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['67'])),
      ),
      _value(
        'RESULTAT',
        'E44',
        'excel.resultat.produits_hao',
        'Produits hors activites ordinaires',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['8'])),
      ),
      _value(
        'RESULTAT',
        'E46',
        'excel.resultat.charges_hao',
        'Charges hors activites ordinaires',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['8'])),
      ),
    ];

    final formulas = <FiscalExcelFormula>[
      const FiscalExcelFormula(
        sheet: 'PASSIF',
        cell: 'D19',
        formula: '=RESULTAT!E50',
        label: 'Resultat net de l exercice',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H14',
        formula: '=RESULTAT!E50+RESULTAT!E34-RESULTAT!E33-RESULTAT!E37',
        label: 'Capacite d autofinancement globale SYSCEBNL',
      ),
    ];

    return SyscebnlFiscalExcelMapping(values: values, formulas: formulas);
  }

  static FiscalExcelCellValue _value(
    String sheet,
    String cell,
    String fieldKey,
    String label,
    double value,
  ) {
    return FiscalExcelCellValue(
      sheet: sheet,
      cell: cell,
      fieldKey: fieldKey,
      label: label,
      value: _round(value),
    );
  }

  static double _debitBySelector(
    List<SyscebnlBalanceLine> lines,
    _AccountSelector selector,
  ) {
    return lines
        .where(selector.matches)
        .fold<double>(0, (sum, line) => sum + line.soldeDebiteur);
  }

  static double _creditBySelector(
    List<SyscebnlBalanceLine> lines,
    _AccountSelector selector,
  ) {
    return lines
        .where(selector.matches)
        .fold<double>(0, (sum, line) => sum + line.soldeCrediteur);
  }

  static double _round(double value) => (value * 100).roundToDouble() / 100;
}

class _AccountSelector {
  const _AccountSelector({
    required this.prefixes,
    this.excludePrefixes = const [],
    this.nature,
  });

  final List<String> prefixes;
  final List<String> excludePrefixes;
  final String? nature;

  bool matches(SyscebnlBalanceLine line) {
    final numero = line.numero.trim();
    if (nature != null && line.nature != nature) return false;
    if (!prefixes.any(numero.startsWith)) return false;
    if (excludePrefixes.any(numero.startsWith)) return false;
    return true;
  }
}
