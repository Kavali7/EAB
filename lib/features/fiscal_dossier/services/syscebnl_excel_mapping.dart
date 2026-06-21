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

class FiscalManualReviewSheet {
  const FiscalManualReviewSheet({
    required this.sheet,
    required this.category,
    required this.reason,
    required this.requiredSource,
  });

  final String sheet;
  final String category;
  final String reason;
  final String requiredSource;
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

  static const automatedSheetNames = <String>[
    'ACTIF',
    'PASSIF',
    'RESULTAT',
    'TFT',
    'NOTE 3A',
    'NOTE 3C',
    'NOTE 4',
    'NOTE 6',
    'NOTE 7',
    'NOTE 8',
    'NOTE 9',
    'NOTE 10',
    'NOTE 11',
    'NOTE 12',
    'NOTE 14',
    'NOTE 15A',
    'NOTES 15B',
    'NOTE 16A',
    'NOTE 17',
    'NOTE 18',
    'NOTE 19',
    'NOTE 20',
    'NOTE 21',
    'NOTE 22',
    'NOTE 23',
    'NOTE 24',
    'NOTE 25',
    'NOTE 26',
    'NOTE 27A',
    'NOTE 28',
    'NOTE 29',
    'NOTE 30',
    'NOTE 31',
    'NOTE 34',
  ];

  static const manualReviewSheetNames = <String>[
    'NOTE 1',
    'NOTE 2',
    'NOTE 3B',
    'NOTE 3D',
    'NOTE 3E',
    'NOTE 5',
    'NOTE 8A',
    'NOTE 13',
    'NOTE 16B',
    'NOTE 16B bis',
    'NOTE 16C',
    'NOTE 27B',
    'NOTE 32',
    'NOTE 33',
    'NOTE 35',
    'NOTE 36',
    'FICHE R1',
    'FICHE R2',
    'FICHE R3',
    'FICHE R4',
  ];

  static const manualReviewSheets = <FiscalManualReviewSheet>[
    FiscalManualReviewSheet(
      sheet: 'NOTE 1',
      category: 'engagements',
      reason:
          'Dettes garanties par suretes reelles sans source comptable '
          'suffisante dans la balance.',
      requiredSource: 'registre des garanties, nantissements et cautions',
    ),
    FiscalManualReviewSheet(
      sheet: 'NOTE 2',
      category: 'methodes',
      reason: 'Declarations de conformite et methodes comptables qualitatives.',
      requiredSource: 'parametres des methodes comptables de l organisation',
    ),
    FiscalManualReviewSheet(
      sheet: 'NOTE 3B',
      category: 'immobilisations',
      reason:
          'Biens pris en location-acquisition non deduisibles de la '
          'balance seule.',
      requiredSource: 'module contrats de location-acquisition',
    ),
    FiscalManualReviewSheet(
      sheet: 'NOTE 3D',
      category: 'immobilisations',
      reason:
          'Plus-values et moins-values de cession necessitent le detail '
          'des sorties d immobilisations.',
      requiredSource: 'module immobilisations avec cessions',
    ),
    FiscalManualReviewSheet(
      sheet: 'NOTE 3E',
      category: 'immobilisations',
      reason:
          'Reevaluations et traitements fiscaux associes non presents '
          'dans les ecritures courantes.',
      requiredSource: 'registre des reevaluations',
    ),
    FiscalManualReviewSheet(
      sheet: 'NOTE 5',
      category: 'actif circulant',
      reason:
          'Actif circulant HAO et commentaires de variation a valider '
          'hors balance generale.',
      requiredSource: 'registre HAO et justification des variations',
    ),
    FiscalManualReviewSheet(
      sheet: 'NOTE 8A',
      category: 'charges etalees',
      reason:
          'Tableau d etalement des charges immobilisees exige un '
          'echeancier dedie.',
      requiredSource: 'module charges a etaler',
    ),
    FiscalManualReviewSheet(
      sheet: 'NOTE 13',
      category: 'fonds associatifs',
      reason:
          'Detail des apporteurs et mouvements de fonds associatifs '
          'non fiable depuis la balance seule.',
      requiredSource: 'registre des apporteurs et decisions statutaires',
    ),
    FiscalManualReviewSheet(
      sheet: 'NOTE 16B',
      category: 'engagements sociaux',
      reason: 'Hypotheses actuarielles et engagements de retraite.',
      requiredSource: 'module RH ou evaluation actuarielle',
    ),
    FiscalManualReviewSheet(
      sheet: 'NOTE 16B bis',
      category: 'engagements sociaux',
      reason: 'Actifs affectes aux regimes finances et rendements attendus.',
      requiredSource: 'module RH ou evaluation actuarielle',
    ),
    FiscalManualReviewSheet(
      sheet: 'NOTE 16C',
      category: 'risques',
      reason: 'Actifs et passifs eventuels exigent une revue juridique.',
      requiredSource: 'registre des litiges et engagements eventuels',
    ),
    FiscalManualReviewSheet(
      sheet: 'NOTE 27B',
      category: 'ressources humaines',
      reason:
          'Effectifs, masse salariale et personnel exterieur ne peuvent '
          'pas etre controles depuis la seule comptabilite.',
      requiredSource: 'module RH et paie',
    ),
    FiscalManualReviewSheet(
      sheet: 'NOTE 32',
      category: 'production',
      reason:
          'Production de l exercice en quantites et valeurs, non '
          'applicable ou non disponible sans module operationnel.',
      requiredSource: 'module production ou parametrage non applicable',
    ),
    FiscalManualReviewSheet(
      sheet: 'NOTE 33',
      category: 'production',
      reason:
          'Achats destines a la production et variations de stocks par '
          'quantites.',
      requiredSource: 'module achats/stocks ou parametrage non applicable',
    ),
    FiscalManualReviewSheet(
      sheet: 'NOTE 35',
      category: 'informations sociales',
      reason:
          'Informations sociales, environnementales et communautaires '
          'qualitatives.',
      requiredSource: 'rapport social et communautaire',
    ),
    FiscalManualReviewSheet(
      sheet: 'NOTE 36',
      category: 'codes fiscaux',
      reason:
          'Codes de forme juridique, regime fiscal et pays a confirmer '
          'avec les parametres officiels.',
      requiredSource: 'parametres fiscaux avances',
    ),
    FiscalManualReviewSheet(
      sheet: 'FICHE R1',
      category: 'identite fiscale',
      reason:
          'Fiche administrative pre-remplie partiellement mais signature '
          'et codes officiels a verifier.',
      requiredSource: 'parametres fiscaux avances et signataire',
    ),
    FiscalManualReviewSheet(
      sheet: 'FICHE R2',
      category: 'activite',
      reason:
          'Activite, forme juridique, regime fiscal et controle a '
          'confirmer.',
      requiredSource: 'parametres fiscaux avances',
    ),
    FiscalManualReviewSheet(
      sheet: 'FICHE R3',
      category: 'gouvernance',
      reason:
          'Dirigeants pre-remplis partiellement, conseil d administration '
          'a renseigner si applicable.',
      requiredSource: 'module gouvernance et dirigeants',
    ),
    FiscalManualReviewSheet(
      sheet: 'FICHE R4',
      category: 'controle dossier',
      reason:
          'Tableau de presence des notes a verifier selon les feuilles '
          'applicables.',
      requiredSource: 'matrice d applicabilite des notes fiscales',
    ),
  ];

  static SyscebnlFiscalExcelMapping fromBalance(
    List<SyscebnlBalanceLine> lines, {
    List<SyscebnlBalanceLine> previousLines = const [],
  }) {
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
        'E20',
        'excel.actif.amenagements.amortissements',
        'Amortissements amenagements, agencements et installations',
        _creditBySelector(
          lines,
          const _AccountSelector(prefixes: ['2814', '2815', '2816', '2817']),
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
        _debitBySelector(lines, const _AccountSelector(prefixes: ['511'])),
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
            excludePrefixes: ['50', '511'],
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
    for (final value in _comparativeValues(lines, previousLines)) {
      put(value);
    }
    for (final value in _annexValues(lines, previousLines)) {
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
        sheet: 'PASSIF',
        cell: 'E19',
        formula: '=RESULTAT!F50',
        label: 'Resultat net de l exercice precedent',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H14',
        formula: '=RESULTAT!E50+RESULTAT!E34-RESULTAT!E33-RESULTAT!E37',
        label: 'Capacite d autofinancement globale SYSCEBNL',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'I14',
        formula: '=RESULTAT!F50+RESULTAT!F34-RESULTAT!F33-RESULTAT!F37',
        label: 'Capacite d autofinancement globale SYSCEBNL N-1',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H19',
        formula: '=H15+H16+H17-H18',
        label: 'Variation du besoin de financement operationnel',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'I19',
        formula: '=I15+I16+I17-I18',
        label: 'Variation du besoin de financement operationnel N-1',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H20',
        formula: '=H14-H15-H16-H17+H18',
        label: 'Flux de tresorerie operationnels',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'I20',
        formula: '=I14-I15-I16-I17+I18',
        label: 'Flux de tresorerie operationnels N-1',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H27',
        formula: '=-H22-H23-H24+H25+H26',
        label: 'Flux d investissement',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'I27',
        formula: '=-I22-I23-I24+I25+I26',
        label: 'Flux d investissement N-1',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H33',
        formula: '=H29+H30-H31-H32',
        label: 'Flux des capitaux propres',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'I33',
        formula: '=I29+I30-I31-I32',
        label: 'Flux des capitaux propres N-1',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H38',
        formula: '=H35+H36-H37',
        label: 'Flux des capitaux etrangers',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'I38',
        formula: '=I35+I36-I37',
        label: 'Flux des capitaux etrangers N-1',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H39',
        formula: '=H33+H38',
        label: 'Flux de financement',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'I39',
        formula: '=I33+I38',
        label: 'Flux de financement N-1',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H40',
        formula: '=H20+H27+H39',
        label: 'Variation de tresorerie nette',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'I40',
        formula: '=I20+I27+I39',
        label: 'Variation de tresorerie nette N-1',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'H41',
        formula: '=H11+H40',
        label: 'Tresorerie nette de cloture',
      ),
      const FiscalExcelFormula(
        sheet: 'TFT',
        cell: 'I41',
        formula: '=I11+I40',
        label: 'Tresorerie nette de cloture N-1',
      ),
      ..._annexFormulas(),
    ];

    return SyscebnlFiscalExcelMapping(values: values, formulas: formulas);
  }

  static Iterable<FiscalExcelCellValue> _annexValues(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _note3aGrossAssets(lines, previousLines);
    yield* _note3cDepreciation(lines, previousLines);
    yield* _note4FinancialAssets(lines, previousLines);
    yield* _note6Inventories(lines, previousLines);
    yield* _note7MemberReceivables(lines, previousLines);
    yield* _note8OtherReceivables(lines, previousLines);
    yield* _note9InvestmentSecurities(lines, previousLines);
    yield* _note10ReceivableValues(lines, previousLines);
    yield* _note11CashAndBank(lines, previousLines);
    yield* _note12ExpenseTransfers(lines, previousLines);
    yield* _note14ReservesAndRetainedEarnings(lines, previousLines);
    yield* _note15aSubventionsAndRegulatedProvisions(lines, previousLines);
    yield* _note15bOtherOwnFunds(lines, previousLines);
    yield* _note16aFinancialDebts(lines, previousLines);
    yield* _note17SupplierDebts(lines, previousLines);
    yield* _note18TaxAndSocialDebts(lines, previousLines);
    yield* _note19OtherDebts(lines, previousLines);
    yield* _note20TreasuryPassive(lines, previousLines);
    yield* _note21Revenues(lines, previousLines);
    yield* _note22Purchases(lines, previousLines);
    yield* _note23Transports(lines, previousLines);
    yield* _note24ExternalServices(lines, previousLines);
    yield* _note25Taxes(lines, previousLines);
    yield* _note26OtherCharges(lines, previousLines);
    yield* _note27aStaffCosts(lines, previousLines);
    yield* _note28ProvisionsAndDepreciations(lines, previousLines);
    yield* _note29FinancialIncomeAndCharges(lines, previousLines);
    yield* _note30HaoIncomeAndCharges(lines, previousLines);
  }

  static Iterable<FiscalExcelFormula> _annexFormulas() sync* {
    yield* const [
      FiscalExcelFormula(
        sheet: 'NOTE 3A',
        cell: 'H15',
        formula: '=SUM(H16:H19)',
        label: 'Total immobilisations incorporelles brutes',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 3A',
        cell: 'H20',
        formula: '=SUM(H21:H27)',
        label: 'Total immobilisations corporelles brutes',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 3A',
        cell: 'H28',
        formula: '=SUM(H29:H30)',
        label: 'Total avances sur immobilisations',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 3A',
        cell: 'H31',
        formula: '=SUM(H32:H33)',
        label: 'Total immobilisations financieres',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 3A',
        cell: 'H34',
        formula: '=H15+H20+H28+H31',
        label: 'Total general immobilisations brutes',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 3C',
        cell: 'E15',
        formula: '=B15+C15-D15',
        label: 'Amortissements frais de developpement',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 3C',
        cell: 'E16',
        formula: '=B16+C16-D16',
        label: 'Amortissements logiciels',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 3C',
        cell: 'E18',
        formula: '=B18+C18-D18',
        label: 'Autres amortissements incorporels',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 3C',
        cell: 'E19',
        formula: '=SUM(E15:E18)',
        label: 'Total amortissements incorporels',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 3C',
        cell: 'E22',
        formula: '=B22+C22-D22',
        label: 'Amortissements batiments',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 3C',
        cell: 'E24',
        formula: '=B24+C24-D24',
        label: 'Amortissements amenagements',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 3C',
        cell: 'E25',
        formula: '=B25+C25-D25',
        label: 'Amortissements materiel et mobilier',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 3C',
        cell: 'E26',
        formula: '=B26+C26-D26',
        label: 'Amortissements materiel de transport',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 3C',
        cell: 'E27',
        formula: '=SUM(E20:E26)',
        label: 'Total amortissements corporels',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 3C',
        cell: 'E29',
        formula: '=E19+E27',
        label: 'Total general amortissements',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 21',
        cell: 'B38',
        formula: '=SUM(B35:B37)',
        label: 'Total autres produits',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 21',
        cell: 'C38',
        formula: '=SUM(C35:C37)',
        label: 'Total autres produits N-1',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 19',
        cell: 'B24',
        formula: '=SUM(B17:B23)',
        label: 'Total crediteurs divers',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 19',
        cell: 'C24',
        formula: '=SUM(C17:C23)',
        label: 'Total crediteurs divers N-1',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 15A',
        cell: 'C18',
        formula: '=SUM(C10:C17)',
        label: 'Total subventions d investissement',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 15A',
        cell: 'D18',
        formula: '=SUM(D10:D17)',
        label: 'Total subventions d investissement N-1',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 15A',
        cell: 'C27',
        formula: '=SUM(C20:C26)',
        label: 'Total provisions reglementees',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 15A',
        cell: 'D27',
        formula: '=SUM(D20:D26)',
        label: 'Total provisions reglementees N-1',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 15A',
        cell: 'C29',
        formula: '=C18+C27',
        label: 'Total subventions et provisions reglementees',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 15A',
        cell: 'D29',
        formula: '=D18+D27',
        label: 'Total subventions et provisions reglementees N-1',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 28',
        cell: 'I12',
        formula: '=B12+C12+D12+E12-F12-G12-H12',
        label: 'Solde final provisions reglementees',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 28',
        cell: 'I13',
        formula: '=B13+C13+D13+E13-F13-G13-H13',
        label: 'Solde final provisions pour risques et charges',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 31',
        cell: 'B18',
        formula: "='NOTE 21'!B40",
        label: 'Ressources ordinaires exercice courant',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 31',
        cell: 'C18',
        formula: "='NOTE 21'!C40",
        label: 'Ressources ordinaires exercice precedent',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 31',
        cell: 'B19',
        formula: '=RESULTAT!E35+RESULTAT!E34',
        label: 'Resultat ordinaire hors dotations',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 31',
        cell: 'C19',
        formula: '=RESULTAT!F35+RESULTAT!F34',
        label: 'Resultat ordinaire hors dotations N-1',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 31',
        cell: 'B21',
        formula: '=RESULTAT!E49',
        label: 'Impots sur le resultat',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 31',
        cell: 'C21',
        formula: '=RESULTAT!F49',
        label: 'Impots sur le resultat N-1',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 31',
        cell: 'B22',
        formula: '=RESULTAT!E50',
        label: 'Resultat net',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 31',
        cell: 'C22',
        formula: '=RESULTAT!F50',
        label: 'Resultat net N-1',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 31',
        cell: 'B29',
        formula: "='NOTE 27A'!B11+'NOTE 27A'!B12",
        label: 'Masse salariale distribuee',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 31',
        cell: 'C29',
        formula: "='NOTE 27A'!C11+'NOTE 27A'!C12",
        label: 'Masse salariale distribuee N-1',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 31',
        cell: 'B30',
        formula: "='NOTE 27A'!B13+'NOTE 27A'!B16",
        label: 'Avantages sociaux',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 31',
        cell: 'C30',
        formula: "='NOTE 27A'!C13+'NOTE 27A'!C16",
        label: 'Avantages sociaux N-1',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 31',
        cell: 'B31',
        formula: "='NOTE 27A'!B15",
        label: 'Personnel exterieur facture',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 31',
        cell: 'C31',
        formula: "='NOTE 27A'!C15",
        label: 'Personnel exterieur facture N-1',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 34',
        cell: 'C10',
        formula: "='NOTE 21'!B40",
        label: 'Ressources ordinaires exercice courant',
      ),
      FiscalExcelFormula(
        sheet: 'NOTE 34',
        cell: 'D10',
        formula: "='NOTE 21'!C40",
        label: 'Ressources ordinaires exercice precedent',
      ),
    ];
  }

  static Iterable<FiscalExcelCellValue> _comparativeValues(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    if (previousLines.isEmpty) return;

    yield _value(
      'ACTIF',
      'G11',
      'excel.n1.actif.incorporel.developpement.net',
      'Frais de developpement et de prospection N-1',
      _netBySelectors(
        previousLines,
        const _AccountSelector(prefixes: ['201']),
        const _AccountSelector(prefixes: ['2801']),
      ),
    );
    yield _value(
      'ACTIF',
      'G12',
      'excel.n1.actif.incorporel.logiciels.net',
      'Logiciels, licences et droits similaires N-1',
      _netBySelectors(
        previousLines,
        const _AccountSelector(prefixes: ['205']),
        const _AccountSelector(prefixes: ['2805']),
      ),
    );
    yield _value(
      'ACTIF',
      'G14',
      'excel.n1.actif.incorporel.autres.net',
      'Autres immobilisations incorporelles N-1',
      _netBySelectors(
        previousLines,
        const _AccountSelector(
          prefixes: ['20'],
          excludePrefixes: ['201', '205', '28'],
        ),
        const _AccountSelector(
          prefixes: ['280'],
          excludePrefixes: ['2801', '2805'],
        ),
      ),
    );
    yield _value(
      'ACTIF',
      'G16',
      'excel.n1.actif.terrains.net',
      'Terrains N-1',
      _debitBySelector(
        previousLines,
        const _AccountSelector(
          prefixes: ['21'],
          excludePrefixes: ['213', '214', '215', '216', '217', '218', '28'],
        ),
      ),
    );
    yield _value(
      'ACTIF',
      'G18',
      'excel.n1.actif.batiments.net',
      'Batiments N-1',
      _netBySelectors(
        previousLines,
        const _AccountSelector(prefixes: ['213']),
        const _AccountSelector(prefixes: ['2813']),
      ),
    );
    yield _value(
      'ACTIF',
      'G20',
      'excel.n1.actif.amenagements.net',
      'Amenagements, agencements et installations N-1',
      _netBySelectors(
        previousLines,
        const _AccountSelector(prefixes: ['214', '215', '216', '217']),
        const _AccountSelector(prefixes: ['2814', '2815', '2816', '2817']),
      ),
    );
    yield _value(
      'ACTIF',
      'G21',
      'excel.n1.actif.materiel_mobilier.net',
      'Materiel, mobilier et actifs assimilables N-1',
      _netBySelectors(
        previousLines,
        const _AccountSelector(prefixes: ['218']),
        const _AccountSelector(prefixes: ['2818']),
      ),
    );
    yield _value(
      'ACTIF',
      'G22',
      'excel.n1.actif.transport.net',
      'Materiel de transport N-1',
      _netBySelectors(
        previousLines,
        const _AccountSelector(prefixes: ['244', '245']),
        const _AccountSelector(prefixes: ['2844', '2845', '28182']),
      ),
    );
    yield _value(
      'ACTIF',
      'G23',
      'excel.n1.actif.avances_immobilisations.net',
      'Avances et acomptes sur immobilisations N-1',
      _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['238']),
      ),
    );
    yield _value(
      'ACTIF',
      'G25',
      'excel.n1.actif.titres_participation.net',
      'Titres de participation N-1',
      _debitBySelector(previousLines, const _AccountSelector(prefixes: ['26'])),
    );
    yield _value(
      'ACTIF',
      'G26',
      'excel.n1.actif.autres_immobilisations_financieres.net',
      'Autres immobilisations financieres N-1',
      _debitBySelector(previousLines, const _AccountSelector(prefixes: ['27'])),
    );
    yield _value(
      'ACTIF',
      'G29',
      'excel.n1.actif.stocks.net',
      'Stocks et en-cours N-1',
      _stockValue(previousLines),
    );
    yield _value(
      'ACTIF',
      'G31',
      'excel.n1.actif.avances_fournisseurs.net',
      'Fournisseurs avances versees N-1',
      _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['409']),
      ),
    );
    yield _value(
      'ACTIF',
      'G32',
      'excel.n1.actif.creances_membres.net',
      'Creances membres, adherents et tiers debiteurs N-1',
      _debitBySelector(
        previousLines,
        const _AccountSelector(
          prefixes: ['4'],
          excludePrefixes: ['409', '45', '46', '47', '48'],
          nature: 'actif',
        ),
      ),
    );
    yield _value(
      'ACTIF',
      'G33',
      'excel.n1.actif.autres_creances.net',
      'Autres creances N-1',
      _otherReceivables(previousLines),
    );
    yield _value(
      'ACTIF',
      'G35',
      'excel.n1.actif.titres_placement.net',
      'Titres de placement N-1',
      _debitBySelector(previousLines, const _AccountSelector(prefixes: ['50'])),
    );
    yield _value(
      'ACTIF',
      'G36',
      'excel.n1.actif.valeurs_encaisser.net',
      'Valeurs a encaisser N-1',
      _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['511']),
      ),
    );
    yield _value(
      'ACTIF',
      'G37',
      'excel.n1.actif.tresorerie.net',
      'Banques, caisses, mobile money et assimiles N-1',
      _treasuryActive(previousLines),
    );

    yield _value(
      'PASSIF',
      'E12',
      'excel.n1.passif.fonds_associatifs',
      'Fonds associatifs, dotations et ressources durables N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['10']),
      ),
    );
    yield _value(
      'PASSIF',
      'E16',
      'excel.n1.passif.reserves_indisponibles',
      'Reserves indisponibles N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['106']),
      ),
    );
    yield _value(
      'PASSIF',
      'E17',
      'excel.n1.passif.reserves_libres',
      'Reserves libres N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['11']),
      ),
    );
    yield _value(
      'PASSIF',
      'E18',
      'excel.n1.passif.report_a_nouveau',
      'Report a nouveau N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['12']),
      ),
    );
    yield _value(
      'PASSIF',
      'E20',
      'excel.n1.passif.subventions_investissement',
      'Subventions d investissement N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['14']),
      ),
    );
    yield _value(
      'PASSIF',
      'E21',
      'excel.n1.passif.provisions_reglementees',
      'Provisions reglementees N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['15']),
      ),
    );
    yield _value(
      'PASSIF',
      'E23',
      'excel.n1.passif.emprunts_dettes_financieres',
      'Emprunts et dettes financieres diverses N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['16']),
      ),
    );
    yield _value(
      'PASSIF',
      'E25',
      'excel.n1.passif.provisions_risques_charges',
      'Provisions pour risques et charges N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['19']),
      ),
    );
    yield _value(
      'PASSIF',
      'E29',
      'excel.n1.passif.avances_recues',
      'Avances recues N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['419']),
      ),
    );
    yield _value(
      'PASSIF',
      'E30',
      'excel.n1.passif.fournisseurs',
      'Fournisseurs et comptes rattaches N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['40']),
      ),
    );
    yield _value(
      'PASSIF',
      'E31',
      'excel.n1.passif.dettes_fiscales_sociales',
      'Dettes fiscales, sociales et assimilables N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['42', '43', '44']),
      ),
    );
    yield _value(
      'PASSIF',
      'E32',
      'excel.n1.passif.autres_dettes',
      'Autres dettes et tiers crediteurs N-1',
      _otherDebts(previousLines),
    );
    yield _value(
      'PASSIF',
      'E36',
      'excel.n1.passif.tresorerie_passive',
      'Decouverts et tresorerie passive N-1',
      _treasuryPassive(previousLines),
    );

    yield _value(
      'RESULTAT',
      'F19',
      'excel.n1.resultat.subventions_exploitation',
      'Subventions d exploitation N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['74']),
      ),
    );
    yield _value(
      'RESULTAT',
      'F20',
      'excel.n1.resultat.ressources_eglise',
      'Dimes, offrandes, dons, cotisations et autres produits N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(
          prefixes: ['7'],
          excludePrefixes: ['74', '77', '78', '79'],
        ),
      ),
    );
    yield _value(
      'RESULTAT',
      'F21',
      'excel.n1.resultat.transferts_charges_exploitation',
      'Transferts de charges d exploitation N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['78']),
      ),
    );
    yield _value(
      'RESULTAT',
      'F22',
      'excel.n1.resultat.achats_matieres',
      'Achats de matieres premieres et fournitures liees N-1',
      _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['601']),
      ),
    );
    yield _value(
      'RESULTAT',
      'F24',
      'excel.n1.resultat.autres_achats',
      'Autres achats N-1',
      _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['60'], excludePrefixes: ['601']),
      ),
    );
    yield _value(
      'RESULTAT',
      'F26',
      'excel.n1.resultat.transports',
      'Transports N-1',
      _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['624']),
      ),
    );
    yield _value(
      'RESULTAT',
      'F27',
      'excel.n1.resultat.services_exterieurs',
      'Services exterieurs N-1',
      _debitBySelector(
        previousLines,
        const _AccountSelector(
          prefixes: ['61', '62'],
          excludePrefixes: ['624'],
        ),
      ),
    );
    yield _value(
      'RESULTAT',
      'F28',
      'excel.n1.resultat.impots_taxes',
      'Impots et taxes N-1',
      _debitBySelector(previousLines, const _AccountSelector(prefixes: ['63'])),
    );
    yield _value(
      'RESULTAT',
      'F29',
      'excel.n1.resultat.autres_charges',
      'Autres charges de gestion et aides N-1',
      _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['64', '65']),
      ),
    );
    yield _value(
      'RESULTAT',
      'F31',
      'excel.n1.resultat.personnel',
      'Charges de personnel N-1',
      _debitBySelector(previousLines, const _AccountSelector(prefixes: ['66'])),
    );
    yield _value(
      'RESULTAT',
      'F33',
      'excel.n1.resultat.reprises_amortissements',
      'Reprises d amortissements, provisions et depreciations N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['79']),
      ),
    );
    yield _value(
      'RESULTAT',
      'F34',
      'excel.n1.resultat.dotations',
      'Dotations aux amortissements et depreciations N-1',
      _debitBySelector(previousLines, const _AccountSelector(prefixes: ['68'])),
    );
    yield _value(
      'RESULTAT',
      'F36',
      'excel.n1.resultat.revenus_financiers',
      'Revenus financiers et assimiles N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['77']),
      ),
    );
    yield _value(
      'RESULTAT',
      'F39',
      'excel.n1.resultat.charges_financieres',
      'Frais financiers et charges assimilees N-1',
      _debitBySelector(previousLines, const _AccountSelector(prefixes: ['67'])),
    );
    yield _value(
      'RESULTAT',
      'F40',
      'excel.n1.resultat.dotations_financieres',
      'Dotations financieres N-1',
      _debitBySelector(previousLines, const _AccountSelector(prefixes: ['69'])),
    );
    yield _value(
      'RESULTAT',
      'F43',
      'excel.n1.resultat.produits_cessions_immobilisations',
      'Produits des cessions d immobilisations N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['82']),
      ),
    );
    yield _value(
      'RESULTAT',
      'F44',
      'excel.n1.resultat.produits_hao',
      'Produits hors activites ordinaires N-1',
      _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['8'], excludePrefixes: ['82']),
      ),
    );
    yield _value(
      'RESULTAT',
      'F45',
      'excel.n1.resultat.valeurs_comptables_cessions',
      'Valeurs comptables des cessions d immobilisations N-1',
      _debitBySelector(previousLines, const _AccountSelector(prefixes: ['81'])),
    );
    yield _value(
      'RESULTAT',
      'F46',
      'excel.n1.resultat.charges_hao',
      'Charges hors activites ordinaires N-1',
      _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['8'], excludePrefixes: ['81']),
      ),
    );
    yield _value(
      'RESULTAT',
      'F49',
      'excel.n1.resultat.impots_resultat',
      'Impots sur le resultat N-1',
      _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['695']),
      ),
    );

    yield _value(
      'TFT',
      'H11',
      'excel.tft.tresorerie_ouverture',
      'Tresorerie nette au 1er janvier',
      _treasuryNet(previousLines),
    );
    yield _value(
      'TFT',
      'H16',
      'excel.tft.variation_stocks',
      'Variation des stocks',
      _stockValue(lines) - _stockValue(previousLines),
    );
    yield _value(
      'TFT',
      'H17',
      'excel.tft.variation_creances',
      'Variation des creances',
      _receivablesValue(lines) - _receivablesValue(previousLines),
    );
    yield _value(
      'TFT',
      'H18',
      'excel.tft.variation_passif_circulant',
      'Variation du passif circulant',
      _currentLiabilities(lines) - _currentLiabilities(previousLines),
    );
  }

  static Iterable<FiscalExcelCellValue> _note3aGrossAssets(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _note3aGrossRow(
      lines,
      previousLines,
      row: '16',
      fieldKey: 'developpement',
      label: 'Frais de developpement et de prospection',
      selector: const _AccountSelector(prefixes: ['201']),
    );
    yield* _note3aGrossRow(
      lines,
      previousLines,
      row: '17',
      fieldKey: 'logiciels',
      label: 'Logiciels, licences et droits similaires',
      selector: const _AccountSelector(prefixes: ['205']),
    );
    yield* _note3aGrossRow(
      lines,
      previousLines,
      row: '19',
      fieldKey: 'autres_incorporelles',
      label: 'Autres immobilisations incorporelles',
      selector: const _AccountSelector(
        prefixes: ['20'],
        excludePrefixes: ['201', '205', '28'],
      ),
    );
    yield* _note3aGrossRow(
      lines,
      previousLines,
      row: '21',
      fieldKey: 'terrains',
      label: 'Terrains',
      selector: const _AccountSelector(
        prefixes: ['21'],
        excludePrefixes: ['213', '214', '215', '216', '217', '218', '28'],
      ),
    );
    yield* _note3aGrossRow(
      lines,
      previousLines,
      row: '23',
      fieldKey: 'batiments',
      label: 'Batiments',
      selector: const _AccountSelector(prefixes: ['213']),
    );
    yield* _note3aGrossRow(
      lines,
      previousLines,
      row: '25',
      fieldKey: 'amenagements',
      label: 'Amenagements, agencements et installations',
      selector: const _AccountSelector(prefixes: ['214', '215', '216', '217']),
    );
    yield* _note3aGrossRow(
      lines,
      previousLines,
      row: '26',
      fieldKey: 'materiel_mobilier',
      label: 'Materiel, mobilier et actifs assimilables',
      selector: const _AccountSelector(prefixes: ['218']),
    );
    yield* _note3aGrossRow(
      lines,
      previousLines,
      row: '27',
      fieldKey: 'transport',
      label: 'Materiel de transport',
      selector: const _AccountSelector(prefixes: ['244', '245']),
    );
    yield* _note3aGrossRow(
      lines,
      previousLines,
      row: '30',
      fieldKey: 'avances_corporelles',
      label: 'Avances et acomptes sur immobilisations corporelles',
      selector: const _AccountSelector(prefixes: ['238']),
    );
    yield* _note3aGrossRow(
      lines,
      previousLines,
      row: '32',
      fieldKey: 'titres_participation',
      label: 'Titres de participation',
      selector: const _AccountSelector(prefixes: ['26']),
    );
    yield* _note3aGrossRow(
      lines,
      previousLines,
      row: '33',
      fieldKey: 'autres_financieres',
      label: 'Autres immobilisations financieres',
      selector: const _AccountSelector(prefixes: ['27']),
    );
  }

  static Iterable<FiscalExcelCellValue> _note3cDepreciation(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _note3cAmortizationRow(
      lines,
      previousLines,
      row: '15',
      fieldKey: 'developpement',
      label: 'Amortissements frais de developpement',
      selector: const _AccountSelector(prefixes: ['2801']),
    );
    yield* _note3cAmortizationRow(
      lines,
      previousLines,
      row: '16',
      fieldKey: 'logiciels',
      label: 'Amortissements logiciels',
      selector: const _AccountSelector(prefixes: ['2805']),
    );
    yield* _note3cAmortizationRow(
      lines,
      previousLines,
      row: '18',
      fieldKey: 'autres_incorporelles',
      label: 'Autres amortissements incorporels',
      selector: const _AccountSelector(
        prefixes: ['280'],
        excludePrefixes: ['2801', '2805'],
      ),
    );
    yield* _note3cAmortizationRow(
      lines,
      previousLines,
      row: '22',
      fieldKey: 'batiments',
      label: 'Amortissements batiments',
      selector: const _AccountSelector(prefixes: ['2813']),
    );
    yield* _note3cAmortizationRow(
      lines,
      previousLines,
      row: '24',
      fieldKey: 'amenagements',
      label: 'Amortissements amenagements',
      selector: const _AccountSelector(
        prefixes: ['2814', '2815', '2816', '2817'],
      ),
    );
    yield* _note3cAmortizationRow(
      lines,
      previousLines,
      row: '25',
      fieldKey: 'materiel_mobilier',
      label: 'Amortissements materiel et mobilier',
      selector: const _AccountSelector(prefixes: ['2818']),
    );
    yield* _note3cAmortizationRow(
      lines,
      previousLines,
      row: '26',
      fieldKey: 'transport',
      label: 'Amortissements materiel de transport',
      selector: const _AccountSelector(prefixes: ['2844', '2845', '28182']),
    );
  }

  static Iterable<FiscalExcelCellValue> _note4FinancialAssets(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 4',
      currentCell: 'B13',
      previousCell: 'C13',
      fieldKey: 'note4.titres_participation',
      label: 'Titres de participation',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['26']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['26']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 4',
      currentCell: 'B17',
      previousCell: 'C17',
      fieldKey: 'note4.autres_immobilisations_financieres',
      label: 'Autres immobilisations financieres',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['27']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['27']),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note6Inventories(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 6',
      currentCell: 'B12',
      previousCell: 'C12',
      fieldKey: 'note6.stocks',
      label: 'Stocks et en-cours',
      current: _stockValue(lines),
      previous: _stockValue(previousLines),
    );
  }

  static Iterable<FiscalExcelCellValue> _note7MemberReceivables(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    final current = _memberReceivables(lines);
    final previous = _memberReceivables(previousLines);
    yield* _currentPreviousValues(
      sheet: 'NOTE 7',
      currentCell: 'B12',
      previousCell: 'C12',
      fieldKey: 'note7.creances_membres',
      label: 'Creances membres et tiers debiteurs',
      current: current,
      previous: previous,
    );
    yield _value(
      'NOTE 7',
      'E12',
      'excel.note7.creances_membres.moins_un_an',
      'Creances membres a un an au plus',
      current,
    );
  }

  static Iterable<FiscalExcelCellValue> _note8OtherReceivables(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _note8ReceivableRow(
      lines,
      previousLines,
      row: '14',
      fieldKey: 'personnel',
      label: 'Creances sur personnel',
      selector: const _AccountSelector(prefixes: ['42'], nature: 'actif'),
    );
    yield* _note8ReceivableRow(
      lines,
      previousLines,
      row: '15',
      fieldKey: 'organismes_sociaux',
      label: 'Creances sur organismes sociaux',
      selector: const _AccountSelector(prefixes: ['43'], nature: 'actif'),
    );
    yield* _note8ReceivableRow(
      lines,
      previousLines,
      row: '16',
      fieldKey: 'etat_collectivites',
      label: 'Creances sur Etat et collectivites',
      selector: const _AccountSelector(prefixes: ['44'], nature: 'actif'),
    );
    yield* _note8ReceivableRow(
      lines,
      previousLines,
      row: '18',
      fieldKey: 'membres_associes',
      label: 'Creances membres et entites liees',
      selector: const _AccountSelector(prefixes: ['45'], nature: 'actif'),
    );
    yield* _note8ReceivableRow(
      lines,
      previousLines,
      row: '20',
      fieldKey: 'autres_debiteurs',
      label: 'Autres debiteurs divers',
      selector: const _AccountSelector(
        prefixes: ['46', '47', '48'],
        nature: 'actif',
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note9InvestmentSecurities(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 9',
      currentCell: 'B17',
      previousCell: 'C17',
      fieldKey: 'note9.titres_placement_brut',
      label: 'Titres de placement',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['50']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['50']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 9',
      currentCell: 'B20',
      previousCell: 'C20',
      fieldKey: 'note9.depreciation_titres_placement',
      label: 'Depreciation des titres de placement',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['590']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['590']),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note10ReceivableValues(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 10',
      currentCell: 'B15',
      previousCell: 'C15',
      fieldKey: 'note10.valeurs_encaisser_brut',
      label: 'Valeurs a encaisser',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['511']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['511']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 10',
      currentCell: 'B18',
      previousCell: 'C18',
      fieldKey: 'note10.depreciation_valeurs_encaisser',
      label: 'Depreciation des valeurs a encaisser',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['591']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['591']),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note11CashAndBank(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 11',
      currentCell: 'C12',
      previousCell: 'D12',
      fieldKey: 'note11.banques_locales',
      label: 'Banques locales',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['512']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['512']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 11',
      currentCell: 'C18',
      previousCell: 'D18',
      fieldKey: 'note11.autres_etablissements_financiers',
      label: 'Autres etablissements financiers',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['52']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['52']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 11',
      currentCell: 'C21',
      previousCell: 'D21',
      fieldKey: 'note11.caisse',
      label: 'Caisse',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['531']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['531']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 11',
      currentCell: 'C22',
      previousCell: 'D22',
      fieldKey: 'note11.mobile_money',
      label: 'Mobile money',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['55']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['55']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 11',
      currentCell: 'C23',
      previousCell: 'D23',
      fieldKey: 'note11.regies_avances',
      label: 'Regies d avances',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['57']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['57']),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note12ExpenseTransfers(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 12',
      currentCell: 'B25',
      previousCell: 'C25',
      fieldKey: 'note12.transferts_charges_exploitation',
      label: 'Transferts de charges d exploitation',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['78'], excludePrefixes: ['787']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['78'], excludePrefixes: ['787']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 12',
      currentCell: 'B29',
      previousCell: 'C29',
      fieldKey: 'note12.transferts_charges_financieres',
      label: 'Transferts de charges financieres',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['787']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['787']),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note14ReservesAndRetainedEarnings(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 14',
      currentCell: 'C21',
      previousCell: 'D21',
      fieldKey: 'note14.reserves_reglementees',
      label: 'Reserves reglementees et autres reserves',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['106']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['106']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 14',
      currentCell: 'C24',
      previousCell: 'D24',
      fieldKey: 'note14.report_crediteur',
      label: 'Report a nouveau crediteur',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['11']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['11']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 14',
      currentCell: 'C26',
      previousCell: 'D26',
      fieldKey: 'note14.resultat_exercice',
      label: 'Resultat net de l exercice',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['12']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['12']),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue>
  _note15aSubventionsAndRegulatedProvisions(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 15A',
      currentCell: 'C17',
      previousCell: 'D17',
      fieldKey: 'note15a.subventions_investissement',
      label: 'Subventions d investissement et assimilables',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['14']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['14']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 15A',
      currentCell: 'C26',
      previousCell: 'D26',
      fieldKey: 'note15a.provisions_reglementees',
      label: 'Provisions reglementees',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['15']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['15']),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note15bOtherOwnFunds(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTES 15B',
      currentCell: 'C14',
      previousCell: 'D14',
      fieldKey: 'note15b.autres_fonds_propres',
      label: 'Autres fonds propres',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['18']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['18']),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note16aFinancialDebts(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousAndShortDebtValues(
      sheet: 'NOTE 16A',
      row: '8',
      fieldKey: 'note16a.emprunts_etablissements_credit',
      label: 'Emprunts et dettes financieres',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['16']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['16']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 16A',
      currentCell: 'B38',
      previousCell: 'C38',
      fieldKey: 'note16a.autres_provisions',
      label: 'Autres provisions pour risques et charges',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['19']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['19']),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note17SupplierDebts(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 17',
      currentCell: 'B10',
      previousCell: 'C10',
      fieldKey: 'note17.fournisseurs_dettes',
      label: 'Fournisseurs dettes en compte',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['40']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['40']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 17',
      currentCell: 'B17',
      previousCell: 'C17',
      fieldKey: 'note17.fournisseurs_avances',
      label: 'Fournisseurs avances et acomptes',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['409']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['409']),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note18TaxAndSocialDebts(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousAndShortDebtValues(
      sheet: 'NOTE 18',
      row: '12',
      fieldKey: 'note18.personnel_remunerations_dues',
      label: 'Personnel remunerations dues',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['42']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['42']),
      ),
    );
    yield* _currentPreviousAndShortDebtValues(
      sheet: 'NOTE 18',
      row: '14',
      fieldKey: 'note18.organismes_sociaux',
      label: 'Dettes envers organismes sociaux',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['43']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['43']),
      ),
    );
    yield* _currentPreviousAndShortDebtValues(
      sheet: 'NOTE 18',
      row: '20',
      fieldKey: 'note18.etat_impots_taxes',
      label: 'Dettes fiscales et taxes',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['44']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['44']),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note19OtherDebts(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousAndShortDebtValues(
      sheet: 'NOTE 19',
      row: '12',
      fieldKey: 'note19.membres_entites_liees',
      label: 'Comptes courants membres et entites liees',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['45']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['45']),
      ),
    );
    yield* _currentPreviousAndShortDebtValues(
      sheet: 'NOTE 19',
      row: '17',
      fieldKey: 'note19.crediteurs_divers',
      label: 'Crediteurs divers',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['46', '47', '48']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['46', '47', '48']),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note20TreasuryPassive(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 20',
      currentCell: 'B17',
      previousCell: 'C17',
      fieldKey: 'note20.banques_locales_passives',
      label: 'Banques locales crediteurs',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['512'], nature: 'passif'),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['512'], nature: 'passif'),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 20',
      currentCell: 'B21',
      previousCell: 'C21',
      fieldKey: 'note20.credits_tresorerie',
      label: 'Credits de tresorerie',
      current: _creditBySelector(
        lines,
        const _AccountSelector(
          prefixes: ['5'],
          excludePrefixes: ['512'],
          nature: 'passif',
        ),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(
          prefixes: ['5'],
          excludePrefixes: ['512'],
          nature: 'passif',
        ),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note21Revenues(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 21',
      currentCell: 'B35',
      previousCell: 'C35',
      fieldKey: 'note21.production_immobilisee',
      label: 'Production immobilisee',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['72']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['72']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 21',
      currentCell: 'B36',
      previousCell: 'C36',
      fieldKey: 'note21.subventions_exploitation',
      label: 'Subventions d exploitation',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['74']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['74']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 21',
      currentCell: 'B37',
      previousCell: 'C37',
      fieldKey: 'note21.ressources_ordinaires',
      label: 'Ressources ordinaires d eglise',
      current: _creditBySelector(
        lines,
        const _AccountSelector(
          prefixes: ['7'],
          excludePrefixes: ['72', '74', '77', '78', '79'],
        ),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(
          prefixes: ['7'],
          excludePrefixes: ['72', '74', '77', '78', '79'],
        ),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note22Purchases(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 22',
      currentCell: 'B16',
      previousCell: 'C16',
      fieldKey: 'note22.achats_matieres_fournitures',
      label: 'Achats de matieres et fournitures liees',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['601']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['601']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 22',
      currentCell: 'B31',
      previousCell: 'C31',
      fieldKey: 'note22.autres_achats',
      label: 'Autres achats et prestations',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['60'], excludePrefixes: ['601']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['60'], excludePrefixes: ['601']),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note23Transports(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 23',
      currentCell: 'B14',
      previousCell: 'C14',
      fieldKey: 'note23.autres_transports',
      label: 'Transports',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['624']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['624']),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note24ExternalServices(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 24',
      currentCell: 'B11',
      previousCell: 'C11',
      fieldKey: 'note24.locations',
      label: 'Locations et charges locatives',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['613']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['613']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 24',
      currentCell: 'B13',
      previousCell: 'C13',
      fieldKey: 'note24.entretien_maintenance',
      label: 'Entretien, reparations et maintenance',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['615']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['615']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 24',
      currentCell: 'B17',
      previousCell: 'C17',
      fieldKey: 'note24.telecommunications',
      label: 'Frais de telecommunications',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['626']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['626']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 24',
      currentCell: 'B18',
      previousCell: 'C18',
      fieldKey: 'note24.frais_bancaires',
      label: 'Frais bancaires',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['627']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['627']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 24',
      currentCell: 'B23',
      previousCell: 'C23',
      fieldKey: 'note24.autres_charges_externes',
      label: 'Autres charges externes',
      current: _debitBySelector(
        lines,
        const _AccountSelector(
          prefixes: ['61', '62'],
          excludePrefixes: ['613', '615', '624', '626', '627'],
        ),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(
          prefixes: ['61', '62'],
          excludePrefixes: ['613', '615', '624', '626', '627'],
        ),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note25Taxes(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 25',
      currentCell: 'B11',
      previousCell: 'C11',
      fieldKey: 'note25.impots_directs',
      label: 'Impots et taxes directs',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['631']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['631']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 25',
      currentCell: 'B12',
      previousCell: 'C12',
      fieldKey: 'note25.impots_indirects',
      label: 'Impots et taxes indirects',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['632']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['632']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 25',
      currentCell: 'B13',
      previousCell: 'C13',
      fieldKey: 'note25.droits_enregistrement',
      label: 'Droits d enregistrement',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['633']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['633']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 25',
      currentCell: 'B14',
      previousCell: 'C14',
      fieldKey: 'note25.penalites_amendes',
      label: 'Penalites et amendes fiscales',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['637']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['637']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 25',
      currentCell: 'B15',
      previousCell: 'C15',
      fieldKey: 'note25.autres_impots_taxes',
      label: 'Autres impots et taxes',
      current: _debitBySelector(
        lines,
        const _AccountSelector(
          prefixes: ['63'],
          excludePrefixes: ['631', '632', '633', '637'],
        ),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(
          prefixes: ['63'],
          excludePrefixes: ['631', '632', '633', '637'],
        ),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note26OtherCharges(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 26',
      currentCell: 'B10',
      previousCell: 'C10',
      fieldKey: 'note26.pertes_creances_membres',
      label: 'Pertes sur creances membres et tiers',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['654']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['654']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 26',
      currentCell: 'B15',
      previousCell: 'C15',
      fieldKey: 'note26.dons_aides_mecenat',
      label: 'Dons, aides et mecenat accordes',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['645']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['645']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 26',
      currentCell: 'B16',
      previousCell: 'C16',
      fieldKey: 'note26.autres_charges_diverses',
      label: 'Autres charges diverses',
      current: _debitBySelector(
        lines,
        const _AccountSelector(
          prefixes: ['64', '65'],
          excludePrefixes: ['645', '654'],
        ),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(
          prefixes: ['64', '65'],
          excludePrefixes: ['645', '654'],
        ),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note27aStaffCosts(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 27A',
      currentCell: 'B11',
      previousCell: 'C11',
      fieldKey: 'note27a.remunerations_directes',
      label: 'Remunerations directes du personnel',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['661', '662', '663']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['661', '662', '663']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 27A',
      currentCell: 'B13',
      previousCell: 'C13',
      fieldKey: 'note27a.charges_sociales',
      label: 'Charges sociales',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['664', '668']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['664', '668']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 27A',
      currentCell: 'B15',
      previousCell: 'C15',
      fieldKey: 'note27a.personnel_exterieur',
      label: 'Personnel exterieur',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['667']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['667']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 27A',
      currentCell: 'B16',
      previousCell: 'C16',
      fieldKey: 'note27a.autres_charges_sociales',
      label: 'Autres charges de personnel',
      current: _debitBySelector(
        lines,
        const _AccountSelector(
          prefixes: ['66'],
          excludePrefixes: ['661', '662', '663', '664', '667', '668'],
        ),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(
          prefixes: ['66'],
          excludePrefixes: ['661', '662', '663', '664', '667', '668'],
        ),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note28ProvisionsAndDepreciations(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _note28ProvisionRow(
      lines,
      previousLines,
      row: '12',
      fieldKey: 'provisions_reglementees',
      label: 'Provisions reglementees',
      selector: const _AccountSelector(prefixes: ['15']),
    );
    yield* _note28ProvisionRow(
      lines,
      previousLines,
      row: '13',
      fieldKey: 'provisions_risques_charges',
      label: 'Provisions pour risques et charges',
      selector: const _AccountSelector(prefixes: ['19']),
    );
    yield* _note28ProvisionRow(
      lines,
      previousLines,
      row: '17',
      fieldKey: 'depreciations_stocks',
      label: 'Depreciations des stocks',
      selector: const _AccountSelector(prefixes: ['39']),
    );
    yield* _note28ProvisionRow(
      lines,
      previousLines,
      row: '20',
      fieldKey: 'depreciations_creances_membres',
      label: 'Depreciations des creances membres',
      selector: const _AccountSelector(prefixes: ['49']),
    );
    yield* _note28ProvisionRow(
      lines,
      previousLines,
      row: '23',
      fieldKey: 'depreciations_titres_placement',
      label: 'Depreciations des titres de placement',
      selector: const _AccountSelector(prefixes: ['590']),
    );
    yield* _note28ProvisionRow(
      lines,
      previousLines,
      row: '24',
      fieldKey: 'depreciations_valeurs_encaisser',
      label: 'Depreciations des valeurs a encaisser',
      selector: const _AccountSelector(prefixes: ['591']),
    );
  }

  static Iterable<FiscalExcelCellValue> _note29FinancialIncomeAndCharges(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 29',
      currentCell: 'B10',
      previousCell: 'C10',
      fieldKey: 'note29.interets_emprunts',
      label: 'Interets des emprunts',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['671']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['671']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 29',
      currentCell: 'B13',
      previousCell: 'C13',
      fieldKey: 'note29.autres_interets_charges',
      label: 'Autres interets et charges financieres',
      current: _debitBySelector(
        lines,
        const _AccountSelector(
          prefixes: ['67'],
          excludePrefixes: ['671', '676'],
        ),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(
          prefixes: ['67'],
          excludePrefixes: ['671', '676'],
        ),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 29',
      currentCell: 'B15',
      previousCell: 'C15',
      fieldKey: 'note29.pertes_change',
      label: 'Pertes de change',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['676']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['676']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 29',
      currentCell: 'B19',
      previousCell: 'C19',
      fieldKey: 'note29.dotations_financieres',
      label: 'Dotations financieres',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['69']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['69']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 29',
      currentCell: 'B22',
      previousCell: 'C22',
      fieldKey: 'note29.interets_prets_creances',
      label: 'Interets de prets et creances diverses',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['771']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['771']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 29',
      currentCell: 'B25',
      previousCell: 'C25',
      fieldKey: 'note29.revenus_placement',
      label: 'Autres revenus financiers',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['77'], excludePrefixes: ['771']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['77'], excludePrefixes: ['771']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 29',
      currentCell: 'B30',
      previousCell: 'C30',
      fieldKey: 'note29.reprises_financieres',
      label: 'Reprises financieres',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['797']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['797']),
      ),
    );
  }

  static Iterable<FiscalExcelCellValue> _note30HaoIncomeAndCharges(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines,
  ) sync* {
    yield* _currentPreviousValues(
      sheet: 'NOTE 30',
      currentCell: 'B10',
      previousCell: 'C10',
      fieldKey: 'note30.charges_hao',
      label: 'Charges hors activites ordinaires',
      current: _debitBySelector(
        lines,
        const _AccountSelector(prefixes: ['8'], excludePrefixes: ['81']),
      ),
      previous: _debitBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['8'], excludePrefixes: ['81']),
      ),
    );
    yield* _currentPreviousValues(
      sheet: 'NOTE 30',
      currentCell: 'B20',
      previousCell: 'C20',
      fieldKey: 'note30.produits_hao',
      label: 'Produits hors activites ordinaires',
      current: _creditBySelector(
        lines,
        const _AccountSelector(prefixes: ['8'], excludePrefixes: ['82']),
      ),
      previous: _creditBySelector(
        previousLines,
        const _AccountSelector(prefixes: ['8'], excludePrefixes: ['82']),
      ),
    );
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

  static double _netBySelectors(
    List<SyscebnlBalanceLine> lines,
    _AccountSelector debitSelector,
    _AccountSelector creditSelector,
  ) {
    return _debitBySelector(lines, debitSelector) -
        _creditBySelector(lines, creditSelector);
  }

  static double _stockValue(List<SyscebnlBalanceLine> lines) {
    return _debitBySelector(lines, const _AccountSelector(prefixes: ['3']));
  }

  static double _otherReceivables(List<SyscebnlBalanceLine> lines) {
    return _debitBySelector(
      lines,
      const _AccountSelector(
        prefixes: ['45', '46', '47', '48'],
        nature: 'actif',
      ),
    );
  }

  static double _otherDebts(List<SyscebnlBalanceLine> lines) {
    return _creditBySelector(
      lines,
      const _AccountSelector(prefixes: ['45', '46', '47', '48']),
    );
  }

  static double _treasuryActive(List<SyscebnlBalanceLine> lines) {
    return _debitBySelector(
      lines,
      const _AccountSelector(
        prefixes: ['5'],
        excludePrefixes: ['50', '511'],
        nature: 'actif',
      ),
    );
  }

  static double _treasuryPassive(List<SyscebnlBalanceLine> lines) {
    return _creditBySelector(
      lines,
      const _AccountSelector(prefixes: ['5'], nature: 'passif'),
    );
  }

  static double _treasuryNet(List<SyscebnlBalanceLine> lines) {
    return _treasuryActive(lines) - _treasuryPassive(lines);
  }

  static double _receivablesValue(List<SyscebnlBalanceLine> lines) {
    return _debitBySelector(lines, const _AccountSelector(prefixes: ['409'])) +
        _debitBySelector(
          lines,
          const _AccountSelector(
            prefixes: ['4'],
            excludePrefixes: ['409', '45', '46', '47', '48'],
            nature: 'actif',
          ),
        ) +
        _otherReceivables(lines);
  }

  static double _currentLiabilities(List<SyscebnlBalanceLine> lines) {
    return _creditBySelector(lines, const _AccountSelector(prefixes: ['419'])) +
        _creditBySelector(lines, const _AccountSelector(prefixes: ['40'])) +
        _creditBySelector(
          lines,
          const _AccountSelector(prefixes: ['42', '43', '44']),
        ) +
        _otherDebts(lines);
  }

  static Iterable<FiscalExcelCellValue> _note3aGrossRow(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines, {
    required String row,
    required String fieldKey,
    required String label,
    required _AccountSelector selector,
  }) sync* {
    final current = _debitBySelector(lines, selector);
    final previous = _debitBySelector(previousLines, selector);
    yield _value(
      'NOTE 3A',
      'B$row',
      'excel.note3a.$fieldKey.ouverture',
      '$label a l ouverture',
      previous,
    );
    yield _value(
      'NOTE 3A',
      'C$row',
      'excel.note3a.$fieldKey.acquisitions',
      '$label acquisitions ou creations',
      _positiveDelta(current, previous),
    );
    yield _value(
      'NOTE 3A',
      'F$row',
      'excel.note3a.$fieldKey.sorties',
      '$label cessions ou sorties',
      _positiveDelta(previous, current),
    );
    yield _value(
      'NOTE 3A',
      'H$row',
      'excel.note3a.$fieldKey.cloture',
      '$label a la cloture',
      current,
    );
  }

  static Iterable<FiscalExcelCellValue> _note3cAmortizationRow(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines, {
    required String row,
    required String fieldKey,
    required String label,
    required _AccountSelector selector,
  }) sync* {
    final current = _creditBySelector(lines, selector);
    final previous = _creditBySelector(previousLines, selector);
    yield _value(
      'NOTE 3C',
      'B$row',
      'excel.note3c.$fieldKey.ouverture',
      '$label a l ouverture',
      previous,
    );
    yield _value(
      'NOTE 3C',
      'C$row',
      'excel.note3c.$fieldKey.dotations',
      '$label dotations',
      _positiveDelta(current, previous),
    );
    yield _value(
      'NOTE 3C',
      'D$row',
      'excel.note3c.$fieldKey.reductions',
      '$label reductions',
      _positiveDelta(previous, current),
    );
  }

  static Iterable<FiscalExcelCellValue> _note28ProvisionRow(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines, {
    required String row,
    required String fieldKey,
    required String label,
    required _AccountSelector selector,
  }) sync* {
    final current = _creditBySelector(lines, selector);
    final previous = _creditBySelector(previousLines, selector);
    yield _value(
      'NOTE 28',
      'B$row',
      'excel.note28.$fieldKey.ouverture',
      '$label a l ouverture',
      previous,
    );
    yield _value(
      'NOTE 28',
      'C$row',
      'excel.note28.$fieldKey.augmentation',
      '$label augmentations',
      _positiveDelta(current, previous),
    );
    yield _value(
      'NOTE 28',
      'F$row',
      'excel.note28.$fieldKey.reprise',
      '$label reprises ou reductions',
      _positiveDelta(previous, current),
    );
  }

  static Iterable<FiscalExcelCellValue> _currentPreviousValues({
    required String sheet,
    required String currentCell,
    required String previousCell,
    required String fieldKey,
    required String label,
    required double current,
    required double previous,
  }) sync* {
    yield _value(
      sheet,
      currentCell,
      'excel.$fieldKey.current',
      '$label exercice courant',
      current,
    );
    yield _value(
      sheet,
      previousCell,
      'excel.$fieldKey.previous',
      '$label exercice precedent',
      previous,
    );
  }

  static Iterable<FiscalExcelCellValue> _currentPreviousAndShortDebtValues({
    required String sheet,
    required String row,
    required String fieldKey,
    required String label,
    required double current,
    required double previous,
  }) sync* {
    yield* _currentPreviousValues(
      sheet: sheet,
      currentCell: 'B$row',
      previousCell: 'C$row',
      fieldKey: fieldKey,
      label: label,
      current: current,
      previous: previous,
    );
    yield _value(
      sheet,
      'F$row',
      'excel.$fieldKey.moins_un_an',
      '$label a un an au plus',
      current,
    );
  }

  static Iterable<FiscalExcelCellValue> _note8ReceivableRow(
    List<SyscebnlBalanceLine> lines,
    List<SyscebnlBalanceLine> previousLines, {
    required String row,
    required String fieldKey,
    required String label,
    required _AccountSelector selector,
  }) sync* {
    final current = _debitBySelector(lines, selector);
    final previous = _debitBySelector(previousLines, selector);
    yield* _currentPreviousValues(
      sheet: 'NOTE 8',
      currentCell: 'B$row',
      previousCell: 'C$row',
      fieldKey: 'note8.$fieldKey',
      label: label,
      current: current,
      previous: previous,
    );
    yield _value(
      'NOTE 8',
      'E$row',
      'excel.note8.$fieldKey.moins_un_an',
      '$label a un an au plus',
      current,
    );
  }

  static double _memberReceivables(List<SyscebnlBalanceLine> lines) {
    return _debitBySelector(
      lines,
      const _AccountSelector(
        prefixes: ['4'],
        excludePrefixes: ['409', '42', '43', '44', '45', '46', '47', '48'],
        nature: 'actif',
      ),
    );
  }

  static double _positiveDelta(double current, double previous) {
    return math.max(current - previous, 0);
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
