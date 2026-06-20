/// Ecriture OOXML minimale pour generer un classeur fiscal depuis un modele.
///
/// Le principe est de copier le fichier `.xlsx` comme une archive zip et de
/// remplacer uniquement `xl/workbook.xml` et les feuilles ciblees. Les styles,
/// mises en page, dessins, relations et autres parties du classeur restent donc
/// dans l'archive au lieu d'etre recrees.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'syscebnl_excel_mapping.dart';

class FiscalExcelTemplateWriter {
  const FiscalExcelTemplateWriter._();

  static Uint8List write({
    required Uint8List templateBytes,
    required SyscebnlFiscalExcelMapping mapping,
    Map<String, String> definedNames = const {},
    Map<String, String> textReplacements = const {},
    List<RegExp> forbiddenTextPatterns = const [],
    List<RegExp> neutralizeNumericSheetPatterns = const [],
  }) {
    final archive = ZipDecoder().decodeBytes(templateBytes);
    final files = {for (final file in archive.files) file.name: file};

    final workbookPath = 'xl/workbook.xml';
    final workbookRelsPath = 'xl/_rels/workbook.xml.rels';
    final workbookFile = files[workbookPath];
    final relsFile = files[workbookRelsPath];
    if (workbookFile == null || relsFile == null) {
      throw const FormatException('Classeur Excel invalide: workbook absent.');
    }

    final workbookDoc = XmlDocument.parse(_readText(workbookFile));
    final relsDoc = XmlDocument.parse(_readText(relsFile));
    final sheetPaths = _resolveWorksheetPaths(workbookDoc, relsDoc);
    final sharedStrings = _readSharedStrings(files);

    _applyDefinedNames(workbookDoc, definedNames);
    _forceFormulaRecalculation(workbookDoc);

    final replacements = <String, Uint8List>{};

    final valuesBySheet = <String, List<FiscalExcelCellValue>>{};
    for (final value in mapping.values) {
      valuesBySheet.putIfAbsent(value.sheet, () => []).add(value);
    }
    final formulasBySheet = <String, List<FiscalExcelFormula>>{};
    for (final formula in mapping.formulas) {
      formulasBySheet.putIfAbsent(formula.sheet, () => []).add(formula);
    }

    final neutralizedSheetNames = sheetPaths.keys
        .where(
          (sheetName) =>
              _matchesSheetPattern(sheetName, neutralizeNumericSheetPatterns),
        )
        .toSet();

    for (final sheetName in {
      ...neutralizedSheetNames,
      ...valuesBySheet.keys,
      ...formulasBySheet.keys,
    }) {
      final sheetPath = sheetPaths[sheetName];
      if (sheetPath == null) {
        throw FormatException('Feuille Excel introuvable: $sheetName');
      }
      final sheetFile = files[sheetPath];
      if (sheetFile == null) {
        throw FormatException('Fichier de feuille introuvable: $sheetPath');
      }
      final sheetDoc = XmlDocument.parse(_readText(sheetFile));
      if (neutralizedSheetNames.contains(sheetName)) {
        _neutralizeNumericConstants(sheetDoc);
      }
      for (final value in valuesBySheet[sheetName] ?? const []) {
        _setNumericCell(sheetDoc, value.cell, value.value);
      }
      for (final formula in formulasBySheet[sheetName] ?? const []) {
        _setFormulaCell(sheetDoc, formula.cell, formula.formula);
      }
      _syncDefinedNameFormulaCaches(sheetDoc, definedNames);
      _ensureHorizontalPrintCentering(sheetDoc);
      replacements[sheetPath] = _encodeXml(sheetDoc);
    }

    for (final sheetPath in sheetPaths.values) {
      if (replacements.containsKey(sheetPath)) continue;
      final sheetFile = files[sheetPath];
      if (sheetFile == null) continue;
      final sheetDoc = XmlDocument.parse(_readText(sheetFile));
      _syncDefinedNameFormulaCaches(sheetDoc, definedNames);
      _ensureHorizontalPrintCentering(sheetDoc);
      replacements[sheetPath] = _encodeXml(sheetDoc);
    }

    _applyWorksheetPrintAreas(
      workbookDoc,
      sheetPaths,
      files,
      replacements,
      sharedStrings,
    );
    replacements[workbookPath] = _encodeXml(workbookDoc);

    final outputArchive = Archive();
    for (final file in archive.files) {
      if (file.isDirectory) {
        outputArchive.addFile(ArchiveFile.directory(file.name));
        continue;
      }

      final replacement = replacements[file.name];
      final rawBytes = replacement ?? _readBytes(file);
      final outputBytes = _isXmlPart(file.name)
          ? _sanitizeXmlPart(
              file.name,
              rawBytes,
              textReplacements,
              forbiddenTextPatterns,
            )
          : rawBytes;
      final outputFile = ArchiveFile.bytes(file.name, outputBytes);
      outputFile.compression = file.compression;
      outputFile.compressionLevel = file.compressionLevel;
      outputFile.comment = file.comment;
      outputFile.mode = file.mode;
      outputFile.ownerId = file.ownerId;
      outputFile.groupId = file.groupId;
      outputFile.lastModTime = file.lastModTime;
      outputArchive.addFile(outputFile);
    }

    return ZipEncoder().encodeBytes(outputArchive);
  }

  static Map<String, String> _resolveWorksheetPaths(
    XmlDocument workbookDoc,
    XmlDocument relsDoc,
  ) {
    final relationshipTargets = <String, String>{};
    for (final rel in relsDoc.findAllElements('Relationship')) {
      final id = rel.getAttribute('Id');
      final target = rel.getAttribute('Target');
      if (id == null || target == null) continue;
      relationshipTargets[id] = _normalizeWorkbookTarget(target);
    }

    final sheetPaths = <String, String>{};
    for (final sheet in workbookDoc.findAllElements('sheet')) {
      final name = sheet.getAttribute('name');
      final relId = _relationshipId(sheet);
      final target = relId == null ? null : relationshipTargets[relId];
      if (name == null || target == null) continue;
      sheetPaths[name] = target;
    }
    return sheetPaths;
  }

  static bool _matchesSheetPattern(String sheetName, List<RegExp> patterns) {
    final normalized = sheetName.trim();
    return patterns.any((pattern) => pattern.hasMatch(normalized));
  }

  static String? _relationshipId(XmlElement element) {
    for (final attr in element.attributes) {
      if (attr.name.local == 'id') return attr.value;
    }
    return null;
  }

  static String _normalizeWorkbookTarget(String target) {
    final withoutLeadingSlash = target.startsWith('/')
        ? target.substring(1)
        : target;
    if (withoutLeadingSlash.startsWith('xl/')) return withoutLeadingSlash;
    return 'xl/$withoutLeadingSlash';
  }

  static void _applyDefinedNames(
    XmlDocument workbookDoc,
    Map<String, String> definedNames,
  ) {
    if (definedNames.isEmpty) return;

    final definedNamesElement = _ensureDefinedNamesElement(workbookDoc);

    for (final entry in definedNames.entries) {
      final existing = definedNamesElement
          .findElements('definedName')
          .where((element) => element.getAttribute('name') == entry.key)
          .firstOrNull;
      final text = _excelStringLiteral(entry.value);
      if (existing != null) {
        existing.children
          ..clear()
          ..add(XmlText(text));
      } else {
        definedNamesElement.children.add(
          XmlElement(
            XmlName('definedName'),
            [XmlAttribute(XmlName('name'), entry.key)],
            [XmlText(text)],
          ),
        );
      }
    }
  }

  static void _applyWorksheetPrintAreas(
    XmlDocument workbookDoc,
    Map<String, String> sheetPaths,
    Map<String, ArchiveFile> files,
    Map<String, Uint8List> replacements,
    List<String> sharedStrings,
  ) {
    final definedNamesElement = _ensureDefinedNamesElement(workbookDoc);
    definedNamesElement.children.removeWhere((node) {
      if (node is! XmlElement || node.name.local != 'definedName') {
        return false;
      }
      final name = node.getAttribute('name');
      return name == 'Print_Area' || name == '_xlnm.Print_Area';
    });

    final entries = sheetPaths.entries.toList(growable: false);
    for (var index = 0; index < entries.length; index += 1) {
      final entry = entries[index];
      final sheetBytes =
          replacements[entry.value] ?? _readBytes(files[entry.value]!);
      final sheetDoc = XmlDocument.parse(utf8.decode(sheetBytes));
      final usedRange = _worksheetUsedRange(sheetDoc, sharedStrings);
      if (usedRange == null) continue;

      definedNamesElement.children.add(
        XmlElement(
          XmlName('definedName'),
          [
            XmlAttribute(XmlName('name'), '_xlnm.Print_Area'),
            XmlAttribute(XmlName('localSheetId'), '$index'),
          ],
          [
            XmlText(
              '${_quoteSheetName(entry.key)}!${_absoluteRange(usedRange)}',
            ),
          ],
        ),
      );
    }
  }

  static XmlElement _ensureDefinedNamesElement(XmlDocument workbookDoc) {
    final existing = workbookDoc
        .findAllElements('definedNames')
        .cast<XmlElement?>()
        .firstWhere((element) => element != null, orElse: () => null);
    if (existing != null) return existing;

    final definedNamesElement = XmlElement(XmlName('definedNames'));
    final workbook = workbookDoc.rootElement;
    final calcPr = workbook.findElements('calcPr').firstOrNull;
    if (calcPr != null) {
      workbook.children.insert(
        workbook.children.indexOf(calcPr),
        definedNamesElement,
      );
    } else {
      workbook.children.add(definedNamesElement);
    }
    return definedNamesElement;
  }

  static void _forceFormulaRecalculation(XmlDocument workbookDoc) {
    final workbook = workbookDoc.rootElement;
    var calcPr = workbook.findElements('calcPr').firstOrNull;
    if (calcPr == null) {
      calcPr = XmlElement(XmlName('calcPr'));
      workbook.children.add(calcPr);
    }
    _setAttribute(calcPr, 'calcMode', 'auto');
    _setAttribute(calcPr, 'fullCalcOnLoad', '1');
    _setAttribute(calcPr, 'forceFullCalc', '1');
  }

  static void _ensureHorizontalPrintCentering(XmlDocument sheetDoc) {
    final worksheet = sheetDoc.rootElement;
    var printOptions = worksheet.findElements('printOptions').firstOrNull;
    if (printOptions == null) {
      printOptions = XmlElement(XmlName('printOptions'));
      final beforeElement =
          worksheet.findElements('pageMargins').firstOrNull ??
          worksheet.findElements('pageSetup').firstOrNull ??
          worksheet.findElements('headerFooter').firstOrNull;
      if (beforeElement != null) {
        worksheet.children.insert(
          worksheet.children.indexOf(beforeElement),
          printOptions,
        );
      } else {
        worksheet.children.add(printOptions);
      }
    }
    _setAttribute(printOptions, 'horizontalCentered', '1');
  }

  static void _setNumericCell(
    XmlDocument sheetDoc,
    String cellRef,
    double value,
  ) {
    final cell = _ensureCell(sheetDoc, cellRef);
    if (cell.findElements('f').isNotEmpty) {
      cell.children.removeWhere(
        (node) => node is XmlElement && node.name.local == 'v',
      );
      return;
    }
    _removeAttribute(cell, 't');
    cell.children.removeWhere(
      (node) =>
          node is XmlElement &&
          (node.name.local == 'f' || node.name.local == 'v'),
    );
    cell.children.add(
      XmlElement(XmlName('v'), [], [XmlText(_formatNumber(value))]),
    );
  }

  static void _setFormulaCell(
    XmlDocument sheetDoc,
    String cellRef,
    String formula,
  ) {
    final cell = _ensureCell(sheetDoc, cellRef);
    if (_belongsToSharedFormula(sheetDoc, cellRef)) {
      cell.children.removeWhere(
        (node) => node is XmlElement && node.name.local == 'v',
      );
      return;
    }
    _removeAttribute(cell, 't');
    cell.children.removeWhere(
      (node) =>
          node is XmlElement &&
          (node.name.local == 'f' || node.name.local == 'v'),
    );
    cell.children.add(
      XmlElement(XmlName('f'), [], [
        XmlText(formula.replaceFirst(RegExp(r'^='), '')),
      ]),
    );
  }

  static String? _worksheetUsedRange(
    XmlDocument sheetDoc,
    List<String> sharedStrings,
  ) {
    int? minColumn;
    int? maxColumn;
    int? minRow;
    int? maxRow;

    for (final cell in sheetDoc.findAllElements('c')) {
      final cellRef = cell.getAttribute('r');
      if (cellRef == null || cellRef.isEmpty) continue;

      if (!_cellHasPrintableContent(cell, sharedStrings)) continue;

      final parsed = _parseCellRef(cellRef);
      minColumn = minColumn == null || parsed.column < minColumn
          ? parsed.column
          : minColumn;
      maxColumn = maxColumn == null || parsed.column > maxColumn
          ? parsed.column
          : maxColumn;
      minRow = minRow == null || parsed.row < minRow ? parsed.row : minRow;
      maxRow = maxRow == null || parsed.row > maxRow ? parsed.row : maxRow;
    }

    if (minColumn == null ||
        maxColumn == null ||
        minRow == null ||
        maxRow == null) {
      return null;
    }

    return '${_columnName(minColumn)}$minRow:${_columnName(maxColumn)}$maxRow';
  }

  static bool _cellHasPrintableContent(
    XmlElement cell,
    List<String> sharedStrings,
  ) {
    if (cell.findElements('f').isNotEmpty) return true;

    final type = cell.getAttribute('t');
    final valueElement = cell.findElements('v').firstOrNull;
    if (type == 's') {
      final sharedStringIndex = int.tryParse(valueElement?.innerText ?? '');
      if (sharedStringIndex == null ||
          sharedStringIndex < 0 ||
          sharedStringIndex >= sharedStrings.length) {
        return false;
      }
      return sharedStrings[sharedStringIndex].trim().isNotEmpty;
    }

    if (type == 'inlineStr') {
      return cell
          .findAllElements('t')
          .any((element) => element.innerText.trim().isNotEmpty);
    }

    final value = valueElement?.innerText.trim();
    if (value != null && value.isNotEmpty) return true;
    return cell
        .findAllElements('t')
        .any((element) => element.innerText.trim().isNotEmpty);
  }

  static bool _belongsToSharedFormula(XmlDocument sheetDoc, String cellRef) {
    final target = _parseCellRef(cellRef);
    for (final formulaCell in sheetDoc.findAllElements('c')) {
      final formula = formulaCell.findElements('f').firstOrNull;
      if (formula == null) continue;
      if (formula.getAttribute('t') != 'shared') continue;
      if (formulaCell.getAttribute('r') == cellRef) return true;

      final range = formula.getAttribute('ref');
      if (range == null || range.isEmpty) continue;
      if (_rangeContainsCell(range, target)) return true;
    }
    return false;
  }

  static bool _rangeContainsCell(String range, _CellRef cell) {
    final parts = range.split(':');
    if (parts.isEmpty || parts.length > 2) return false;
    final start = _parseCellRef(parts.first);
    final end = _parseCellRef(parts.length == 1 ? parts.first : parts.last);
    final minColumn = start.column < end.column ? start.column : end.column;
    final maxColumn = start.column > end.column ? start.column : end.column;
    final minRow = start.row < end.row ? start.row : end.row;
    final maxRow = start.row > end.row ? start.row : end.row;
    return cell.column >= minColumn &&
        cell.column <= maxColumn &&
        cell.row >= minRow &&
        cell.row <= maxRow;
  }

  static _CellRef _parseCellRef(String cellRef) {
    final normalized = cellRef.replaceAll(r'$', '');
    final column = normalized.replaceAll(RegExp(r'\d'), '');
    final rowMatch = RegExp(r'\d+').firstMatch(normalized);
    if (column.isEmpty || rowMatch == null) {
      throw FormatException('Reference de cellule invalide: $cellRef');
    }
    return _CellRef(
      column: _columnIndex(column),
      row: int.parse(rowMatch.group(0)!),
    );
  }

  static void _syncDefinedNameFormulaCaches(
    XmlDocument sheetDoc,
    Map<String, String> definedNames,
  ) {
    if (definedNames.isEmpty) return;

    for (final cell in sheetDoc.findAllElements('c')) {
      final formula = cell.findElements('f').firstOrNull;
      if (formula == null) continue;

      final formulaName = formula.innerText.trim().replaceFirst(
        RegExp(r'^='),
        '',
      );
      final value = definedNames[formulaName];
      if (value == null) continue;

      _setAttribute(cell, 't', 'str');
      var valueElement = cell.findElements('v').firstOrNull;
      if (valueElement == null) {
        valueElement = XmlElement(XmlName('v'));
        cell.children.add(valueElement);
      }
      valueElement.children
        ..clear()
        ..add(XmlText(value));
    }
  }

  static void _neutralizeNumericConstants(XmlDocument sheetDoc) {
    for (final cell in sheetDoc.findAllElements('c')) {
      final hasFormula = cell.findElements('f').isNotEmpty;
      if (hasFormula) {
        cell.children.removeWhere(
          (node) => node is XmlElement && node.name.local == 'v',
        );
        continue;
      }

      final type = cell.getAttribute('t');
      if (type != null && type != 'n') continue;

      final valueElement = cell.findElements('v').firstOrNull;
      if (valueElement == null) continue;
      if (double.tryParse(valueElement.innerText.trim()) == null) continue;

      _removeAttribute(cell, 't');
      valueElement.children
        ..clear()
        ..add(XmlText('0'));
    }
  }

  static XmlElement _ensureCell(XmlDocument sheetDoc, String cellRef) {
    final rowIndex = _rowIndex(cellRef);
    final row = _ensureRow(sheetDoc, rowIndex);
    final existing = row
        .findElements('c')
        .where((cell) => cell.getAttribute('r') == cellRef)
        .firstOrNull;
    if (existing != null) return existing;

    final cell = XmlElement(XmlName('c'), [
      XmlAttribute(XmlName('r'), cellRef),
    ]);
    final cells = row.findElements('c').toList();
    final insertBefore = cells.indexWhere(
      (current) =>
          _compareCellRefs(current.getAttribute('r') ?? '', cellRef) > 0,
    );
    if (insertBefore == -1) {
      row.children.add(cell);
    } else {
      row.children.insert(row.children.indexOf(cells[insertBefore]), cell);
    }
    return cell;
  }

  static XmlElement _ensureRow(XmlDocument sheetDoc, int rowIndex) {
    final sheetData = sheetDoc
        .findAllElements('sheetData')
        .cast<XmlElement?>()
        .firstWhere((element) => element != null, orElse: () => null);
    if (sheetData == null) {
      throw const FormatException('Feuille Excel invalide: sheetData absent.');
    }

    final existing = sheetData
        .findElements('row')
        .where((row) => row.getAttribute('r') == '$rowIndex')
        .firstOrNull;
    if (existing != null) return existing;

    final row = XmlElement(XmlName('row'), [
      XmlAttribute(XmlName('r'), '$rowIndex'),
    ]);
    final rows = sheetData.findElements('row').toList();
    final insertBefore = rows.indexWhere((current) {
      final currentIndex = int.tryParse(current.getAttribute('r') ?? '') ?? 0;
      return currentIndex > rowIndex;
    });
    if (insertBefore == -1) {
      sheetData.children.add(row);
    } else {
      sheetData.children.insert(
        sheetData.children.indexOf(rows[insertBefore]),
        row,
      );
    }
    return row;
  }

  static int _compareCellRefs(String left, String right) {
    final leftColumn = _columnIndex(left.replaceAll(RegExp(r'\d'), ''));
    final rightColumn = _columnIndex(right.replaceAll(RegExp(r'\d'), ''));
    return leftColumn.compareTo(rightColumn);
  }

  static int _rowIndex(String cellRef) {
    final match = RegExp(r'\d+').firstMatch(cellRef);
    if (match == null) {
      throw FormatException('Reference de cellule invalide: $cellRef');
    }
    return int.parse(match.group(0)!);
  }

  static int _columnIndex(String column) {
    var index = 0;
    for (final codeUnit in column.toUpperCase().codeUnits) {
      if (codeUnit < 65 || codeUnit > 90) continue;
      index = index * 26 + (codeUnit - 64);
    }
    return index;
  }

  static String _columnName(int index) {
    if (index <= 0) {
      throw FormatException('Index de colonne Excel invalide: $index');
    }

    var value = index;
    final codeUnits = <int>[];
    while (value > 0) {
      value -= 1;
      codeUnits.insert(0, 65 + value % 26);
      value ~/= 26;
    }
    return String.fromCharCodes(codeUnits);
  }

  static String _absoluteRange(String range) {
    final parts = range.split(':');
    if (parts.isEmpty || parts.length > 2) {
      throw FormatException('Plage Excel invalide: $range');
    }
    final start = _parseCellRef(parts.first);
    final end = _parseCellRef(parts.length == 1 ? parts.first : parts.last);
    return '${_absoluteCellRef(start)}:${_absoluteCellRef(end)}';
  }

  static String _absoluteCellRef(_CellRef cell) {
    return r'$' + _columnName(cell.column) + r'$' + cell.row.toString();
  }

  static String _quoteSheetName(String sheetName) {
    return "'${sheetName.replaceAll("'", "''")}'";
  }

  static void _setAttribute(XmlElement element, String name, String value) {
    _removeAttribute(element, name);
    element.attributes.add(XmlAttribute(XmlName(name), value));
  }

  static void _removeAttribute(XmlElement element, String name) {
    element.attributes.removeWhere((attr) => attr.name.local == name);
  }

  static String _excelStringLiteral(String value) {
    return '"${value.replaceAll('"', '""')}"';
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  static String _readText(ArchiveFile file) {
    return utf8.decode(_readBytes(file));
  }

  static Uint8List _readBytes(ArchiveFile file) {
    final bytes = file.readBytes();
    if (bytes == null) {
      throw FormatException('Fichier Excel illisible: ${file.name}');
    }
    return bytes;
  }

  static List<String> _readSharedStrings(Map<String, ArchiveFile> files) {
    final file = files['xl/sharedStrings.xml'];
    if (file == null) return const [];

    final doc = XmlDocument.parse(_readText(file));
    return doc
        .findAllElements('si')
        .map(
          (item) =>
              item.findAllElements('t').map((text) => text.innerText).join(),
        )
        .toList(growable: false);
  }

  static Uint8List _encodeXml(XmlDocument document) {
    return Uint8List.fromList(utf8.encode(document.toXmlString()));
  }

  static bool _isXmlPart(String path) {
    return path.endsWith('.xml') || path.endsWith('.rels');
  }

  static Uint8List _sanitizeXmlPart(
    String path,
    Uint8List bytes,
    Map<String, String> textReplacements,
    List<RegExp> forbiddenTextPatterns,
  ) {
    var text = utf8.decode(bytes);
    for (final entry in textReplacements.entries) {
      text = text.replaceAll(entry.key, _escapeXmlText(entry.value));
    }

    final forbidden = <String>[];
    for (final pattern in forbiddenTextPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        forbidden.add('${pattern.pattern} dans $path');
      }
    }

    if (forbidden.isNotEmpty) {
      throw FormatException(
        'Export fiscal refuse: libelles incompatibles avec le SYSCEBNL '
        'ou le contexte eglise detectes (${forbidden.join(', ')}).',
      );
    }

    return Uint8List.fromList(utf8.encode(text));
  }

  static String _escapeXmlText(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}

class _CellRef {
  const _CellRef({required this.column, required this.row});

  final int column;
  final int row;
}

extension _FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
