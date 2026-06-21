import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_excel_sanitization.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_excel_template_writer.dart';
import 'package:eab/features/fiscal_dossier/services/syscebnl_excel_mapping.dart';
import 'package:xml/xml.dart';

void main() {
  final model = Directory.current.listSync().whereType<File>().where((file) {
    final name = file.uri.pathSegments.last.toLowerCase();
    return name.startsWith('exempele') && name.endsWith('.xlsx');
  }).firstOrNull;

  if (model == null) {
    stderr.writeln('Modele Excel introuvable a la racine du projet.');
    exitCode = 1;
    return;
  }

  final outputDir = Directory('build/prototypes')..createSync(recursive: true);
  final output = File(
    '${outputDir.path}/dossier_fiscal_syscebnl_prototype_${DateTime.now().millisecondsSinceEpoch}.xlsx',
  );

  final mapping = SyscebnlFiscalExcelMapper.fromBalance(
    _sampleBalance(),
    previousLines: _samplePreviousBalance(),
  );
  final bytes = FiscalExcelTemplateWriter.write(
    templateBytes: model.readAsBytesSync(),
    mapping: mapping,
    definedNames: const {
      '_soNom': 'Eglise Prototype SYSCEBNL',
      '_soId': 'NIF-PROTOTYPE',
      '_soSigle': 'EPS',
      '_ExerClos': '31/12/2026',
      '_ExerFin': '31/12/2026',
      '_ExerFin1': '31/12/2025',
      '_Duree': 'Duree (en mois) 12',
    },
    textReplacements: syscebnlFiscalExcelTextReplacements,
    forbiddenTextPatterns: syscebnlFiscalExcelForbiddenPatterns,
    neutralizeNumericSheetPatterns: syscebnlFiscalExcelNeutralizedSheetPatterns,
  );
  output.writeAsBytesSync(bytes);

  final inputArchive = ZipDecoder().decodeBytes(model.readAsBytesSync());
  final outputArchive = ZipDecoder().decodeBytes(bytes);
  final inputNames = inputArchive.files.map((file) => file.name).toSet();
  final outputNames = outputArchive.files.map((file) => file.name).toSet();
  final missing = inputNames.difference(outputNames);
  final added = outputNames.difference(inputNames);

  if (missing.isNotEmpty || added.isNotEmpty) {
    stderr.writeln('Archive modifiee de facon inattendue.');
    stderr.writeln('Manquants: ${missing.join(', ')}');
    stderr.writeln('Ajoutes: ${added.join(', ')}');
    exitCode = 1;
    return;
  }

  final workbook = XmlDocument.parse(
    _entryText(outputArchive, 'xl/workbook.xml'),
  );
  final sheetPaths = _sheetPaths(outputArchive, workbook);
  final actif = XmlDocument.parse(
    _entryText(outputArchive, sheetPaths['ACTIF']!),
  );
  final passif = XmlDocument.parse(
    _entryText(outputArchive, sheetPaths['PASSIF']!),
  );
  final resultat = XmlDocument.parse(
    _entryText(outputArchive, sheetPaths['RESULTAT']!),
  );
  final tft = XmlDocument.parse(_entryText(outputArchive, sheetPaths['TFT']!));
  final ficheR1 = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'FICHE R1')!),
  );
  final note3a = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 3A')!),
  );
  final note3c = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 3C')!),
  );
  final note6 = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 6')!),
  );
  final note7 = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 7')!),
  );
  final note9 = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 9')!),
  );
  final note10 = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 10')!),
  );
  final note11 = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 11')!),
  );
  final note12 = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 12')!),
  );
  final note14 = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 14')!),
  );
  final note15a = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 15A')!),
  );
  final notes15b = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTES 15B')!),
  );
  final note17 = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 17')!),
  );
  final note21 = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 21')!),
  );
  final note24 = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 24')!),
  );
  final note26 = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 26')!),
  );
  final note27a = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 27A')!),
  );
  final note28 = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 28')!),
  );
  final note29 = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 29')!),
  );
  final note31 = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 31')!),
  );
  final note34 = XmlDocument.parse(
    _entryText(outputArchive, _sheetPathByTrim(sheetPaths, 'NOTE 34')!),
  );

  stdout.writeln('Prototype genere: ${output.path}');
  stdout.writeln('Feuilles conservees: ${_sheetCount(workbook)}');
  stdout.writeln('Entrees zip conservees: ${outputArchive.files.length}');
  stdout.writeln('ACTIF!D16=${_cellValue(actif, 'D16')}');
  stdout.writeln('ACTIF!E18=${_cellValue(actif, 'E18')}');
  stdout.writeln('ACTIF!D22=${_cellValue(actif, 'D22')}');
  stdout.writeln('ACTIF!G37=${_cellValue(actif, 'G37')}');
  stdout.writeln('PASSIF!D19=${_cellFormula(passif, 'D19')}');
  stdout.writeln('PASSIF!E19=${_cellFormula(passif, 'E19')}');
  stdout.writeln('RESULTAT!E20=${_cellValue(resultat, 'E20')}');
  stdout.writeln('RESULTAT!F20=${_cellValue(resultat, 'F20')}');
  stdout.writeln('RESULTAT!E49=${_cellValue(resultat, 'E49')}');
  stdout.writeln('TFT!H11=${_cellValue(tft, 'H11')}');
  stdout.writeln('TFT!H17=${_cellValue(tft, 'H17')}');
  stdout.writeln('TFT!I14=${_cellFormula(tft, 'I14')}');
  stdout.writeln('TFT!I40=${_cellFormula(tft, 'I40')}');
  stdout.writeln('FICHE R1!AQ14=${_cellValue(ficheR1, 'AQ14')}');
  stdout.writeln('NOTE 3A!H23=${_cellValue(note3a, 'H23')}');
  stdout.writeln('NOTE 3C!C22=${_cellValue(note3c, 'C22')}');
  stdout.writeln('NOTE 6!B12=${_cellValue(note6, 'B12')}');
  stdout.writeln('NOTE 7!B12=${_cellValue(note7, 'B12')}');
  stdout.writeln('NOTE 9!B17=${_cellValue(note9, 'B17')}');
  stdout.writeln('NOTE 10!B15=${_cellValue(note10, 'B15')}');
  stdout.writeln('NOTE 11!C12=${_cellValue(note11, 'C12')}');
  stdout.writeln('NOTE 11!C21=${_cellValue(note11, 'C21')}');
  stdout.writeln('NOTE 12!B25=${_cellValue(note12, 'B25')}');
  stdout.writeln('NOTE 14!C21=${_cellValue(note14, 'C21')}');
  stdout.writeln('NOTE 15A!C18=${_cellFormula(note15a, 'C18')}');
  stdout.writeln('NOTES 15B!C14=${_cellValue(notes15b, 'C14')}');
  stdout.writeln('NOTE 17!B10=${_cellValue(note17, 'B10')}');
  stdout.writeln('NOTE 21!B37=${_cellValue(note21, 'B37')}');
  stdout.writeln('NOTE 21!B38=${_cellFormula(note21, 'B38')}');
  stdout.writeln('NOTE 24!B11=${_cellValue(note24, 'B11')}');
  stdout.writeln('NOTE 26!B15=${_cellValue(note26, 'B15')}');
  stdout.writeln('NOTE 27A!B11=${_cellValue(note27a, 'B11')}');
  stdout.writeln('NOTE 28!I12=${_cellFormula(note28, 'I12')}');
  stdout.writeln('NOTE 29!B10=${_cellValue(note29, 'B10')}');
  stdout.writeln('NOTE 31!B18=${_cellFormula(note31, 'B18')}');
  stdout.writeln('NOTE 31!B22=${_cellFormula(note31, 'B22')}');
  stdout.writeln('NOTE 34!C10=${_cellFormula(note34, 'C10')}');
  stdout.writeln('Audit libelles SYSCEBNL: OK');
}

List<SyscebnlBalanceLine> _sampleBalance() {
  return const [
    SyscebnlBalanceLine(
      numero: '21',
      intitule: 'Terrains',
      nature: 'actif',
      totalDebit: 1000000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '213',
      intitule: 'Batiments',
      nature: 'actif',
      totalDebit: 15000000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '2813',
      intitule: 'Amortissement batiments',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 1800000,
    ),
    SyscebnlBalanceLine(
      numero: '2183',
      intitule: 'Mobilier',
      nature: 'actif',
      totalDebit: 750000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '28183',
      intitule: 'Amortissement mobilier',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 120000,
    ),
    SyscebnlBalanceLine(
      numero: '411',
      intitule: 'Membres / adherents',
      nature: 'actif',
      totalDebit: 300000,
      totalCredit: 50000,
    ),
    SyscebnlBalanceLine(
      numero: '31',
      intitule: 'Stocks de fournitures',
      nature: 'actif',
      totalDebit: 175000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '5121',
      intitule: 'Banque principale',
      nature: 'actif',
      totalDebit: 2300000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '531',
      intitule: 'Caisse',
      nature: 'actif',
      totalDebit: 450000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '501',
      intitule: 'Titres de placement',
      nature: 'actif',
      totalDebit: 125000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '590',
      intitule: 'Depreciation titres de placement',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 10000,
    ),
    SyscebnlBalanceLine(
      numero: '511',
      intitule: 'Valeurs a encaisser',
      nature: 'actif',
      totalDebit: 90000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '591',
      intitule: 'Depreciation valeurs a encaisser',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 5000,
    ),
    SyscebnlBalanceLine(
      numero: '401',
      intitule: 'Fournisseurs',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 600000,
    ),
    SyscebnlBalanceLine(
      numero: '106',
      intitule: 'Reserves reglementees',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 450000,
    ),
    SyscebnlBalanceLine(
      numero: '110',
      intitule: 'Report a nouveau',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 750000,
    ),
    SyscebnlBalanceLine(
      numero: '120',
      intitule: 'Resultat net',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 100000,
    ),
    SyscebnlBalanceLine(
      numero: '140',
      intitule: 'Subventions d investissement',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 200000,
    ),
    SyscebnlBalanceLine(
      numero: '150',
      intitule: 'Provisions reglementees',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 40000,
    ),
    SyscebnlBalanceLine(
      numero: '180',
      intitule: 'Autres fonds propres',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 65000,
    ),
    SyscebnlBalanceLine(
      numero: '190',
      intitule: 'Provisions risques',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 30000,
    ),
    SyscebnlBalanceLine(
      numero: '390',
      intitule: 'Depreciation stocks',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 15000,
    ),
    SyscebnlBalanceLine(
      numero: '491',
      intitule: 'Depreciation creances',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 6000,
    ),
    SyscebnlBalanceLine(
      numero: '701',
      intitule: 'Dimes',
      nature: 'produit',
      totalDebit: 0,
      totalCredit: 5500000,
    ),
    SyscebnlBalanceLine(
      numero: '702',
      intitule: 'Offrandes',
      nature: 'produit',
      totalDebit: 0,
      totalCredit: 3250000,
    ),
    SyscebnlBalanceLine(
      numero: '613',
      intitule: 'Loyers et locations',
      nature: 'charge',
      totalDebit: 650000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '624',
      intitule: 'Transports',
      nature: 'charge',
      totalDebit: 280000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '631',
      intitule: 'Impots directs',
      nature: 'charge',
      totalDebit: 95000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '645',
      intitule: 'Indemnites et aides',
      nature: 'charge',
      totalDebit: 500000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '661',
      intitule: 'Remunerations directes',
      nature: 'charge',
      totalDebit: 1200000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '664',
      intitule: 'Charges sociales',
      nature: 'charge',
      totalDebit: 240000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '671',
      intitule: 'Interets financiers',
      nature: 'charge',
      totalDebit: 85000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '6811',
      intitule: 'Dotations aux amortissements',
      nature: 'charge',
      totalDebit: 420000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '771',
      intitule: 'Interets recus',
      nature: 'produit',
      totalDebit: 0,
      totalCredit: 30000,
    ),
    SyscebnlBalanceLine(
      numero: '781',
      intitule: 'Transferts de charges',
      nature: 'produit',
      totalDebit: 0,
      totalCredit: 35000,
    ),
    SyscebnlBalanceLine(
      numero: '787',
      intitule: 'Transferts financiers',
      nature: 'produit',
      totalDebit: 0,
      totalCredit: 7000,
    ),
  ];
}

List<SyscebnlBalanceLine> _samplePreviousBalance() {
  return const [
    SyscebnlBalanceLine(
      numero: '21',
      intitule: 'Terrains',
      nature: 'actif',
      totalDebit: 1000000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '213',
      intitule: 'Batiments',
      nature: 'actif',
      totalDebit: 14500000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '2813',
      intitule: 'Amortissement batiments',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 1400000,
    ),
    SyscebnlBalanceLine(
      numero: '2183',
      intitule: 'Mobilier',
      nature: 'actif',
      totalDebit: 600000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '28183',
      intitule: 'Amortissement mobilier',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 80000,
    ),
    SyscebnlBalanceLine(
      numero: '411',
      intitule: 'Membres / adherents',
      nature: 'actif',
      totalDebit: 240000,
      totalCredit: 20000,
    ),
    SyscebnlBalanceLine(
      numero: '31',
      intitule: 'Stocks de fournitures',
      nature: 'actif',
      totalDebit: 125000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '5121',
      intitule: 'Banque principale',
      nature: 'actif',
      totalDebit: 1850000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '531',
      intitule: 'Caisse',
      nature: 'actif',
      totalDebit: 350000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '501',
      intitule: 'Titres de placement',
      nature: 'actif',
      totalDebit: 100000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '590',
      intitule: 'Depreciation titres de placement',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 8000,
    ),
    SyscebnlBalanceLine(
      numero: '511',
      intitule: 'Valeurs a encaisser',
      nature: 'actif',
      totalDebit: 75000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '591',
      intitule: 'Depreciation valeurs a encaisser',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 4000,
    ),
    SyscebnlBalanceLine(
      numero: '401',
      intitule: 'Fournisseurs',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 500000,
    ),
    SyscebnlBalanceLine(
      numero: '106',
      intitule: 'Reserves reglementees',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 420000,
    ),
    SyscebnlBalanceLine(
      numero: '110',
      intitule: 'Report a nouveau',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 700000,
    ),
    SyscebnlBalanceLine(
      numero: '120',
      intitule: 'Resultat net',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 90000,
    ),
    SyscebnlBalanceLine(
      numero: '140',
      intitule: 'Subventions d investissement',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 180000,
    ),
    SyscebnlBalanceLine(
      numero: '150',
      intitule: 'Provisions reglementees',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 25000,
    ),
    SyscebnlBalanceLine(
      numero: '180',
      intitule: 'Autres fonds propres',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 50000,
    ),
    SyscebnlBalanceLine(
      numero: '190',
      intitule: 'Provisions risques',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 35000,
    ),
    SyscebnlBalanceLine(
      numero: '390',
      intitule: 'Depreciation stocks',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 9000,
    ),
    SyscebnlBalanceLine(
      numero: '491',
      intitule: 'Depreciation creances',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 3000,
    ),
    SyscebnlBalanceLine(
      numero: '701',
      intitule: 'Dimes',
      nature: 'produit',
      totalDebit: 0,
      totalCredit: 5000000,
    ),
    SyscebnlBalanceLine(
      numero: '702',
      intitule: 'Offrandes',
      nature: 'produit',
      totalDebit: 0,
      totalCredit: 2800000,
    ),
    SyscebnlBalanceLine(
      numero: '613',
      intitule: 'Loyers et locations',
      nature: 'charge',
      totalDebit: 600000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '624',
      intitule: 'Transports',
      nature: 'charge',
      totalDebit: 220000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '631',
      intitule: 'Impots directs',
      nature: 'charge',
      totalDebit: 80000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '645',
      intitule: 'Indemnites et aides',
      nature: 'charge',
      totalDebit: 450000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '661',
      intitule: 'Remunerations directes',
      nature: 'charge',
      totalDebit: 1050000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '664',
      intitule: 'Charges sociales',
      nature: 'charge',
      totalDebit: 210000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '671',
      intitule: 'Interets financiers',
      nature: 'charge',
      totalDebit: 70000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '6811',
      intitule: 'Dotations aux amortissements',
      nature: 'charge',
      totalDebit: 360000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '771',
      intitule: 'Interets recus',
      nature: 'produit',
      totalDebit: 0,
      totalCredit: 20000,
    ),
    SyscebnlBalanceLine(
      numero: '781',
      intitule: 'Transferts de charges',
      nature: 'produit',
      totalDebit: 0,
      totalCredit: 25000,
    ),
    SyscebnlBalanceLine(
      numero: '787',
      intitule: 'Transferts financiers',
      nature: 'produit',
      totalDebit: 0,
      totalCredit: 5000,
    ),
  ];
}

String _entryText(Archive archive, String name) {
  final entry = archive.files.firstWhere((file) => file.name == name);
  return utf8.decode(entry.readBytes() ?? Uint8List(0));
}

Map<String, String> _sheetPaths(Archive archive, XmlDocument workbook) {
  final rels = XmlDocument.parse(
    _entryText(archive, 'xl/_rels/workbook.xml.rels'),
  );
  final targets = <String, String>{};
  for (final rel in rels.findAllElements('Relationship')) {
    final id = rel.getAttribute('Id');
    final target = rel.getAttribute('Target');
    if (id != null && target != null) targets[id] = 'xl/$target';
  }

  final paths = <String, String>{};
  for (final sheet in workbook.findAllElements('sheet')) {
    final name = sheet.getAttribute('name');
    final relId = sheet.attributes
        .where((attr) => attr.name.local == 'id')
        .firstOrNull
        ?.value;
    if (name != null && relId != null && targets[relId] != null) {
      paths[name] = targets[relId]!;
    }
  }
  return paths;
}

String? _sheetPathByTrim(Map<String, String> paths, String name) {
  for (final entry in paths.entries) {
    if (entry.key.trim() == name) return entry.value;
  }
  return null;
}

int _sheetCount(XmlDocument workbook) {
  return workbook.findAllElements('sheet').length;
}

String? _cellValue(XmlDocument doc, String ref) {
  return _cell(doc, ref)?.findElements('v').firstOrNull?.innerText;
}

String? _cellFormula(XmlDocument doc, String ref) {
  return _cell(doc, ref)?.findElements('f').firstOrNull?.innerText;
}

XmlElement? _cell(XmlDocument doc, String ref) {
  return doc
      .findAllElements('c')
      .where((element) => element.getAttribute('r') == ref)
      .firstOrNull;
}

extension _FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
