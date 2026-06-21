import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_excel_sanitization.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_excel_template_writer.dart';
import 'package:eab/features/fiscal_dossier/services/syscebnl_excel_mapping.dart';
import 'package:xml/xml.dart';

void main() {
  final template = File('assets/templates/fiscal_syscebnl_template.xlsx');
  if (!template.existsSync()) {
    stderr.writeln('Template Excel fiscal introuvable: ${template.path}');
    exitCode = 1;
    return;
  }

  final outputDir = Directory('build/exports')..createSync(recursive: true);
  final output = File(
    '${outputDir.path}/dossier_fiscal_syscebnl_eab_2025.xlsx',
  );

  final identity = _eabIdentity;
  final mapping = SyscebnlFiscalExcelMapper.fromBalance(_eabDemoBalance());

  final outputBytes = FiscalExcelTemplateWriter.write(
    templateBytes: template.readAsBytesSync(),
    mapping: mapping,
    definedNames: identity.definedNames(),
    textReplacements: {
      ...syscebnlFiscalExcelTextReplacements,
      ...identity.textReplacements(),
    },
    forbiddenTextPatterns: syscebnlFiscalExcelForbiddenPatterns,
    neutralizeNumericSheetPatterns: syscebnlFiscalExcelNeutralizedSheetPatterns,
  );
  output.writeAsBytesSync(outputBytes);

  final inputArchive = ZipDecoder().decodeBytes(template.readAsBytesSync());
  final outputArchive = ZipDecoder().decodeBytes(outputBytes);
  final audit = _auditWorkbook(
    inputArchive: inputArchive,
    outputArchive: outputArchive,
    mapping: mapping,
  );
  final auditFile = File(
    '${outputDir.path}/dossier_fiscal_syscebnl_eab_2025.audit.json',
  );
  auditFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(audit.toJson(output)),
  );

  stdout.writeln('Export genere: ${output.absolute.path}');
  stdout.writeln('Audit genere: ${auditFile.absolute.path}');
  stdout.writeln('Taille: ${output.lengthSync()} octets');
  stdout.writeln('Feuilles: ${audit.sheetCount}');
  stdout.writeln('Feuilles automatisees: ${audit.automatedSheetCount}');
  stdout.writeln('Feuilles a revue manuelle: ${audit.manualReviewSheetCount}');
  stdout.writeln(
    'Feuilles non classees: ${audit.unclassifiedSheetNames.length}',
  );
  stdout.writeln('Entrees zip preservees: ${audit.preservedArchiveEntries}');
  stdout.writeln('Noms definis critiques:');
  for (final entry in audit.definedNames.entries) {
    stdout.writeln('  ${entry.key} = ${entry.value}');
  }
  stdout.writeln('Cellules SYSCEBNL non nulles:');
  for (final entry in audit.nonZeroCells) {
    stdout.writeln(
      '  ${entry.address} = ${_formatNumber(entry.value)} (${entry.label})',
    );
  }
  stdout.writeln('Formules critiques conservees:');
  for (final entry in audit.criticalFormulas.entries) {
    stdout.writeln('  ${entry.key} = ${entry.value}');
  }
  stdout.writeln('Audit export fiscal EAB 2025: OK');
}

_WorkbookAudit _auditWorkbook({
  required Archive inputArchive,
  required Archive outputArchive,
  required SyscebnlFiscalExcelMapping mapping,
}) {
  final inputNames = inputArchive.files.map((file) => file.name).toSet();
  final outputNames = outputArchive.files.map((file) => file.name).toSet();
  final missing = inputNames.difference(outputNames);
  final added = outputNames.difference(inputNames);
  if (missing.isNotEmpty || added.isNotEmpty) {
    throw StateError(
      'Archive modifiee de facon inattendue. '
      'Manquants=${missing.join(', ')}; ajoutes=${added.join(', ')}',
    );
  }

  final workbook = XmlDocument.parse(
    _entryText(outputArchive, 'xl/workbook.xml'),
  );
  final sheetPaths = _sheetPaths(outputArchive, workbook);
  final normalizedSheetNames = [
    for (final sheet in sheetPaths.keys) sheet.trim(),
  ];
  final normalizedSheets = normalizedSheetNames.toSet();
  final missingAutomated = SyscebnlFiscalExcelMapper.automatedSheetNames
      .where((sheet) => !normalizedSheets.contains(sheet))
      .toList();
  if (missingAutomated.isNotEmpty) {
    throw StateError(
      'Feuilles automatisees introuvables: ${missingAutomated.join(', ')}',
    );
  }
  final missingManual = SyscebnlFiscalExcelMapper.manualReviewSheetNames
      .where((sheet) => !normalizedSheets.contains(sheet))
      .toList();
  if (missingManual.isNotEmpty) {
    throw StateError(
      'Feuilles a revue manuelle introuvables: ${missingManual.join(', ')}',
    );
  }
  final manualPolicyNames = SyscebnlFiscalExcelMapper.manualReviewSheets
      .map((sheet) => sheet.sheet)
      .toSet();
  final manualWithoutPolicy = SyscebnlFiscalExcelMapper.manualReviewSheetNames
      .where((sheet) => !manualPolicyNames.contains(sheet))
      .toList();
  if (manualWithoutPolicy.isNotEmpty) {
    throw StateError(
      'Feuilles a revue manuelle sans justification: '
      '${manualWithoutPolicy.join(', ')}',
    );
  }
  const informationalSheetNames = {'PAGE DE GARDE', 'CODES'};
  final classifiedSheets = {
    ...SyscebnlFiscalExcelMapper.automatedSheetNames,
    ...SyscebnlFiscalExcelMapper.manualReviewSheetNames,
    ...informationalSheetNames,
  };
  final unclassifiedSheetNames = normalizedSheetNames
      .where((sheet) => !classifiedSheets.contains(sheet))
      .toList();
  if (unclassifiedSheetNames.isNotEmpty) {
    throw StateError(
      'Feuilles non classees dans l audit fiscal: '
      '${unclassifiedSheetNames.join(', ')}',
    );
  }

  final allXml = outputArchive.files
      .where((file) => file.name.endsWith('.xml'))
      .map((file) => utf8.decode(file.readBytes() ?? Uint8List(0)))
      .join('\n');
  for (final forbidden in [
    'CECOTRA',
    'AKODA',
    'ALIDOU',
    '3201810353457',
    'RB/ABC/18 B 2310',
    'CIME ATL',
    'BIIC',
    'SOUROU',
    'SYSCOHADA',
  ]) {
    if (allXml.toLowerCase().contains(forbidden.toLowerCase())) {
      throw StateError('Ancienne donnee modele restante: $forbidden');
    }
  }
  for (final expected in [
    '\u00c9glise Apostolique du B\u00e9nin',
    'Georges GUIDAN',
    'Comptable Demo Eglise',
    '3202600000001',
    '31/12/2025',
  ]) {
    if (!allXml.contains(expected)) {
      throw StateError('Information EAB attendue absente: $expected');
    }
  }

  final nonZeroCells =
      mapping.values
          .where(
            (value) => !value.fieldKey.endsWith('.zero') && value.value != 0,
          )
          .toList()
        ..sort((a, b) => a.address.compareTo(b.address));
  if (nonZeroCells.isEmpty) {
    throw StateError('Aucune cellule SYSCEBNL non nulle n a ete injectee.');
  }
  final sheetDocuments = <String, XmlDocument>{};
  for (final cell in nonZeroCells) {
    final sheetPath = _sheetPathByTrim(sheetPaths, cell.sheet);
    if (sheetPath == null) {
      throw StateError('Feuille introuvable pour cellule: ${cell.address}');
    }
    final sheetDoc = sheetDocuments.putIfAbsent(
      sheetPath,
      () => XmlDocument.parse(_entryText(outputArchive, sheetPath)),
    );
    final actual = double.tryParse(_cellValue(sheetDoc, cell.cell) ?? '');
    if (actual == null || (actual - cell.value).abs() > 0.01) {
      throw StateError(
        'Cellule SYSCEBNL incorrecte: ${cell.address}. '
        'Attendu=${_formatNumber(cell.value)}, obtenu=${actual ?? '<vide>'}',
      );
    }
  }

  final criticalFormulas = <String, String>{};
  for (final request in const [
    ('PASSIF', 'D19'),
    ('PASSIF', 'E19'),
    ('TFT', 'I14'),
    ('TFT', 'I40'),
    ('NOTE 21', 'B38'),
  ]) {
    final sheetPath = _sheetPathByTrim(sheetPaths, request.$1);
    if (sheetPath == null) {
      throw StateError('Feuille introuvable pour formule: ${request.$1}');
    }
    final sheet = XmlDocument.parse(_entryText(outputArchive, sheetPath));
    criticalFormulas['${request.$1}!${request.$2}'] =
        _cellFormula(sheet, request.$2) ?? '<absente>';
  }
  if (criticalFormulas.values.any((formula) => formula == '<absente>')) {
    throw StateError('Une formule critique est absente: $criticalFormulas');
  }

  return _WorkbookAudit(
    sheetCount: sheetPaths.length,
    automatedSheetNames: SyscebnlFiscalExcelMapper.automatedSheetNames,
    automatedSheetCount: SyscebnlFiscalExcelMapper.automatedSheetNames.length,
    manualReviewSheetNames: SyscebnlFiscalExcelMapper.manualReviewSheetNames,
    manualReviewSheets: SyscebnlFiscalExcelMapper.manualReviewSheets,
    manualReviewSheetCount:
        SyscebnlFiscalExcelMapper.manualReviewSheetNames.length,
    unclassifiedSheetNames: unclassifiedSheetNames,
    preservedArchiveEntries: inputNames.length == outputNames.length,
    definedNames: {
      '_nSo': _definedName(workbook, '_nSo') ?? '<absent>',
      '_soNumFisc': _definedName(workbook, '_soNumFisc') ?? '<absent>',
      '_Ville': _definedName(workbook, '_Ville') ?? '<absent>',
      '_Perimetre': _definedName(workbook, '_Perimetre') ?? '<absent>',
      '_ExerFin': _definedName(workbook, '_ExerFin') ?? '<absent>',
      '_Devise': _definedName(workbook, '_Devise') ?? '<absent>',
    },
    nonZeroCells: nonZeroCells,
    criticalFormulas: criticalFormulas,
    formulaCount: mapping.formulas.length,
  );
}

final _eabIdentity = _FiscalDemoIdentity(
  organizationName: '\u00c9glise Apostolique du B\u00e9nin',
  organizationSigle: 'EAB',
  ifu: '3202600000001',
  registrationNumber: 'EAB-DEMO-2026-001',
  taxCenter: 'Centre des impots des organisations religieuses - Cotonou',
  depositCenter: 'Direction generale des impots - Cotonou',
  country: 'Benin',
  headOfficeAddress: 'Cotonou, Littoral, Benin',
  activityDescription: 'Organisation religieuse a but non lucratif',
  legalRepresentativeName: 'Georges GUIDAN',
  legalRepresentativeTitle: 'Representant legal de demonstration',
  legalRepresentativePhone: '+229 01 00 00 00 00',
  accountantName: 'Comptable Demo Eglise',
  accountantTitle: 'Comptable responsable des etats SYSCEBNL',
  accountantPhone: '+229 01 00 00 00 01',
  accountantEmail: 'comptable.demo@example.com',
  bankName: 'Banque Demo Benin',
  bankAccountLabel: 'Compte principal de demonstration',
  bankAccountNumber: 'BJ66DEMO000000000001',
  currency: 'FCFA',
  periodLabel: 'Exercice comptable 2025',
  periodStart: DateTime(2025),
  periodEnd: DateTime(2025, 12, 31),
  previousPeriodEnd: DateTime(2024, 12, 31),
  perimeterLabel: 'Organisation - \u00c9glise Apostolique du B\u00e9nin',
);

class _FiscalDemoIdentity {
  const _FiscalDemoIdentity({
    required this.organizationName,
    required this.organizationSigle,
    required this.ifu,
    required this.registrationNumber,
    required this.taxCenter,
    required this.depositCenter,
    required this.country,
    required this.headOfficeAddress,
    required this.activityDescription,
    required this.legalRepresentativeName,
    required this.legalRepresentativeTitle,
    required this.legalRepresentativePhone,
    required this.accountantName,
    required this.accountantTitle,
    required this.accountantPhone,
    required this.accountantEmail,
    required this.bankName,
    required this.bankAccountLabel,
    required this.bankAccountNumber,
    required this.currency,
    required this.periodLabel,
    required this.periodStart,
    required this.periodEnd,
    required this.previousPeriodEnd,
    required this.perimeterLabel,
  });

  final String organizationName;
  final String organizationSigle;
  final String ifu;
  final String registrationNumber;
  final String taxCenter;
  final String depositCenter;
  final String country;
  final String headOfficeAddress;
  final String activityDescription;
  final String legalRepresentativeName;
  final String legalRepresentativeTitle;
  final String legalRepresentativePhone;
  final String accountantName;
  final String accountantTitle;
  final String accountantPhone;
  final String accountantEmail;
  final String bankName;
  final String bankAccountLabel;
  final String bankAccountNumber;
  final String currency;
  final String periodLabel;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime previousPeriodEnd;
  final String perimeterLabel;

  Map<String, String> definedNames() {
    final endDate = _formatDate(periodEnd);
    final previousEndDate = _formatDate(previousPeriodEnd);
    return {
      '_soNom': organizationName,
      '_nSo': organizationName,
      '_soId': ifu,
      '_soNumFisc': ifu,
      'numFisc': ifu,
      '_soSigle': organizationSigle,
      '_soAdresse': headOfficeAddress,
      '_soAdr': headOfficeAddress,
      '_regCom': registrationNumber,
      '_Ville': taxCenter,
      '_centreImpot': depositCenter,
      '_Pays': country,
      '_nCompletPays': country,
      '_Perimetre': perimeterLabel,
      '_Devise': currency,
      '_ExerClos': endDate,
      '_ExerDeb': _formatDate(periodStart),
      '_ExerFin': endDate,
      '_ExerFin1': previousEndDate,
      '_Duree': 'Duree (en mois) ${_monthDuration(periodStart, periodEnd)}',
      '_dAn': periodEnd.year.toString(),
      '_dFin': endDate,
      '_sTabExer': 'Tableaux financiers au $endDate',
      '_soAg1': bankName,
      '_soAg2': bankAccountNumber,
      '_soCompteLibelle': bankAccountLabel,
    };
  }

  Map<String, String> textReplacements() {
    final representativeLine = [
      legalRepresentativeName,
      legalRepresentativeTitle,
      if (legalRepresentativePhone.isNotEmpty) 'Tel $legalRepresentativePhone',
    ].join(' ');
    final representativeNameParts = legalRepresentativeName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final representativeLastName = representativeNameParts.length > 1
        ? representativeNameParts.first
        : legalRepresentativeName;
    final representativeFirstName = representativeNameParts.length > 1
        ? representativeNameParts.skip(1).join(' ')
        : legalRepresentativeName;

    return {
      'CECOTRA': organizationName,
      'Cecotra': organizationName,
      'cecotra': organizationName,
      '3201810353457': ifu,
      'RB/ABC/18 B 2310': registrationNumber,
      'ILOT 1842 M/KPACOSSOU CODJO TANKPE AB-CLAVI': headOfficeAddress,
      'Calavi Tankpe': headOfficeAddress,
      'import-export': activityDescription,
      'CIME ATL': depositCenter,
      'CENTRE DES IMP\u00d4TS DE COTONOU': taxCenter,
      'CENTRE DES IMPOTS DE COTONOU': taxCenter,
      'CENTRE DES IMP'
              '\u00c3\u0192\u00e2\u20ac\u009d'
              'TS DE COTONOU':
          taxCenter,
      'AKODA ALIDOU ASSOCIER GERANT T\u00e9l 61218199': representativeLine,
      'AKODA ALIDOU ASSOCIER GERANT T'
              '\u00c3\u0192\u00c2\u00a9'
              'l 61218199':
          representativeLine,
      'AKODA ALIDOU ASSOCIER GERANT ': representativeLine,
      'AKODA ALIDOU ASSOCIER GERANT': representativeLine,
      'AKODA': representativeLastName,
      'ALIDOU': representativeFirstName,
      'G\u00e9rant': legalRepresentativeTitle,
      'G'
              '\u00c3\u0192\u00c2\u00a9'
              'rant':
          legalRepresentativeTitle,
      'GERANT': legalRepresentativeTitle,
      'Gerant': legalRepresentativeTitle,
      'Ernest Cyrille A. SOUROU': accountantName,
      'BIIC': bankName,
    };
  }
}

List<SyscebnlBalanceLine> _eabDemoBalance() {
  return const [
    SyscebnlBalanceLine(
      numero: '531',
      intitule: 'Caisse',
      nature: 'actif',
      totalDebit: 150000,
      totalCredit: 30000,
    ),
    SyscebnlBalanceLine(
      numero: '5121',
      intitule: 'Banque - Compte principal',
      nature: 'actif',
      totalDebit: 0,
      totalCredit: 80000,
    ),
    SyscebnlBalanceLine(
      numero: '613',
      intitule: 'Loyers et locations',
      nature: 'charge',
      totalDebit: 80000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '645',
      intitule: 'Indemnites et aides',
      nature: 'charge',
      totalDebit: 30000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '702',
      intitule: 'Offrandes de culte',
      nature: 'produit',
      totalDebit: 0,
      totalCredit: 150000,
    ),
  ];
}

Map<String, String> _sheetPaths(Archive archive, XmlDocument workbook) {
  final rels = XmlDocument.parse(
    _entryText(archive, 'xl/_rels/workbook.xml.rels'),
  );
  final targets = <String, String>{};
  for (final rel in rels.findAllElements('Relationship')) {
    final id = rel.getAttribute('Id');
    final target = rel.getAttribute('Target');
    if (id == null || target == null) continue;
    targets[id] = target.startsWith('xl/') ? target : 'xl/$target';
  }

  final sheets = <String, String>{};
  for (final sheet in workbook.findAllElements('sheet')) {
    final name = sheet.getAttribute('name');
    String? relId;
    for (final attr in sheet.attributes) {
      if (attr.name.local == 'id') relId = attr.value;
    }
    final target = relId == null ? null : targets[relId];
    if (name != null && target != null) sheets[name] = target;
  }
  return sheets;
}

String? _sheetPathByTrim(Map<String, String> sheetPaths, String sheetName) {
  for (final entry in sheetPaths.entries) {
    if (entry.key.trim() == sheetName) return entry.value;
  }
  return null;
}

String _entryText(Archive archive, String name) {
  final entry = archive.files.firstWhere((file) => file.name == name);
  return utf8.decode(entry.readBytes() ?? Uint8List(0));
}

String? _definedName(XmlDocument doc, String name) {
  return doc
      .findAllElements('definedName')
      .where((element) => element.getAttribute('name') == name)
      .firstOrNull
      ?.innerText;
}

String? _cellFormula(XmlDocument doc, String ref) {
  return doc
      .findAllElements('c')
      .where((element) => element.getAttribute('r') == ref)
      .firstOrNull
      ?.findElements('f')
      .firstOrNull
      ?.innerText;
}

String? _cellValue(XmlDocument doc, String ref) {
  return doc
      .findAllElements('c')
      .where((element) => element.getAttribute('r') == ref)
      .firstOrNull
      ?.findElements('v')
      .firstOrNull
      ?.innerText;
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

int _monthDuration(DateTime start, DateTime end) {
  final months = (end.year - start.year) * 12 + end.month - start.month + 1;
  return months < 1 ? 1 : months;
}

class _WorkbookAudit {
  const _WorkbookAudit({
    required this.sheetCount,
    required this.automatedSheetNames,
    required this.automatedSheetCount,
    required this.manualReviewSheetNames,
    required this.manualReviewSheets,
    required this.manualReviewSheetCount,
    required this.unclassifiedSheetNames,
    required this.preservedArchiveEntries,
    required this.definedNames,
    required this.nonZeroCells,
    required this.criticalFormulas,
    required this.formulaCount,
  });

  final int sheetCount;
  final List<String> automatedSheetNames;
  final int automatedSheetCount;
  final List<String> manualReviewSheetNames;
  final List<FiscalManualReviewSheet> manualReviewSheets;
  final int manualReviewSheetCount;
  final List<String> unclassifiedSheetNames;
  final bool preservedArchiveEntries;
  final Map<String, String> definedNames;
  final List<FiscalExcelCellValue> nonZeroCells;
  final Map<String, String> criticalFormulas;
  final int formulaCount;

  Map<String, Object?> toJson(File output) {
    return {
      'file': output.absolute.path,
      'sheet_count': sheetCount,
      'automated_sheet_count': automatedSheetCount,
      'automated_sheet_names': automatedSheetNames,
      'manual_review_sheet_count': manualReviewSheetCount,
      'manual_review_sheet_names': manualReviewSheetNames,
      'manual_review_sheets': [
        for (final sheet in manualReviewSheets)
          {
            'sheet': sheet.sheet,
            'category': sheet.category,
            'reason': sheet.reason,
            'required_source': sheet.requiredSource,
          },
      ],
      'unclassified_sheet_count': unclassifiedSheetNames.length,
      'unclassified_sheet_names': unclassifiedSheetNames,
      'preserved_archive_entries': preservedArchiveEntries,
      'defined_names': definedNames,
      'non_zero_cell_count': nonZeroCells.length,
      'formula_count': formulaCount,
      'non_zero_cells': [
        for (final cell in nonZeroCells)
          {
            'address': cell.address,
            'field_key': cell.fieldKey,
            'label': cell.label,
            'value': cell.value,
          },
      ],
      'critical_formulas': criticalFormulas,
    };
  }
}

extension _FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
