import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:eab/features/fiscal_dossier/domain/fiscal_models.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_excel_sanitization.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_excel_template_writer.dart';
import 'package:eab/features/fiscal_dossier/services/fiscal_export_adjustments.dart';
import 'package:eab/features/fiscal_dossier/services/syscebnl_excel_mapping.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

const _defaultDossierId = '00000000-0000-0000-00df-000000002025';
const _templatePath = 'assets/templates/fiscal_syscebnl_template.xlsx';
const _outputDir = 'build/exports';
const _networkTimeout = Duration(seconds: 60);

Future<void> main(List<String> args) async {
  final supabaseUrl = _requiredEnv(
    'SUPABASE_URL',
  ).replaceAll(RegExp(r'/$'), '');
  final serviceRoleKey = _requiredEnv('SUPABASE_SERVICE_ROLE_KEY');
  final dossierId =
      _argValue(args, '--dossier-id') ??
      Platform.environment['FISCAL_DOSSIER_ID'] ??
      _defaultDossierId;

  _logStep('Connexion au projet Supabase distant');
  final client = _SupabaseRestClient(
    baseUrl: supabaseUrl,
    serviceRoleKey: serviceRoleKey,
  );

  _logStep('Lecture du dossier fiscal $dossierId');
  final dossier = FiscalDossier.fromJson(
    await client.single(
      'fiscal_dossiers',
      select: '*',
      filters: {'id': 'eq.$dossierId'},
    ),
  );
  _logStep('Lecture de l\'organisation ${dossier.organizationId}');
  final organization = _RemoteOrganization.fromJson(
    await client.single(
      'organizations',
      select: '*',
      filters: {'id': 'eq.${dossier.organizationId}'},
    ),
  );
  _logStep('Lecture des valeurs fiscales');
  final values = await _fetchValues(client, dossier.id);
  _logStep('${values.length} valeur(s) fiscale(s) lue(s)');
  _logStep('Lecture du perimetre actif');
  final churchUnit = dossier.churchUnitId == null
      ? null
      : ChurchUnit.fromJson(
          await client.single(
            'church_units',
            select: '''
              id,
              organization_id,
              type_id,
              parent_id,
              nom,
              code,
              description,
              ville,
              quartier,
              adresse,
              telephone,
              email,
              active,
              legacy_region_id,
              legacy_district_id,
              legacy_assemblee_id,
              type:church_unit_types(
                code,
                label,
                level_order,
                is_local,
                is_financial_scope,
                can_have_members,
                can_have_cash_accounts,
                can_have_bank_accounts,
                can_have_mobile_money_accounts,
                can_create_programs,
                can_launch_contributions,
                can_validate_finances,
                can_consolidate_finances,
                can_notify_descendants,
                can_view_descendants
              )
            ''',
            filters: {'id': 'eq.${dossier.churchUnitId}'},
          ),
        );

  final dateFin =
      _dateValue(values['exercice.date_fin']) ??
      _fallbackDateFin(dossier, values);
  final dateDebut =
      _dateValue(values['exercice.date_debut']) ?? DateTime(dateFin.year, 1, 1);
  if (dateDebut.isAfter(dateFin)) {
    throw StateError('Export refused: period start is after period end.');
  }

  _logStep('Periode: ${_dateParam(dateDebut)} au ${_dateParam(dateFin)}');
  final previousPeriod = _previousPeriod(dateDebut, dateFin);
  _logStep('Chargement de la balance courante');
  final currentLines = await _loadCurrentLines(
    client: client,
    dossier: dossier,
    churchUnitId: dossier.churchUnitId,
    dateDebut: dateDebut,
    dateFin: dateFin,
  );
  _logStep('${currentLines.length} ligne(s) courante(s) retenue(s)');
  _logStep('Chargement de la balance comparative');
  final previousLines = await _loadAccountingLines(
    client: client,
    dossier: dossier,
    churchUnitId: dossier.churchUnitId,
    dateDebut: previousPeriod.start,
    dateFin: previousPeriod.end,
  );
  _logStep('${previousLines.length} ligne(s) comparative(s) retenue(s)');

  _logStep('Application des ajustements et du mapping SYSCEBNL');
  final adjustments = FiscalExportAdjustmentCodec.decode(
    values[FiscalExportAdjustmentCodec.fieldKey],
  );
  final adjusted = FiscalExportAdjustmentEngine.apply(
    balanceLines: currentLines,
    adjustments: adjustments,
  );
  final previousAdjusted = previousLines.isEmpty
      ? null
      : FiscalExportAdjustmentEngine.apply(
          balanceLines: previousLines,
          adjustments: const [],
        );
  _logStep('Construction des cellules Excel');
  final mapping = SyscebnlFiscalExcelMapper.fromBalance(
    adjusted.lines,
    previousLines: previousAdjusted?.lines ?? const [],
  );
  _logStep(
    '${mapping.values.length + mapping.formulas.length} cellule(s) preparee(s)',
  );
  final identity = _RemoteFiscalIdentity.from(
    organization: organization,
    values: values,
    periodStart: dateDebut,
    periodEnd: dateFin,
    previousPeriodEnd: previousPeriod.end,
    churchUnit: churchUnit,
  );

  final template = File(_templatePath);
  if (!template.existsSync()) {
    throw StateError('Fiscal Excel template not found: $_templatePath');
  }
  _logStep('Generation du classeur Excel');
  final bytes = FiscalExcelTemplateWriter.write(
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

  final outDir = Directory(_outputDir)..createSync(recursive: true);
  final filename = _filename(organization, churchUnit, dateFin);
  final output = File('${outDir.path}/$filename');
  output.writeAsBytesSync(bytes);

  _logStep('Audit du classeur genere');
  final audit = _auditWorkbook(
    output: output,
    templateBytes: template.readAsBytesSync(),
    outputBytes: bytes,
    identity: identity,
    mapping: mapping,
    currentLines: currentLines,
    previousLines: previousLines,
    adjustmentCount: adjusted.adjustmentCount,
    adjustmentLineCount: adjusted.adjustmentLineCount,
  );
  final auditFile = File(
    '${outDir.path}/${filename.replaceAll('.xlsx', '')}.audit.json',
  );
  auditFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(audit),
  );

  stdout.writeln('Export generated: ${output.absolute.path}');
  stdout.writeln('Audit generated: ${auditFile.absolute.path}');
  stdout.writeln('Organization: ${identity.organizationName}');
  stdout.writeln('IFU: ${identity.ifu}');
  stdout.writeln('Current balance lines: ${currentLines.length}');
  stdout.writeln('Previous balance lines: ${previousLines.length}');
  stdout.writeln(
    'Injected cells: ${mapping.values.length + mapping.formulas.length}',
  );
  stdout.writeln('Forbidden legacy terms: ${audit['forbiddenLegacyTerms']}');
}

void _logStep(String message) {
  stderr.writeln('[export-fiscal] $message');
}

Future<Map<String, dynamic>> _fetchValues(
  _SupabaseRestClient client,
  String dossierId,
) async {
  final rows = await client.list(
    'fiscal_dossier_values',
    select: 'field_key,value',
    filters: {'dossier_id': 'eq.$dossierId'},
  );
  return {for (final row in rows) row['field_key'].toString(): row['value']};
}

Future<List<SyscebnlBalanceLine>> _loadCurrentLines({
  required _SupabaseRestClient client,
  required FiscalDossier dossier,
  required String? churchUnitId,
  required DateTime dateDebut,
  required DateTime dateFin,
}) async {
  final importId = dossier.importId?.trim();
  if (importId != null && importId.isNotEmpty) {
    final imported = await client.list(
      'imported_trial_balance_lines',
      select: '*',
      filters: {'import_id': 'eq.$importId'},
      order: 'account_number.asc',
    );
    final lines = imported
        .map(ImportedTrialBalanceLine.fromJson)
        .map(_fromImportedLine)
        .where(_hasUsableAmount)
        .toList(growable: false);
    if (lines.isNotEmpty) return lines;
  }
  return _loadAccountingLines(
    client: client,
    dossier: dossier,
    churchUnitId: churchUnitId,
    dateDebut: dateDebut,
    dateFin: dateFin,
  );
}

Future<List<SyscebnlBalanceLine>> _loadAccountingLines({
  required _SupabaseRestClient client,
  required FiscalDossier dossier,
  required String? churchUnitId,
  required DateTime dateDebut,
  required DateTime dateFin,
}) async {
  final resolvedUnitId = churchUnitId?.trim();
  final accounts = await client.list(
    'comptes_comptables',
    select: 'id,numero,intitule,nature,niveau',
    filters: {
      'organization_id': 'eq.${dossier.organizationId}',
      'actif': 'eq.true',
    },
    order: 'numero.asc',
  );
  final accountById = {
    for (final row in accounts) row['id'].toString(): _RemoteAccount.from(row),
  };
  if (accountById.isEmpty) return const [];

  final units = await _loadRemoteUnits(client, dossier.organizationId);
  final allowedUnitIds = _descendantUnitIds(units, resolvedUnitId);
  final legacyUnitByAssemblyId = {
    for (final unit in units)
      if (unit.legacyAssembleeId != null) unit.legacyAssembleeId!: unit.id,
  };

  final entries = await client.list(
    'ecritures_comptables',
    select: 'id,date,church_unit_id,id_assemblee_locale',
    filters: {
      'organization_id': 'eq.${dossier.organizationId}',
      'statut': 'in.(validee,cloturee)',
      'deleted_at': 'is.null',
    },
    order: 'date.asc',
  );
  final entryIds = entries
      .where((row) {
        final date = DateTime.tryParse(row['date'].toString());
        if (date == null || date.isBefore(dateDebut) || date.isAfter(dateFin)) {
          return false;
        }
        if (resolvedUnitId == null || resolvedUnitId.isEmpty) return true;
        final directUnitId = _stringValue(row['church_unit_id']);
        final legacyAssemblyId = _stringValue(row['id_assemblee_locale']);
        final entryUnitId =
            directUnitId ?? legacyUnitByAssemblyId[legacyAssemblyId];
        return entryUnitId != null && allowedUnitIds.contains(entryUnitId);
      })
      .map((row) => row['id'].toString())
      .toList(growable: false);
  if (entryIds.isEmpty) return const [];

  final totals = <String, _BalanceAccumulator>{};
  for (final chunk in _chunks(entryIds, 80)) {
    final lines = await client.list(
      'lignes_ecritures',
      select: 'id_ecriture,id_compte_comptable,debit,credit',
      filters: {'id_ecriture': 'in.(${chunk.join(',')})'},
    );
    for (final line in lines) {
      final accountId = _stringValue(line['id_compte_comptable']);
      final account = accountId == null ? null : accountById[accountId];
      if (account == null) continue;
      final accumulator = totals.putIfAbsent(
        account.id,
        () => _BalanceAccumulator(account),
      );
      accumulator
        ..debit += _doubleValue(line['debit'])
        ..credit += _doubleValue(line['credit']);
    }
  }

  final ordered = totals.values.toList()
    ..sort((a, b) => a.account.numero.compareTo(b.account.numero));
  return ordered
      .map((line) => line.toBalanceLine())
      .where(_hasUsableAmount)
      .toList(growable: false);
}

SyscebnlBalanceLine _fromImportedLine(ImportedTrialBalanceLine line) {
  final debit = _round(line.debit);
  final credit = _round(line.credit);
  return SyscebnlBalanceLine(
    numero: line.accountNumber.trim(),
    intitule: line.accountLabel?.trim().isNotEmpty == true
        ? line.accountLabel!.trim()
        : 'Compte ${line.accountNumber.trim()}',
    nature: _natureFromAccount(line.accountNumber, debit, credit),
    totalDebit: debit,
    totalCredit: credit,
  );
}

String _natureFromBalance({
  required String account,
  required double debit,
  required double credit,
  required double soldeDebiteur,
  required double soldeCrediteur,
}) {
  if (soldeDebiteur > soldeCrediteur) return 'actif';
  if (soldeCrediteur > soldeDebiteur) return 'passif';
  return _natureFromAccount(account, debit, credit);
}

String _natureFromAccount(String account, double debit, double credit) {
  final numero = account.trim();
  if (numero.startsWith('6')) return 'charge';
  if (numero.startsWith('7')) return 'produit';
  if (numero.startsWith('1')) return 'passif';
  if (numero.startsWith('2') || numero.startsWith('3')) return 'actif';
  if (numero.startsWith('4') || numero.startsWith('5')) {
    return debit >= credit ? 'actif' : 'passif';
  }
  if (numero.startsWith('8')) {
    return debit >= credit ? 'charge' : 'produit';
  }
  return debit >= credit ? 'actif' : 'passif';
}

Map<String, dynamic> _auditWorkbook({
  required File output,
  required List<int> templateBytes,
  required List<int> outputBytes,
  required _RemoteFiscalIdentity identity,
  required SyscebnlFiscalExcelMapping mapping,
  required List<SyscebnlBalanceLine> currentLines,
  required List<SyscebnlBalanceLine> previousLines,
  required int adjustmentCount,
  required int adjustmentLineCount,
}) {
  final templateArchive = ZipDecoder().decodeBytes(templateBytes);
  final outputArchive = ZipDecoder().decodeBytes(outputBytes);
  final templateNames = templateArchive.files.map((file) => file.name).toSet();
  final outputNames = outputArchive.files.map((file) => file.name).toSet();
  final missingEntries = templateNames.difference(outputNames).toList()..sort();
  final addedEntries = outputNames.difference(templateNames).toList()..sort();
  final workbook = XmlDocument.parse(
    _entryText(outputArchive, 'xl/workbook.xml'),
  );
  final sheetNames = workbook
      .findAllElements('sheet')
      .map((sheet) => sheet.getAttribute('name') ?? '')
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
  final forbidden = _findForbiddenLegacyTerms(outputArchive);
  if (missingEntries.isNotEmpty || addedEntries.isNotEmpty) {
    throw StateError(
      'Generated workbook archive differs from template. '
      'Missing=${missingEntries.join(', ')}; added=${addedEntries.join(', ')}',
    );
  }
  if (forbidden.isNotEmpty) {
    throw StateError(
      'Generated workbook still contains legacy template terms: '
      '${forbidden.join(', ')}',
    );
  }
  return {
    'output': output.absolute.path,
    'size': output.lengthSync(),
    'organization': identity.organizationName,
    'sigle': identity.organizationSigle,
    'ifu': identity.ifu,
    'perimeter': identity.perimeterLabel,
    'periodStart': identity.periodStart.toIso8601String(),
    'periodEnd': identity.periodEnd.toIso8601String(),
    'sheetCount': sheetNames.length,
    'missingArchiveEntries': missingEntries,
    'addedArchiveEntries': addedEntries,
    'currentBalanceLines': currentLines.length,
    'previousBalanceLines': previousLines.length,
    'adjustmentCount': adjustmentCount,
    'adjustmentLineCount': adjustmentLineCount,
    'injectedValues': mapping.values.length,
    'injectedFormulas': mapping.formulas.length,
    'forbiddenLegacyTerms': forbidden,
  };
}

List<String> _findForbiddenLegacyTerms(Archive archive) {
  const terms = [
    'CECOTRA',
    'Cecotra',
    'cecotra',
    'AKODA',
    'ALIDOU',
    '3201810353457',
    'RB/ABC/18 B 2310',
  ];
  final found = <String>{};
  for (final file in archive.files) {
    if (file.isDirectory || !_isTextEntry(file.name)) continue;
    final text = utf8.decode(_archiveBytes(file), allowMalformed: true);
    for (final term in terms) {
      if (text.contains(term)) found.add(term);
    }
  }
  return found.toList()..sort();
}

String _entryText(Archive archive, String name) {
  final file = archive.files.where((entry) => entry.name == name).firstOrNull;
  if (file == null) throw StateError('Workbook entry missing: $name');
  return utf8.decode(_archiveBytes(file));
}

List<int> _archiveBytes(ArchiveFile file) {
  final bytes = file.readBytes();
  if (bytes == null) {
    throw StateError('Workbook entry unreadable: ${file.name}');
  }
  return bytes;
}

bool _isTextEntry(String name) {
  return name.endsWith('.xml') || name.endsWith('.rels');
}

bool _hasUsableAmount(SyscebnlBalanceLine line) {
  return line.numero.trim().isNotEmpty &&
      (_round(line.totalDebit).abs() > 0 || _round(line.totalCredit).abs() > 0);
}

double _round(double value) => (value * 100).roundToDouble() / 100;

double _doubleValue(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
  }
  return 0;
}

DateTime? _dateValue(dynamic value) {
  final raw = _stringValue(value);
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

DateTime _fallbackDateFin(FiscalDossier dossier, Map<String, dynamic> values) {
  final raw = [
    _stringValue(values['exercice.label']),
    dossier.label,
  ].whereType<String>().join(' ');
  final match = RegExp(r'(20\d{2})').firstMatch(raw);
  final year = match == null ? DateTime.now().year : int.parse(match.group(1)!);
  return DateTime(year, 12, 31);
}

_FiscalPeriod _previousPeriod(DateTime start, DateTime end) {
  return _FiscalPeriod(_shiftOneYearBack(start), _shiftOneYearBack(end));
}

DateTime _shiftOneYearBack(DateTime date) {
  final targetYear = date.year - 1;
  final day = date.day
      .clamp(1, _lastDayOfMonth(targetYear, date.month))
      .toInt();
  return DateTime(targetYear, date.month, day);
}

int _lastDayOfMonth(int year, int month) => DateTime(year, month + 1, 0).day;

String _dateParam(DateTime date) => date.toIso8601String().substring(0, 10);

String? _stringValue(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String _filename(
  _RemoteOrganization organization,
  ChurchUnit? unit,
  DateTime dateFin,
) {
  final sigle =
      (organization.sigle?.trim().isNotEmpty == true
              ? organization.sigle
              : organization.name)
          ?.trim();
  final base = [
    'dossier_fiscal_syscebnl',
    sigle,
    unit?.nom ?? 'perimetre',
    dateFin.year.toString(),
    'remote',
  ].whereType<String>().join('_');
  return '${_slug(base)}.xlsx';
}

String _slug(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String _requiredEnv(String key) {
  final value = Platform.environment[key]?.trim();
  if (value == null || value.isEmpty) {
    throw StateError('Missing environment variable: $key');
  }
  return value;
}

String? _argValue(List<String> args, String key) {
  final index = args.indexOf(key);
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}

Future<List<_RemoteUnit>> _loadRemoteUnits(
  _SupabaseRestClient client,
  String organizationId,
) async {
  final rows = await client.list(
    'church_units',
    select: 'id,parent_id,legacy_assemblee_id',
    filters: {'organization_id': 'eq.$organizationId'},
  );
  return rows.map(_RemoteUnit.from).toList(growable: false);
}

Set<String> _descendantUnitIds(List<_RemoteUnit> units, String? rootId) {
  final resolvedRootId = rootId?.trim();
  if (resolvedRootId == null || resolvedRootId.isEmpty) {
    return units.map((unit) => unit.id).toSet();
  }
  final childrenByParent = <String, List<_RemoteUnit>>{};
  for (final unit in units) {
    final parentId = unit.parentId;
    if (parentId == null) continue;
    childrenByParent.putIfAbsent(parentId, () => []).add(unit);
  }
  final allowed = <String>{resolvedRootId};
  final pending = <String>[resolvedRootId];
  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    for (final child in childrenByParent[current] ?? const <_RemoteUnit>[]) {
      if (allowed.add(child.id)) pending.add(child.id);
    }
  }
  return allowed;
}

Iterable<List<T>> _chunks<T>(List<T> values, int size) sync* {
  for (var index = 0; index < values.length; index += size) {
    final end = (index + size).clamp(0, values.length).toInt();
    yield values.sublist(index, end);
  }
}

class _RemoteAccount {
  const _RemoteAccount({
    required this.id,
    required this.numero,
    required this.intitule,
    required this.nature,
  });

  final String id;
  final String numero;
  final String intitule;
  final String nature;

  factory _RemoteAccount.from(Map<String, dynamic> json) {
    return _RemoteAccount(
      id: json['id'].toString(),
      numero: _stringValue(json['numero']) ?? '',
      intitule: _stringValue(json['intitule']) ?? '',
      nature: (_stringValue(json['nature']) ?? '').toLowerCase(),
    );
  }
}

class _RemoteUnit {
  const _RemoteUnit({required this.id, this.parentId, this.legacyAssembleeId});

  final String id;
  final String? parentId;
  final String? legacyAssembleeId;

  factory _RemoteUnit.from(Map<String, dynamic> json) {
    return _RemoteUnit(
      id: json['id'].toString(),
      parentId: _stringValue(json['parent_id']),
      legacyAssembleeId: _stringValue(json['legacy_assemblee_id']),
    );
  }
}

class _BalanceAccumulator {
  _BalanceAccumulator(this.account);

  final _RemoteAccount account;
  double debit = 0;
  double credit = 0;

  SyscebnlBalanceLine toBalanceLine() {
    final totalDebit = _round(debit);
    final totalCredit = _round(credit);
    final soldeDebiteur = totalDebit > totalCredit
        ? totalDebit - totalCredit
        : 0.0;
    final soldeCrediteur = totalCredit > totalDebit
        ? totalCredit - totalDebit
        : 0.0;
    return SyscebnlBalanceLine(
      numero: account.numero,
      intitule: account.intitule,
      nature: account.nature.isNotEmpty
          ? account.nature
          : _natureFromBalance(
              account: account.numero,
              debit: totalDebit,
              credit: totalCredit,
              soldeDebiteur: soldeDebiteur,
              soldeCrediteur: soldeCrediteur,
            ),
      totalDebit: totalDebit,
      totalCredit: totalCredit,
    );
  }
}

class _FiscalPeriod {
  const _FiscalPeriod(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

class _RemoteOrganization {
  const _RemoteOrganization({
    required this.id,
    required this.name,
    this.sigle,
    this.description,
    this.adresse,
    this.telephone,
    this.email,
    this.siteWeb,
    this.devise = 'FCFA',
    this.parametres,
  });

  final String id;
  final String name;
  final String? sigle;
  final String? description;
  final String? adresse;
  final String? telephone;
  final String? email;
  final String? siteWeb;
  final String devise;
  final Map<String, dynamic>? parametres;

  _RemoteFiscalProfile get fiscalProfile {
    return _RemoteFiscalProfile.fromOrganization(this);
  }

  factory _RemoteOrganization.fromJson(Map<String, dynamic> json) {
    return _RemoteOrganization(
      id: json['id'] as String,
      name: json['nom'] as String? ?? json['name'] as String? ?? 'Organisation',
      sigle: json['sigle'] as String? ?? json['code'] as String?,
      description: json['description'] as String?,
      adresse: json['adresse'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      siteWeb: json['site_web'] as String?,
      devise: json['devise'] as String? ?? 'FCFA',
      parametres: _mapValue(json['parametres']),
    );
  }
}

class _RemoteFiscalProfile {
  const _RemoteFiscalProfile({
    this.ifu,
    this.registrationNumber,
    this.taxCenter,
    this.depositCenter,
    this.country,
    this.headOfficeAddress,
    this.activityDescription,
    this.legalRepresentativeName,
    this.legalRepresentativeTitle,
    this.legalRepresentativePhone,
    this.accountantName,
    this.accountantTitle,
    this.accountantPhone,
    this.accountantEmail,
    this.bankName,
    this.bankAccountLabel,
    this.bankAccountNumber,
    this.legalFormCode,
    this.taxRegimeCode,
    this.countryCode,
    this.establishmentsInCountry,
    this.establishmentsOutsideCountry,
    this.firstFiscalYear,
    this.controlTypeCode,
    this.mainActivityCode,
    this.socialSecurityNumber,
    this.importerCode,
    this.legalRepresentativeFiscalId,
    this.governanceLeaders,
    this.boardMembers,
    this.applicableNotes,
  });

  static const defaultApplicableNotes =
      'NOTE 2, NOTE 3B, NOTE 3C, NOTE 6, NOTE 7, NOTE 13, NOTE 14, '
      'NOTE 16C, NOTE 19, NOTE 20, NOTE 21, NOTE 22, NOTE 24, NOTE 25, '
      'NOTE 27A, NOTE 27B, NOTE 28, NOTE 30, NOTE 31, NOTE 33, '
      'NOTE 34, NOTE 35, NOTE 36';

  final String? ifu;
  final String? registrationNumber;
  final String? taxCenter;
  final String? depositCenter;
  final String? country;
  final String? headOfficeAddress;
  final String? activityDescription;
  final String? legalRepresentativeName;
  final String? legalRepresentativeTitle;
  final String? legalRepresentativePhone;
  final String? accountantName;
  final String? accountantTitle;
  final String? accountantPhone;
  final String? accountantEmail;
  final String? bankName;
  final String? bankAccountLabel;
  final String? bankAccountNumber;
  final String? legalFormCode;
  final String? taxRegimeCode;
  final String? countryCode;
  final String? establishmentsInCountry;
  final String? establishmentsOutsideCountry;
  final String? firstFiscalYear;
  final String? controlTypeCode;
  final String? mainActivityCode;
  final String? socialSecurityNumber;
  final String? importerCode;
  final String? legalRepresentativeFiscalId;
  final String? governanceLeaders;
  final String? boardMembers;
  final String? applicableNotes;

  factory _RemoteFiscalProfile.fromOrganization(_RemoteOrganization org) {
    final raw = org.parametres?['fiscal_identity'] ?? org.parametres?['fiscal'];
    final data = _mapValue(raw) ?? const <String, dynamic>{};
    return _RemoteFiscalProfile(
      ifu: _read(data, 'ifu'),
      registrationNumber: _read(data, 'registration_number'),
      taxCenter: _read(data, 'tax_center'),
      depositCenter: _read(data, 'deposit_center'),
      country: _read(data, 'country'),
      headOfficeAddress: _read(data, 'head_office_address') ?? org.adresse,
      activityDescription: _read(data, 'activity_description'),
      legalRepresentativeName: _read(data, 'legal_representative_name'),
      legalRepresentativeTitle: _read(data, 'legal_representative_title'),
      legalRepresentativePhone: _read(data, 'legal_representative_phone'),
      accountantName: _read(data, 'accountant_name'),
      accountantTitle: _read(data, 'accountant_title'),
      accountantPhone: _read(data, 'accountant_phone'),
      accountantEmail: _read(data, 'accountant_email'),
      bankName: _read(data, 'bank_name'),
      bankAccountLabel: _read(data, 'bank_account_label'),
      bankAccountNumber: _read(data, 'bank_account_number'),
      legalFormCode: _read(data, 'legal_form_code'),
      taxRegimeCode: _read(data, 'tax_regime_code'),
      countryCode: _read(data, 'country_code'),
      establishmentsInCountry: _read(data, 'establishments_in_country'),
      establishmentsOutsideCountry: _read(
        data,
        'establishments_outside_country',
      ),
      firstFiscalYear: _read(data, 'first_fiscal_year'),
      controlTypeCode: _read(data, 'control_type_code'),
      mainActivityCode: _read(data, 'main_activity_code'),
      socialSecurityNumber: _read(data, 'social_security_number'),
      importerCode: _read(data, 'importer_code'),
      legalRepresentativeFiscalId: _read(
        data,
        'legal_representative_fiscal_id',
      ),
      governanceLeaders: _read(data, 'governance_leaders'),
      boardMembers: _read(data, 'board_members'),
      applicableNotes: _read(data, 'applicable_notes'),
    );
  }

  static String? _read(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

class _RemoteFiscalIdentity {
  const _RemoteFiscalIdentity({
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
    required this.organizationPhone,
    required this.organizationEmail,
    required this.legalFormCode,
    required this.taxRegimeCode,
    required this.countryCode,
    required this.establishmentsInCountry,
    required this.establishmentsOutsideCountry,
    required this.firstFiscalYear,
    required this.controlTypeCode,
    required this.mainActivityCode,
    required this.socialSecurityNumber,
    required this.importerCode,
    required this.legalRepresentativeFiscalId,
    required this.governanceLeaders,
    required this.boardMembers,
    required this.applicableNotes,
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
  final String organizationPhone;
  final String organizationEmail;
  final String legalFormCode;
  final String taxRegimeCode;
  final String countryCode;
  final String establishmentsInCountry;
  final String establishmentsOutsideCountry;
  final String firstFiscalYear;
  final String controlTypeCode;
  final String mainActivityCode;
  final String socialSecurityNumber;
  final String importerCode;
  final String legalRepresentativeFiscalId;
  final String governanceLeaders;
  final String boardMembers;
  final String applicableNotes;
  final String currency;
  final String periodLabel;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime previousPeriodEnd;
  final String perimeterLabel;

  factory _RemoteFiscalIdentity.from({
    required _RemoteOrganization organization,
    required Map<String, dynamic> values,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime previousPeriodEnd,
    ChurchUnit? churchUnit,
  }) {
    final profile = organization.fiscalProfile;
    final orgName = _firstFilled([
      _stringValue(values['org.name']),
      organization.name,
    ]);
    final orgSigle = _firstFilled([
      _stringValue(values['org.sigle']),
      organization.sigle,
    ]);
    final address = _firstFilled([
      _stringValue(values['org.address']),
      profile.headOfficeAddress,
      organization.adresse,
      'Siege a renseigner',
    ]);
    final ifu = _firstFilled([
      _stringValue(values['org.nif']),
      profile.ifu,
      'IFU a renseigner',
    ]);
    final legalRepresentativeName = _firstFilled([
      profile.legalRepresentativeName,
      'Responsable legal a renseigner',
    ]);
    final legalRepresentativeTitle = _firstFilled([
      profile.legalRepresentativeTitle,
      'Representant legal',
    ]);
    final legalRepresentativePhone = _firstFilled([
      profile.legalRepresentativePhone,
      organization.telephone,
      '',
    ]);
    final legalRepresentativeFiscalId = _firstFilled([
      _stringValue(values['responsable.fiscal_id']),
      profile.legalRepresentativeFiscalId,
      '',
    ]);

    return _RemoteFiscalIdentity(
      organizationName: orgName,
      organizationSigle: orgSigle,
      ifu: ifu,
      registrationNumber: _firstFilled([
        profile.registrationNumber,
        'Reference administrative a renseigner',
      ]),
      taxCenter: _firstFilled([
        profile.taxCenter,
        'Centre des impots a renseigner',
      ]),
      depositCenter: _firstFilled([
        profile.depositCenter,
        profile.taxCenter,
        'Centre de depot a renseigner',
      ]),
      country: _firstFilled([profile.country, 'REPUBLIQUE DU BENIN']),
      headOfficeAddress: address,
      activityDescription: _firstFilled([
        profile.activityDescription,
        'Activites cultuelles et communautaires',
      ]),
      legalRepresentativeName: legalRepresentativeName,
      legalRepresentativeTitle: legalRepresentativeTitle,
      legalRepresentativePhone: legalRepresentativePhone,
      accountantName: _firstFilled([
        profile.accountantName,
        'Comptable responsable a renseigner',
      ]),
      accountantTitle: _firstFilled([
        profile.accountantTitle,
        'Comptable responsable',
      ]),
      accountantPhone: _firstFilled([profile.accountantPhone, '']),
      accountantEmail: _firstFilled([
        profile.accountantEmail,
        organization.email,
        '',
      ]),
      bankName: _firstFilled([profile.bankName, 'Banque a renseigner']),
      bankAccountLabel: _firstFilled([
        profile.bankAccountLabel,
        'Compte principal a renseigner',
      ]),
      bankAccountNumber: _firstFilled([
        profile.bankAccountNumber,
        'Numero de compte a renseigner',
      ]),
      organizationPhone: _firstFilled([
        _stringValue(values['org.phone']),
        organization.telephone,
        '',
      ]),
      organizationEmail: _firstFilled([
        _stringValue(values['org.email']),
        organization.email,
        '',
      ]),
      legalFormCode: _firstFilled([
        _stringValue(values['fiscal.legal_form_code']),
        profile.legalFormCode,
        '07',
      ]),
      taxRegimeCode: _firstFilled([
        _stringValue(values['fiscal.tax_regime_code']),
        profile.taxRegimeCode,
        '01',
      ]),
      countryCode: _firstFilled([
        _stringValue(values['fiscal.country_code']),
        profile.countryCode,
        '01',
      ]),
      establishmentsInCountry: _firstFilled([
        _stringValue(values['fiscal.establishments_in_country']),
        profile.establishmentsInCountry,
        '01',
      ]),
      establishmentsOutsideCountry: _firstFilled([
        _stringValue(values['fiscal.establishments_outside_country']),
        profile.establishmentsOutsideCountry,
        '00',
      ]),
      firstFiscalYear: _firstFilled([
        _stringValue(values['fiscal.first_fiscal_year']),
        profile.firstFiscalYear,
        periodStart.year.toString(),
      ]),
      controlTypeCode: _firstFilled([
        _stringValue(values['fiscal.control_type_code']),
        profile.controlTypeCode,
        'private_national',
      ]),
      mainActivityCode: _firstFilled([
        _stringValue(values['fiscal.main_activity_code']),
        profile.mainActivityCode,
        '',
      ]),
      socialSecurityNumber: _firstFilled([
        _stringValue(values['fiscal.social_security_number']),
        profile.socialSecurityNumber,
        '',
      ]),
      importerCode: _firstFilled([
        _stringValue(values['fiscal.importer_code']),
        profile.importerCode,
        '',
      ]),
      legalRepresentativeFiscalId: legalRepresentativeFiscalId,
      governanceLeaders: _firstFilled([
        _stringValue(values['fiscal.governance_leaders']),
        profile.governanceLeaders,
        _joinDelimitedRow([
          legalRepresentativeName,
          legalRepresentativeTitle,
          legalRepresentativeFiscalId,
          address,
        ]),
      ]),
      boardMembers: _firstFilled([
        _stringValue(values['fiscal.board_members']),
        profile.boardMembers,
        '',
      ]),
      applicableNotes: _firstFilled([
        _stringValue(values['fiscal.applicable_notes']),
        profile.applicableNotes,
        _RemoteFiscalProfile.defaultApplicableNotes,
      ]),
      currency: _firstFilled([
        _stringValue(values['currency']),
        organization.devise,
      ]),
      periodLabel: _firstFilled([
        _stringValue(values['exercice.label']),
        'Exercice ${periodEnd.year}',
      ]),
      periodStart: periodStart,
      periodEnd: periodEnd,
      previousPeriodEnd: previousPeriodEnd,
      perimeterLabel: churchUnit == null
          ? 'Perimetre non renseigne'
          : '${churchUnit.typeLabel} - ${churchUnit.nom}',
    );
  }

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
      '_soTelephone': organizationPhone,
      '_soEmail': organizationEmail,
      '_fiscalLegalFormCode': legalFormCode,
      '_fiscalTaxRegimeCode': taxRegimeCode,
      '_fiscalCountryCode': countryCode,
      '_fiscalActivite': activityDescription,
      '_fiscalEstablishmentsInCountry': establishmentsInCountry,
      '_fiscalEstablishmentsOutsideCountry': establishmentsOutsideCountry,
      '_fiscalFirstYear': firstFiscalYear,
      '_fiscalControlTypeCode': controlTypeCode,
      '_fiscalMainActivityCode': mainActivityCode,
      '_fiscalSocialSecurityNumber': socialSecurityNumber,
      '_fiscalImporterCode': importerCode,
      '_fiscalLegalRepresentativeFiscalId': legalRepresentativeFiscalId,
      '_fiscalLegalRepresentativeName': legalRepresentativeName,
      '_fiscalLegalRepresentativeTitle': legalRepresentativeTitle,
      '_fiscalGovernanceLeaders': governanceLeaders,
      '_fiscalBoardMembers': boardMembers,
      '_fiscalApplicableNotes': applicableNotes,
    };
  }

  Map<String, String> textReplacements() {
    final representativeLine = [
      legalRepresentativeName,
      legalRepresentativeTitle,
      if (legalRepresentativePhone.isNotEmpty) 'Tel $legalRepresentativePhone',
    ].join(' ');
    final parts = legalRepresentativeName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final lastName = parts.length > 1 ? parts.first : legalRepresentativeName;
    final firstName = parts.length > 1
        ? parts.skip(1).join(' ')
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
      'AKODA ALIDOU ASSOCIER GERANT T\u00e9l 61218199': representativeLine,
      'AKODA ALIDOU ASSOCIER GERANT ': representativeLine,
      'AKODA ALIDOU ASSOCIER GERANT': representativeLine,
      'AKODA': lastName,
      'ALIDOU': firstName,
      'G\u00e9rant': legalRepresentativeTitle,
      'GERANT': legalRepresentativeTitle,
      'Gerant': legalRepresentativeTitle,
      'Ernest Cyrille A. SOUROU': accountantName,
      'BIIC': bankName,
    };
  }

  static String _firstFilled(List<String?> values) {
    for (final value in values) {
      final clean = value?.trim();
      if (clean != null && clean.isNotEmpty) return clean;
    }
    return '';
  }

  static String _joinDelimitedRow(List<String> values) {
    return values.map((value) => value.trim()).join(' | ');
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static int _monthDuration(DateTime start, DateTime end) {
    final months = (end.year - start.year) * 12 + end.month - start.month + 1;
    return months < 1 ? 1 : months;
  }
}

Map<String, dynamic>? _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

class _SupabaseRestClient {
  const _SupabaseRestClient({
    required this.baseUrl,
    required this.serviceRoleKey,
  });

  final String baseUrl;
  final String serviceRoleKey;

  Future<Map<String, dynamic>> single(
    String table, {
    required String select,
    Map<String, String> filters = const {},
  }) async {
    final rows = await list(table, select: select, filters: filters, limit: 1);
    if (rows.isEmpty) {
      throw StateError('No row found in $table for filters $filters');
    }
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> list(
    String table, {
    required String select,
    Map<String, String> filters = const {},
    int? limit,
    String? order,
  }) async {
    final query = <String, String>{
      'select': _normalizeSelect(select),
      ...filters,
      if (limit != null) 'limit': limit.toString(),
      if (order != null) 'order': order,
    };
    final response = await http
        .get(_uri('/rest/v1/$table', query), headers: _headers)
        .timeout(_networkTimeout);
    _throwIfFailed(response, 'GET $table');
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> rpcList(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          _uri('/rest/v1/rpc/$functionName'),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_networkTimeout);
    _throwIfFailed(response, 'RPC $functionName');
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
    'apikey': serviceRoleKey,
    'Authorization': 'Bearer $serviceRoleKey',
    'Accept': 'application/json',
  };

  void _throwIfFailed(http.Response response, String operation) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw StateError(
      '$operation failed (${response.statusCode}): ${response.body}',
    );
  }

  String _normalizeSelect(String value) {
    return value.split('\n').map((line) => line.trim()).join('');
  }
}
