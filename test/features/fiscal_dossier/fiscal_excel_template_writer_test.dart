import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

import 'package:eab/features/fiscal_dossier/services/fiscal_excel_template_writer.dart';
import 'package:eab/features/fiscal_dossier/services/syscebnl_excel_mapping.dart';

void main() {
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
  });
}

Uint8List _buildMiniWorkbook() {
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
    <sheet name="ACTIF" sheetId="1" r:id="rId1"/>
    <sheet name="PASSIF" sheetId="2" r:id="rId2"/>
    <sheet name="RESULTAT" sheetId="3" r:id="rId3"/>
    <sheet name="TFT" sheetId="4" r:id="rId4"/>
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
  <Relationship Id="rId1" Type="worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="worksheet" Target="worksheets/sheet2.xml"/>
  <Relationship Id="rId3" Type="worksheet" Target="worksheets/sheet3.xml"/>
  <Relationship Id="rId4" Type="worksheet" Target="worksheets/sheet4.xml"/>
</Relationships>
'''),
    )
    ..addFile(ArchiveFile.string('xl/worksheets/sheet1.xml', _worksheetXml()))
    ..addFile(ArchiveFile.string('xl/worksheets/sheet2.xml', _worksheetXml()))
    ..addFile(ArchiveFile.string('xl/worksheets/sheet3.xml', _worksheetXml()))
    ..addFile(ArchiveFile.string('xl/worksheets/sheet4.xml', _worksheetXml()))
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

  return ZipEncoder().encodeBytes(archive);
}

String _worksheetXml() {
  return '''
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>
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
