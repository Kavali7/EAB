import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

import 'package:eab/features/fiscal_dossier/services/fiscal_excel_sanitization.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_excel_template_writer.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_organization_identity.dart';
import 'package:eab/features/fiscal_dossier/services/syscebnl_excel_mapping.dart';
import 'package:eab/features/organization/data/organization_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FiscalExcelTemplateWriter', () {
    test(
      'ecrit les cellules SYSCEBNL sans supprimer les parties du modele',
      () {
        final template = _buildMiniWorkbook();
        final mapping = SyscebnlFiscalExcelMapper.fromBalance([
          const SyscebnlBalanceLine(
            numero: '21',
            intitule: 'Terrains',
            nature: 'actif',
            totalDebit: 500000,
            totalCredit: 0,
          ),
          const SyscebnlBalanceLine(
            numero: '213',
            intitule: 'Batiments',
            nature: 'actif',
            totalDebit: 2000000,
            totalCredit: 0,
          ),
          const SyscebnlBalanceLine(
            numero: '2813',
            intitule: 'Amortissement batiments',
            nature: 'passif',
            totalDebit: 0,
            totalCredit: 300000,
          ),
          const SyscebnlBalanceLine(
            numero: '701',
            intitule: 'Dimes',
            nature: 'produit',
            totalDebit: 0,
            totalCredit: 650000,
          ),
          const SyscebnlBalanceLine(
            numero: '613',
            intitule: 'Loyers et locations',
            nature: 'charge',
            totalDebit: 80000,
            totalCredit: 0,
          ),
        ]);

        final output = FiscalExcelTemplateWriter.write(
          templateBytes: template,
          mapping: mapping,
          definedNames: {'_soNom': 'Eglise Test', '_soId': 'NIF-TEST'},
          textReplacements: const {
            'SYSCOHADA': 'SYSCEBNL',
            'société': 'organisation',
          },
          forbiddenTextPatterns: [RegExp('SYSCOHADA'), RegExp('société')],
        );

        final archive = ZipDecoder().decodeBytes(output);
        expect(
          _entryText(archive, 'xl/drawings/drawing1.xml'),
          '<drawing>SYSCEBNL</drawing>',
        );
        expect(
          _entryText(archive, 'xl/sharedStrings.xml'),
          contains('Modele SYSCEBNL organisation'),
        );

        final workbook = XmlDocument.parse(
          _entryText(archive, 'xl/workbook.xml'),
        );
        expect(_definedName(workbook, '_soNom'), '"Eglise Test"');
        expect(_definedName(workbook, '_soId'), '"NIF-TEST"');
        final calcPr = workbook.rootElement.findElements('calcPr').first;
        expect(calcPr.getAttribute('fullCalcOnLoad'), '1');
        expect(calcPr.getAttribute('forceFullCalc'), '1');

        final actif = XmlDocument.parse(
          _entryText(archive, 'xl/worksheets/sheet1.xml'),
        );
        expect(_cellValue(actif, 'A1'), 'Eglise Test');
        expect(_cellType(actif, 'A1'), 'str');
        expect(_cellValue(actif, 'D16'), '500000');
        expect(_cellValue(actif, 'D18'), '2000000');
        expect(_cellValue(actif, 'E18'), '300000');
        expect(_cellStyle(actif, 'D16'), '7');

        final passif = XmlDocument.parse(
          _entryText(archive, 'xl/worksheets/sheet2.xml'),
        );
        expect(_cellFormula(passif, 'D19'), 'RESULTAT!E50');

        final resultat = XmlDocument.parse(
          _entryText(archive, 'xl/worksheets/sheet3.xml'),
        );
        expect(_cellValue(resultat, 'E20'), '650000');
        expect(_cellValue(resultat, 'E27'), '80000');

        final tft = XmlDocument.parse(
          _entryText(archive, 'xl/worksheets/sheet4.xml'),
        );
        expect(
          _cellFormula(tft, 'H14'),
          'RESULTAT!E50+RESULTAT!E34-RESULTAT!E33-RESULTAT!E37',
        );
      },
    );

    test('refuse un classeur qui conserve un libelle interdit', () {
      expect(
        () => FiscalExcelTemplateWriter.write(
          templateBytes: _buildMiniWorkbook(),
          mapping: const SyscebnlFiscalExcelMapping(values: [], formulas: []),
          forbiddenTextPatterns: [RegExp('SYSCOHADA')],
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('neutralise les montants exemples des fiches et notes annexes', () {
      final output = FiscalExcelTemplateWriter.write(
        templateBytes: _buildMiniWorkbook(),
        mapping: const SyscebnlFiscalExcelMapping(values: [], formulas: []),
        neutralizeNumericSheetPatterns: [
          RegExp(r'^FICHE R[1-4]$', caseSensitive: false),
          RegExp(r'^NOTES? \d+[A-Z]?(?: bis)?$', caseSensitive: false),
        ],
      );

      final archive = ZipDecoder().decodeBytes(output);
      final fiche = XmlDocument.parse(
        _entryText(archive, 'xl/worksheets/sheet5.xml'),
      );
      final note = XmlDocument.parse(
        _entryText(archive, 'xl/worksheets/sheet6.xml'),
      );

      expect(_cellValue(fiche, 'AQ14'), '0');
      expect(_cellStyle(fiche, 'AQ14'), '9');
      expect(_cellFormula(fiche, 'AQ15'), 'SUM(AQ14:AQ14)');
      expect(_cellValue(fiche, 'AQ15'), isNull);
      expect(_cellValue(note, 'B12'), '0');
      expect(_cellValue(note, 'C12'), '0');
      expect(_cellFormula(note, 'D12'), 'SUM(B12:B12)');
      expect(_cellValue(note, 'D12'), isNull);
    });

    test('nettoie le modele fiscal reel des donnees exemples', () async {
      final template = await rootBundle.load(
        'assets/templates/fiscal_syscebnl_template.xlsx',
      );
      final identity = FiscalOrganizationIdentity.from(
        organization: const Organization(
          id: 'org-1',
          nom: 'Eglise Apostolique du Benin',
          sigle: 'EAB',
          adresse: '01 BP 100 Cotonou',
          telephone: '+229 01 00 00 00 00',
          email: 'contact@eab.test',
          parametres: {
            OrganizationFiscalProfile.paramKey: {
              'ifu': '1202600000001',
              'registration_number': 'ASS-REL-2026-001',
              'tax_center': 'Centre des impots des organisations religieuses',
              'deposit_center': 'Centre de depot des organisations religieuses',
              'head_office_address': '01 BP 100 Cotonou',
              'activity_description': 'Activites cultuelles et communautaires',
              'legal_representative_name': 'Georges Guidan',
              'legal_representative_title': 'President national',
              'legal_representative_phone': '+229 01 00 00 00 00',
              'accountant_name': 'Comptable Demo',
              'accountant_title': 'Comptable responsable',
              'bank_name': 'Banque de demonstration',
              'bank_account_label': 'Compte principal',
            },
          },
        ),
        values: const {'exercice.label': 'Exercice 2026'},
        periodStart: DateTime(2026),
        periodEnd: DateTime(2026, 12, 31),
        previousPeriodEnd: DateTime(2025, 12, 31),
      );

      final output = FiscalExcelTemplateWriter.write(
        templateBytes: template.buffer.asUint8List(),
        mapping: const SyscebnlFiscalExcelMapping(values: [], formulas: []),
        definedNames: identity.definedNames(),
        textReplacements: {
          ...syscebnlFiscalExcelTextReplacements,
          ...identity.textReplacements(),
        },
        forbiddenTextPatterns: syscebnlFiscalExcelForbiddenPatterns,
        neutralizeNumericSheetPatterns:
            syscebnlFiscalExcelNeutralizedSheetPatterns,
      );

      final archive = ZipDecoder().decodeBytes(output);
      final allXml = archive.files
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
        'import-export',
      ]) {
        expect(
          allXml.toLowerCase(),
          isNot(contains(forbidden.toLowerCase())),
          reason: 'Ancienne donnee modele restante: $forbidden',
        );
      }

      final workbook = XmlDocument.parse(
        _entryText(archive, 'xl/workbook.xml'),
      );
      expect(_definedName(workbook, '_nSo'), '"Eglise Apostolique du Benin"');
      expect(_definedName(workbook, '_soNumFisc'), '"1202600000001"');
      expect(
        _definedName(workbook, '_Ville'),
        '"Centre des impots des organisations religieuses"',
      );
    });
  });
}

Uint8List _buildMiniWorkbook() {
  const sheetNames = [
    'ACTIF',
    'PASSIF',
    'RESULTAT',
    'TFT',
    'FICHE R1 ',
    'NOTE 6',
    'NOTE 3A',
    'NOTE 3C',
    'NOTE 4',
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
  final sheetEntries = [
    for (var i = 0; i < sheetNames.length; i++)
      '    <sheet name="${sheetNames[i]}" sheetId="${i + 1}" r:id="rId${i + 1}"/>',
  ].join('\n');
  final relationshipEntries = [
    for (var i = 0; i < sheetNames.length; i++)
      '  <Relationship Id="rId${i + 1}" Type="worksheet" Target="worksheets/sheet${i + 1}.xml"/>',
  ].join('\n');

  final archive = Archive()
    ..addFile(
      ArchiveFile.string(
        '[Content_Types].xml',
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"/>',
      ),
    )
    ..addFile(
      ArchiveFile.string('xl/workbook.xml', '''
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
$sheetEntries
  </sheets>
  <definedNames>
    <definedName name="_soNom">"Ancien"</definedName>
    <definedName name="_soId">"OLD"</definedName>
  </definedNames>
  <calcPr calcId="1"/>
</workbook>
'''),
    )
    ..addFile(
      ArchiveFile.string('xl/_rels/workbook.xml.rels', '''
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
$relationshipEntries
</Relationships>
'''),
    )
    ..addFile(ArchiveFile.string('xl/worksheets/sheet1.xml', _worksheetXml()))
    ..addFile(ArchiveFile.string('xl/worksheets/sheet2.xml', _worksheetXml()))
    ..addFile(ArchiveFile.string('xl/worksheets/sheet3.xml', _worksheetXml()))
    ..addFile(ArchiveFile.string('xl/worksheets/sheet4.xml', _worksheetXml()))
    ..addFile(
      ArchiveFile.string(
        'xl/worksheets/sheet5.xml',
        _annexWorksheetXml('AQ14', 'AQ15', '125000'),
      ),
    )
    ..addFile(
      ArchiveFile.string(
        'xl/worksheets/sheet6.xml',
        _annexWorksheetXml('B12', 'D12', '52704386', secondCellRef: 'C12'),
      ),
    )
    ..addFile(ArchiveFile.string('xl/worksheets/sheet7.xml', _worksheetXml()))
    ..addFile(ArchiveFile.string('xl/worksheets/sheet8.xml', _worksheetXml()))
    ..addFile(ArchiveFile.string('xl/worksheets/sheet9.xml', _worksheetXml()))
    ..addFile(ArchiveFile.string('xl/worksheets/sheet10.xml', _worksheetXml()))
    ..addFile(ArchiveFile.string('xl/worksheets/sheet11.xml', _worksheetXml()))
    ..addFile(ArchiveFile.string('xl/worksheets/sheet12.xml', _worksheetXml()))
    ..addFile(
      ArchiveFile.string(
        'xl/sharedStrings.xml',
        '<sst><si><t>Modele SYSCOHADA société</t></si></sst>',
      ),
    )
    ..addFile(
      ArchiveFile.string(
        'xl/drawings/drawing1.xml',
        '<drawing>SYSCOHADA</drawing>',
      ),
    );

  for (var sheetIndex = 13; sheetIndex <= sheetNames.length; sheetIndex++) {
    archive.addFile(
      ArchiveFile.string('xl/worksheets/sheet$sheetIndex.xml', _worksheetXml()),
    );
  }

  return ZipEncoder().encodeBytes(archive);
}

String _annexWorksheetXml(
  String sourceCellRef,
  String formulaCellRef,
  String sourceValue, {
  String? secondCellRef,
}) {
  final row = RegExp(r'\d+').firstMatch(sourceCellRef)!.group(0)!;
  final formulaRow = RegExp(r'\d+').firstMatch(formulaCellRef)!.group(0)!;
  final secondCell = secondCellRef == null
      ? ''
      : '<c r="$secondCellRef"><v>42</v></c>';
  return '''
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>
    <row r="$row"><c r="$sourceCellRef" s="9"><v>$sourceValue</v></c>$secondCell</row>
    <row r="$formulaRow"><c r="$formulaCellRef"><f>SUM($sourceCellRef:$sourceCellRef)</f><v>125000</v></c></row>
  </sheetData>
</worksheet>
''';
}

String _worksheetXml() {
  return '''
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>
    <row r="1"><c r="A1" t="str"><f>_soNom</f><v>Cecotra</v></c></row>
    <row r="16"><c r="D16" s="7"><v>0</v></c></row>
    <row r="18"><c r="D18"><v>0</v></c><c r="E18"><v>0</v></c></row>
    <row r="19"><c r="D19"><v>0</v></c></row>
    <row r="20"><c r="E20"><v>0</v></c></row>
    <row r="27"><c r="E27"><v>0</v></c></row>
  </sheetData>
</worksheet>
''';
}

String _entryText(Archive archive, String name) {
  final entry = archive.files.firstWhere((file) => file.name == name);
  return utf8.decode(entry.readBytes() ?? Uint8List(0));
}

String? _definedName(XmlDocument doc, String name) {
  return doc
      .findAllElements('definedName')
      .where((element) => element.getAttribute('name') == name)
      .first
      .innerText;
}

String? _cellValue(XmlDocument doc, String ref) {
  return _cell(doc, ref)?.findElements('v').firstOrNull?.innerText;
}

String? _cellFormula(XmlDocument doc, String ref) {
  return _cell(doc, ref)?.findElements('f').firstOrNull?.innerText;
}

String? _cellStyle(XmlDocument doc, String ref) {
  return _cell(doc, ref)?.getAttribute('s');
}

String? _cellType(XmlDocument doc, String ref) {
  return _cell(doc, ref)?.getAttribute('t');
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
