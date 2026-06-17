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

  final mapping = SyscebnlFiscalExcelMapper.fromBalance(_sampleBalance());
  final bytes = FiscalExcelTemplateWriter.write(
    templateBytes: model.readAsBytesSync(),
    mapping: mapping,
    definedNames: const {
      '_soNom': 'Eglise Prototype SYSCEBNL',
      '_soId': 'NIF-PROTOTYPE',
      '_soSigle': 'EPS',
      '_ExerClos': 'Exercice clos le 31/12/2026',
      '_ExerFin': '31/12/2026',
      '_ExerFin1': '31/12/2025',
      '_Duree': 'Duree (en mois) 12',
    },
    textReplacements: syscebnlFiscalExcelTextReplacements,
    forbiddenTextPatterns: syscebnlFiscalExcelForbiddenPatterns,
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

  stdout.writeln('Prototype genere: ${output.path}');
  stdout.writeln('Feuilles conservees: ${_sheetCount(workbook)}');
  stdout.writeln('Entrees zip conservees: ${outputArchive.files.length}');
  stdout.writeln('ACTIF!D16=${_cellValue(actif, 'D16')}');
  stdout.writeln('ACTIF!E18=${_cellValue(actif, 'E18')}');
  stdout.writeln('PASSIF!D19=${_cellFormula(passif, 'D19')}');
  stdout.writeln('RESULTAT!E20=${_cellValue(resultat, 'E20')}');
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
      numero: '401',
      intitule: 'Fournisseurs',
      nature: 'passif',
      totalDebit: 0,
      totalCredit: 600000,
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
      numero: '645',
      intitule: 'Indemnites et aides',
      nature: 'charge',
      totalDebit: 500000,
      totalCredit: 0,
    ),
    SyscebnlBalanceLine(
      numero: '6811',
      intitule: 'Dotations aux amortissements',
      nature: 'charge',
      totalDebit: 420000,
      totalCredit: 0,
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
