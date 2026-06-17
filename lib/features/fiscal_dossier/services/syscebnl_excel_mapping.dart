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
    final valuesByAddress = <String, FiscalExcelCellValue>{};
    void put(FiscalExcelCellValue value) {
      valuesByAddress[value.address] = value;
    }

    for (final value in _zeroSourceValues()) {
      put(value);
    }

    final mappedValues = <FiscalExcelCellValue>[
      // ACTIF - seules les cellules sources sont alimentees. Les totaux et
      // nets restent des formules du classeur.
      _value(
        'ACTIF',
        'D11',
        'excel.actif.incorporel.developpement.brut',
        'Frais de developpement et de prospection',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['201'])),
      ),
      _value(
        'ACTIF',
        'D12',
        'excel.actif.incorporel.logiciels.brut',
        'Logiciels, licences et droits similaires',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['205'])),
      ),
      _value(
        'ACTIF',
        'D14',
        'excel.actif.incorporel.autres.brut',
        'Autres immobilisations incorporelles',
        _debitBySelector(
          lines,
          const _AccountSelector(
            prefixes: ['20'],
            excludePrefixes: ['201', '205', '28'],
          ),
        ),
      ),
      _value(
        'ACTIF',
        'E11',
        'excel.actif.incorporel.developpement.amortissements',
        'Amortissements frais de developpement',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['2801'])),
      ),
      _value(
        'ACTIF',
        'E12',
        'excel.actif.incorporel.logiciels.amortissements',
        'Amortissements logiciels et droits similaires',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['2805'])),
      ),
      _value(
        'ACTIF',
        'E14',
        'excel.actif.incorporel.autres.amortissements',
        'Amortissements autres immobilisations incorporelles',
        _creditBySelector(
          lines,
          const _AccountSelector(
            prefixes: ['280'],
            excludePrefixes: ['2801', '2805'],
          ),
        ),
      ),
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
        'D22',
        'excel.actif.transport.brut',
        'Materiel de transport',
        _debitBySelector(
          lines,
          const _AccountSelector(prefixes: ['244', '245']),
        ),
      ),
      _value(
        'ACTIF',
        'E22',
        'excel.actif.transport.amortissements',
        'Amortissements materiel de transport',
        _creditBySelector(
          lines,
          const _AccountSelector(prefixes: ['2844', '2845', '28182']),
        ),
      ),
      _value(
        'ACTIF',
        'D23',
        'excel.actif.avances_immobilisations.brut',
        'Avances et acomptes sur immobilisations',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['238'])),
      ),
      _value(
        'ACTIF',
        'D25',
        'excel.actif.titres_participation.brut',
        'Titres de participation',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['26'])),
      ),
      _value(
        'ACTIF',
        'D26',
        'excel.actif.autres_immobilisations_financieres.brut',
        'Autres immobilisations financieres',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['27'])),
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
        'D31',
        'excel.actif.avances_fournisseurs.brut',
        'Fournisseurs avances versees',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['409'])),
      ),
      _value(
        'ACTIF',
        'D32',
        'excel.actif.creances_membres.brut',
        'Creances membres, adherents et tiers debiteurs',
        _debitBySelector(
          lines,
          const _AccountSelector(
            prefixes: ['4'],
            excludePrefixes: ['409', '45', '46', '47', '48'],
            nature: 'actif',
          ),
        ),
      ),
      _value(
        'ACTIF',
        'D33',
        'excel.actif.autres_creances.brut',
        'Autres creances',
        _debitBySelector(
          lines,
          const _AccountSelector(
            prefixes: ['45', '46', '47', '48'],
            nature: 'actif',
          ),
        ),
      ),
      _value(
        'ACTIF',
        'D35',
        'excel.actif.titres_placement.brut',
        'Titres de placement',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['50'])),
      ),
      _value(
        'ACTIF',
        'D36',
        'excel.actif.valeurs_encaisser.brut',
        'Valeurs a encaisser',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['51'])),
      ),
      _value(
        'ACTIF',
        'D37',
        'excel.actif.tresorerie.brut',
        'Banques, caisses, mobile money et assimiles',
        _debitBySelector(
          lines,
          const _AccountSelector(
            prefixes: ['5'],
            excludePrefixes: ['50', '51'],
            nature: 'actif',
          ),
        ),
      ),

      // PASSIF - le resultat est injecte par formule depuis RESULTAT!E50.
      _value(
        'PASSIF',
        'D12',
        'excel.passif.fonds_associatifs',
        'Fonds associatifs, dotations et ressources durables',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['10'])),
      ),
      _value(
        'PASSIF',
        'D16',
        'excel.passif.reserves_indisponibles',
        'Reserves indisponibles',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['106'])),
      ),
      _value(
        'PASSIF',
        'D17',
        'excel.passif.reserves_libres',
        'Reserves libres',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['11'])),
      ),
      _value(
        'PASSIF',
        'D18',
        'excel.passif.report_a_nouveau',
        'Report a nouveau',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['12'])),
      ),
      _value(
        'PASSIF',
        'D20',
        'excel.passif.subventions_investissement',
        'Subventions d investissement',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['14'])),
      ),
      _value(
        'PASSIF',
        'D21',
        'excel.passif.provisions_reglementees',
        'Provisions reglementees',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['15'])),
      ),
      _value(
        'PASSIF',
        'D23',
        'excel.passif.emprunts_dettes_financieres',
        'Emprunts et dettes financieres diverses',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['16'])),
      ),
      _value(
        'PASSIF',
        'D25',
        'excel.passif.provisions_risques_charges',
        'Provisions pour risques et charges',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['19'])),
      ),
      _value(
        'PASSIF',
        'D29',
        'excel.passif.avances_recues',
        'Avances recues',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['419'])),
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
        'E19',
        'excel.resultat.subventions_exploitation',
        'Subventions d exploitation',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['74'])),
      ),
      _value(
        'RESULTAT',
        'E20',
        'excel.resultat.ressources_eglise',
        'Dimes, offrandes, dons, cotisations et autres produits',
        _creditBySelector(
          lines,
          const _AccountSelector(
            prefixes: ['7'],
            excludePrefixes: ['74', '77', '78', '79'],
          ),
        ),
      ),
      _value(
        'RESULTAT',
        'E21',
        'excel.resultat.transferts_charges_exploitation',
        'Transferts de charges d exploitation',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['78'])),
      ),
      _value(
        'RESULTAT',
        'E22',
        'excel.resultat.achats_matieres',
        'Achats de matieres premieres et fournitures liees',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['601'])),
      ),
      _value(
        'RESULTAT',
        'E24',
        'excel.resultat.autres_achats',
        'Autres achats',
        _debitBySelector(
          lines,
          const _AccountSelector(prefixes: ['60'], excludePrefixes: ['601']),
        ),
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
        'E28',
        'excel.resultat.impots_taxes',
        'Impots et taxes',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['63'])),
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
        'E33',
        'excel.resultat.reprises_amortissements',
        'Reprises d amortissements, provisions et depreciations',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['79'])),
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
        'E36',
        'excel.resultat.revenus_financiers',
        'Revenus financiers et assimiles',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['77'])),
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
        'E40',
        'excel.resultat.dotations_financieres',
        'Dotations financieres',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['69'])),
      ),
      _value(
        'RESULTAT',
        'E43',
        'excel.resultat.produits_cessions_immobilisations',
        'Produits des cessions d immobilisations',
        _creditBySelector(lines, const _AccountSelector(prefixes: ['82'])),
      ),
      _value(
        'RESULTAT',
        'E44',
        'excel.resultat.produits_hao',
        'Produits hors activites ordinaires',
        _creditBySelector(
          lines,
          const _AccountSelector(prefixes: ['8'], excludePrefixes: ['82']),
        ),
      ),
      _value(
        'RESULTAT',
        'E45',
        'excel.resultat.valeurs_comptables_cessions',
        'Valeurs comptables des cessions d immobilisations',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['81'])),
      ),
      _value(
        'RESULTAT',
        'E46',
        'excel.resultat.charges_hao',
        'Charges hors activites ordinaires',
        _debitBySelector(
          lines,
          const _AccountSelector(prefixes: ['8'], excludePrefixes: ['81']),
        ),
      ),
      _value(
        'RESULTAT',
        'E49',
        'excel.resultat.impots_resultat',
        'Impots sur le resultat',
        _debitBySelector(lines, const _AccountSelector(prefixes: ['695'])),
      ),
    ];

    for (final value in mappedValues) {
      put(value);
    }
    final values = valuesByAddress.values.toList(growable: false);

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
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H19',
        formula: '=H15+H16+H17-H18',
        label: 'Variation du besoin de financement operationnel',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H20',
        formula: '=H14-H15-H16-H17+H18',
        label: 'Flux de tresorerie operationnels',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H27',
        formula: '=-H22-H23-H24+H25+H26',
        label: 'Flux d investissement',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H33',
        formula: '=H29+H30-H31-H32',
        label: 'Flux des capitaux propres',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H38',
        formula: '=H35+H36-H37',
        label: 'Flux des capitaux etrangers',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H39',
        formula: '=H33+H38',
        label: 'Flux de financement',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H40',
        formula: '=H20+H27+H39',
        label: 'Variation de tresorerie nette',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H41',
        formula: '=H11+H40',
        label: 'Tresorerie nette de cloture',
      ),
    ];

    return SyscebnlFiscalExcelMapping(values: values, formulas: formulas);
  }

  static Iterable<FiscalExcelCellValue> _zeroSourceValues() sync* {
    yield* _zeros('ACTIF', const [
      'D11',
      'E11',
      'G11',
      'D12',
      'E12',
      'G12',
      'D13',
      'E13',
      'G13',
      'D14',
      'E14',
      'G14',
      'D16',
      'E16',
      'G16',
      'D18',
      'E18',
      'G18',
      'D20',
      'E20',
      'G20',
      'D21',
      'E21',
      'G21',
      'D22',
      'E22',
      'G22',
      'D23',
      'E23',
      'G23',
      'D25',
      'E25',
      'G25',
      'D26',
      'E26',
      'G26',
      'D28',
      'E28',
      'G28',
      'D29',
      'E29',
      'G29',
      'D31',
      'E31',
      'G31',
      'D32',
      'E32',
      'G32',
      'D33',
      'E33',
      'G33',
      'D35',
      'E35',
      'G35',
      'D36',
      'E36',
      'G36',
      'D37',
      'E37',
      'G37',
      'D39',
      'E39',
      'G39',
    ]);
    yield* _zeros('PASSIF', const [
      'D12',
      'E12',
      'D13',
      'E13',
      'D14',
      'E14',
      'D15',
      'E15',
      'D16',
      'E16',
      'D17',
      'E17',
      'D18',
      'E18',
      'E19',
      'D20',
      'E20',
      'D21',
      'E21',
      'D23',
      'E23',
      'D24',
      'E24',
      'D25',
      'E25',
      'D28',
      'E28',
      'D29',
      'E29',
      'D30',
      'E30',
      'D31',
      'E31',
      'D32',
      'E32',
      'D33',
      'E33',
      'D35',
      'E35',
      'D36',
      'E36',
      'D38',
      'E38',
    ]);
    yield* _zeros('RESULTAT', const [
      'E9',
      'F9',
      'E10',
      'F10',
      'E11',
      'F11',
      'E13',
      'F13',
      'E14',
      'F14',
      'E15',
      'F15',
      'E17',
      'F17',
      'E18',
      'F18',
      'E19',
      'F19',
      'E20',
      'F20',
      'E21',
      'F21',
      'E22',
      'F22',
      'E23',
      'F23',
      'E24',
      'F24',
      'E25',
      'F25',
      'E26',
      'F26',
      'E27',
      'F27',
      'E28',
      'F28',
      'E29',
      'F29',
      'E31',
      'F31',
      'E33',
      'F33',
      'E34',
      'F34',
      'E36',
      'F36',
      'E37',
      'F37',
      'E38',
      'F38',
      'E39',
      'F39',
      'E40',
      'F40',
      'E43',
      'F43',
      'E44',
      'F44',
      'E45',
      'F45',
      'E46',
      'F46',
      'E48',
      'F48',
      'E49',
      'F49',
    ]);
    yield* _zeros('TFT', const [
      'H11',
      'I11',
      'I14',
      'H15',
      'I15',
      'H16',
      'I16',
      'H17',
      'I17',
      'H18',
      'I18',
      'I19',
      'I20',
      'H22',
      'I22',
      'H23',
      'I23',
      'H24',
      'I24',
      'H25',
      'I25',
      'H26',
      'I26',
      'I27',
      'H29',
      'I29',
      'H30',
      'I30',
      'H31',
      'I31',
      'H32',
      'I32',
      'I33',
      'H35',
      'I35',
      'H36',
      'I36',
      'H37',
      'I37',
      'I38',
      'I39',
      'I40',
      'I41',
    ]);
  }

  static Iterable<FiscalExcelCellValue> _zeros(
    String sheet,
    List<String> cells,
  ) sync* {
    for (final cell in cells) {
      yield _value(
        sheet,
        cell,
        'excel.${sheet.toLowerCase()}.$cell.zero',
        'Neutralisation valeur modele',
        0,
      );
    }
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
