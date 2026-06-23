import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _eabOrgId = '00000000-0000-0000-0000-000000000001';
const _singleOrgId = '00000000-0000-0000-0000-000000000002';
const _password = 'test123456789';
const _test1Email = 'test1@gmail.com';
const _test2Email = 'test2@gmail.com';
const _defaultTechnicalEmail = 'georgesbusiness54@gmail.com';
const _defaultExpectedProjectRef = 'ddyhwihcnmzqejjtwrbl';
const _timeout = Duration(seconds: 60);

Future<void> main(List<String> args) async {
  final apply = args.contains('--apply');
  final technicalEmail =
      _argValue(args, '--technical-email') ??
      Platform.environment['TECHNICAL_ADMIN_EMAIL'] ??
      _defaultTechnicalEmail;
  final baseUrl = _requiredEnv('SUPABASE_URL').replaceAll(RegExp(r'/$'), '');
  final serviceRoleKey = _requiredEnv('SUPABASE_SERVICE_ROLE_KEY');
  final expectedProjectRef =
      _argValue(args, '--expected-project-ref') ??
      Platform.environment['SUPABASE_EXPECTED_PROJECT_REF'] ??
      _defaultExpectedProjectRef;
  _assertExpectedProject(baseUrl, expectedProjectRef);
  final client = _SupabaseAdminClient(baseUrl, serviceRoleKey);

  final authUsers = await client.listAuthUsers();
  final technicalUser = authUsers
      .where((user) => user.email.toLowerCase() == technicalEmail.toLowerCase())
      .firstOrNull;

  stdout.writeln('Projet Supabase: $baseUrl');
  stdout.writeln('Mode: ${apply ? 'APPLICATION REELLE' : 'DRY-RUN'}');
  stdout.writeln('Compte technique cible: $technicalEmail');
  stdout.writeln(
    technicalUser == null
        ? 'Compte technique introuvable dans Auth: il ne sera pas rattache.'
        : 'Compte technique trouve: ${technicalUser.id}',
  );
  stdout.writeln('Comptes publics a preparer: $_test1Email, $_test2Email');

  final currentOrgs = await client.list(
    'organizations',
    select: 'id,name,sigle,code',
    order: 'name.asc',
  );
  stdout.writeln('Organisations actuelles: ${currentOrgs.length}');
  for (final org in currentOrgs) {
    stdout.writeln(' - ${org['name']} (${org['sigle'] ?? org['code']})');
  }

  if (!apply) {
    stdout.writeln('');
    stdout.writeln('Dry-run uniquement. Relancer avec --apply pour:');
    stdout.writeln(' - supprimer les organisations metier actuelles;');
    stdout.writeln(' - conserver Auth mais nettoyer les profils non demo;');
    stdout.writeln(' - creer EAB multiniveau pour $_test1Email;');
    stdout.writeln(' - creer une eglise unique pour $_test2Email;');
    stdout.writeln(' - rattacher le compte technique a EAB si present.');
    return;
  }

  final test1 = await client.ensureAuthUser(
    email: _test1Email,
    password: _password,
    fullName: 'Administrateur demo EAB',
  );
  final test2 = await client.ensureAuthUser(
    email: _test2Email,
    password: _password,
    fullName: 'Administrateur demo eglise unique',
  );
  final keepProfileIds = {
    test1.id,
    test2.id,
    if (technicalUser != null) technicalUser.id,
  };

  await client.deleteWhere('organizations', {'id': 'not.is.null'});
  if (keepProfileIds.isNotEmpty) {
    await client.deleteWhere('profiles', {
      'id': 'not.in.(${keepProfileIds.join(',')})',
    });
  }

  await client.insert('organizations', _organizations());
  final eabData = _DemoDataBuilder.eab(
    testUserId: test1.id,
    technicalUserId: technicalUser?.id,
  ).build();
  final singleData = _DemoDataBuilder.single(testUserId: test2.id).build();

  for (final group in [eabData, singleData]) {
    await client.insert('church_unit_types', group.unitTypes);
    await client.insert('church_units', group.units);
    await client.upsert('profiles', group.profiles, onConflict: 'id');
    await client.insert('church_unit_user_scopes', group.scopes);
    await client.insert('comptes_comptables', group.accounts);
    await client.insert('journaux_comptables', group.journals);
    await client.insert(
      'church_unit_financial_accounts',
      group.financialAccounts,
    );
    await client.insert('centres_analytiques', group.centers);
    await client.insert('familles', group.families);
    await client.insert('membres', group.members);
    await client.insert('tiers', group.thirdParties);
    await client.insert('programmes', group.programs);
    await client.insert('campagnes_financieres', group.campaigns);
    await client.insert('promesses_financieres', group.pledges);
    await client.insert('mouvements_financiers', group.movements);
    await client.insert('exercices_comptables', group.exercices);
    await client.insert('ecritures_comptables', group.entries);
    await client.insert('lignes_ecritures', group.entryLines);
    await client.insert('releves_bancaires', group.bankStatements);
    await client.insert('lignes_releves_bancaires', group.bankStatementLines);
    await client.insert('budgets_comptables', group.budgets);
    await client.insert('lignes_budgets', group.budgetLines);
    await client.insert('immobilisations_comptables', group.immobilisations);
    await client.insert('rapports_mensuels_eab', group.monthlyReports);
    await _seedFiscalDossier(client, group);
  }

  final afterOrgs = await client.list(
    'organizations',
    select: 'id,name,sigle,code',
    order: 'name.asc',
  );
  final afterProfiles = await client.list(
    'profiles',
    select: 'id,full_name,role,organization_id',
    order: 'full_name.asc',
  );
  stdout.writeln('');
  stdout.writeln('Seed public termine.');
  stdout.writeln('Organisations: ${afterOrgs.length}');
  stdout.writeln('Profils applicatifs: ${afterProfiles.length}');
  stdout.writeln('Connexion test1: $_test1Email / $_password');
  stdout.writeln('Connexion test2: $_test2Email / $_password');
}

Future<void> _seedFiscalDossier(
  _SupabaseAdminClient client,
  _DemoData data,
) async {
  final templateRows = await client.list(
    'fiscal_templates',
    select: 'id,code,is_active',
    filters: {'code': 'eq.SYSCEBNL_2026', 'is_active': 'eq.true'},
    limit: 1,
  );
  if (templateRows.isEmpty) return;
  final templateId = templateRows.first['id'].toString();
  final dossierId = data.orgId == _eabOrgId
      ? '00000000-0000-0000-00df-000000002025'
      : '00000000-0000-0000-00df-000000002026';
  await client.insert('fiscal_dossiers', [
    {
      'id': dossierId,
      'organization_id': data.orgId,
      'church_unit_id': data.rootUnitId,
      'template_id': templateId,
      'exercice_id': data.exerciceId,
      'status': 'in_progress',
      'label': 'Dossier fiscal ${data.sigle} 2025',
      'notes': 'Dossier fiscal de demonstration publique.',
    },
  ]);
  final fiscal = data.fiscalIdentity;
  final values = <Map<String, dynamic>>{
    for (final entry in {
      'org.name': data.name,
      'org.sigle': data.sigle,
      'org.address': data.address,
      'org.nif': fiscal['ifu'],
      'fiscal.registration_number': fiscal['registration_number'],
      'fiscal.tax_center': fiscal['tax_center'],
      'fiscal.deposit_center': fiscal['deposit_center'],
      'fiscal.legal_form_code': fiscal['legal_form_code'],
      'fiscal.tax_regime_code': fiscal['tax_regime_code'],
      'fiscal.country_code': fiscal['country_code'],
      'fiscal.establishments_in_country': fiscal['establishments_in_country'],
      'fiscal.establishments_outside_country':
          fiscal['establishments_outside_country'],
      'fiscal.first_fiscal_year': fiscal['first_fiscal_year'],
      'fiscal.control_type_code': fiscal['control_type_code'],
      'fiscal.main_activity_code': fiscal['main_activity_code'],
      'fiscal.activity_description': fiscal['activity_description'],
      'responsable.nom': fiscal['legal_representative_name'],
      'responsable.qualite': fiscal['legal_representative_title'],
      'responsable.telephone': fiscal['legal_representative_phone'],
      'responsable.fiscal_id': fiscal['legal_representative_fiscal_id'],
      'accountant.name': fiscal['accountant_name'],
      'accountant.title': fiscal['accountant_title'],
      'accountant.phone': fiscal['accountant_phone'],
      'accountant.email': fiscal['accountant_email'],
      'bank.name': fiscal['bank_name'],
      'bank.account_label': fiscal['bank_account_label'],
      'bank.account_number': fiscal['bank_account_number'],
      'fiscal.governance_leaders': fiscal['governance_leaders'],
      'fiscal.board_members': fiscal['board_members'],
      'fiscal.applicable_notes': fiscal['applicable_notes'],
      'currency': 'FCFA',
      'exercice.label': 'Exercice comptable 2025',
      'exercice.date_debut': '2025-01-01',
      'exercice.date_fin': '2025-12-31',
      'perimetre.label': data.name,
    }.entries)
      if ((entry.value ?? '').toString().trim().isNotEmpty)
        {
          'dossier_id': dossierId,
          'organization_id': data.orgId,
          'field_key': entry.key,
          'value': entry.value,
          'source': 'computed',
        },
  }.toList();
  await client.upsert(
    'fiscal_dossier_values',
    values,
    onConflict: 'dossier_id,field_key',
  );
}

List<Map<String, dynamic>> _organizations() {
  return [
    {
      'id': _eabOrgId,
      'name': 'Église Apostolique du Bénin',
      'code': 'EAB-BENIN',
      'sigle': 'EAB',
      'description':
          'Organisation publique de demonstration pour une eglise multiniveau.',
      'adresse': 'Cotonou, Littoral, Benin',
      'telephone': '+229 01 00 00 00 00',
      'email': 'contact.demo.eab@example.com',
      'site_web': 'https://demo.eglisewise.local/eab',
      'devise': 'FCFA',
      'couleur_primaire': '#1B2A4A',
      'couleur_secondaire': '#D4A843',
      'parametres': {
        'demo': true,
        'fiscal_identity': _eabFiscalIdentity(),
        'onboarding': {
          'status': 'complete',
          'completed_steps': ['identity', 'structure', 'fiscal', 'users'],
        },
      },
    },
    {
      'id': _singleOrgId,
      'name': 'Assemblée Lumière de Porto-Novo',
      'code': 'ALPN-DEMO',
      'sigle': 'ALPN',
      'description':
          'Organisation publique de demonstration pour une eglise unique.',
      'adresse': 'Porto-Novo, Oueme, Benin',
      'telephone': '+229 01 00 00 00 20',
      'email': 'contact.demo.alpn@example.com',
      'site_web': 'https://demo.eglisewise.local/alpn',
      'devise': 'FCFA',
      'couleur_primaire': '#173B35',
      'couleur_secondaire': '#C8A24A',
      'parametres': {
        'demo': true,
        'fiscal_identity': _singleFiscalIdentity(),
        'onboarding': {
          'status': 'complete',
          'completed_steps': ['identity', 'structure', 'fiscal', 'users'],
        },
      },
    },
  ];
}

Map<String, String> _eabFiscalIdentity() => {
  'ifu': '3202600000001',
  'registration_number': 'EAB-DEMO-2026-001',
  'tax_center': 'Centre des impots des organisations religieuses - Cotonou',
  'deposit_center': 'Direction generale des impots - Cotonou',
  'country': 'Benin',
  'head_office_address': 'Cotonou, Littoral, Benin',
  'activity_description': 'Activites cultuelles et sociales',
  'legal_representative_name': 'Georges GUIDAN',
  'legal_representative_title': 'Representant legal de demonstration',
  'legal_representative_phone': '+229 01 00 00 00 00',
  'legal_representative_fiscal_id': '3202600000099',
  'accountant_name': 'Comptable Demo EAB',
  'accountant_title': 'Comptable responsable SYSCEBNL',
  'accountant_phone': '+229 01 00 00 00 01',
  'accountant_email': 'comptable.demo.eab@example.com',
  'bank_name': 'Banque Demo Benin',
  'bank_account_label': 'Compte principal de demonstration',
  'bank_account_number': 'BJ66DEMO000000000001',
  'legal_form_code': '07',
  'tax_regime_code': '01',
  'country_code': '01',
  'establishments_in_country': '04',
  'establishments_outside_country': '00',
  'first_fiscal_year': '2025',
  'control_type_code': 'private_national',
  'main_activity_code': '9491',
  'governance_leaders':
      'Georges GUIDAN | Rep. legal | 3202600000099 | Cotonou, Benin\n'
      'Marie HOUNTON | Secretaire generale | 3202600000100 | Porto-Novo, Benin',
  'board_members':
      'Paul KOSSOU | President | Cotonou, Benin\n'
      'Jeanne ADANDE | Membre | Abomey-Calavi, Benin',
  'applicable_notes':
      'NOTE 2, NOTE 3B, NOTE 3C, NOTE 11, NOTE 21, NOTE 22, NOTE 24, NOTE 25, NOTE 30, NOTE 34, NOTE 35, NOTE 36',
};

Map<String, String> _singleFiscalIdentity() => {
  'ifu': '3202600000202',
  'registration_number': 'ALPN-DEMO-2026-001',
  'tax_center': 'Centre des impots de Porto-Novo',
  'deposit_center': 'Direction departementale des impots - Oueme',
  'country': 'Benin',
  'head_office_address': 'Porto-Novo, Oueme, Benin',
  'activity_description': 'Activites cultuelles et sociales',
  'legal_representative_name': 'Mireille AHOUANGAN',
  'legal_representative_title': 'Responsable principale',
  'legal_representative_phone': '+229 01 00 00 00 20',
  'legal_representative_fiscal_id': '3202600000209',
  'accountant_name': 'Samuel HOUESSOU',
  'accountant_title': 'Comptable volontaire',
  'accountant_phone': '+229 01 00 00 00 21',
  'accountant_email': 'comptable.demo.alpn@example.com',
  'bank_name': 'Banque Demo Benin',
  'bank_account_label': 'Compte courant ALPN',
  'bank_account_number': 'BJ66DEMO000000000202',
  'legal_form_code': '07',
  'tax_regime_code': '01',
  'country_code': '01',
  'establishments_in_country': '01',
  'establishments_outside_country': '00',
  'first_fiscal_year': '2025',
  'control_type_code': 'private_national',
  'main_activity_code': '9491',
  'governance_leaders':
      'Mireille AHOUANGAN | Responsable principale | 3202600000209 | Porto-Novo, Benin',
  'board_members': 'Samuel HOUESSOU | Tresorier | Porto-Novo, Benin',
  'applicable_notes':
      'NOTE 2, NOTE 3B, NOTE 3C, NOTE 11, NOTE 21, NOTE 22, NOTE 24, NOTE 25, NOTE 30, NOTE 34, NOTE 35, NOTE 36',
};

class _DemoDataBuilder {
  _DemoDataBuilder._({
    required this.orgId,
    required this.name,
    required this.sigle,
    required this.address,
    required this.adminUserId,
    this.technicalUserId,
    required this.single,
  });

  factory _DemoDataBuilder.eab({
    required String testUserId,
    required String? technicalUserId,
  }) {
    return _DemoDataBuilder._(
      orgId: _eabOrgId,
      name: 'Église Apostolique du Bénin',
      sigle: 'EAB',
      address: 'Cotonou, Littoral, Benin',
      adminUserId: testUserId,
      technicalUserId: technicalUserId,
      single: false,
    );
  }

  factory _DemoDataBuilder.single({required String testUserId}) {
    return _DemoDataBuilder._(
      orgId: _singleOrgId,
      name: 'Assemblée Lumière de Porto-Novo',
      sigle: 'ALPN',
      address: 'Porto-Novo, Oueme, Benin',
      adminUserId: testUserId,
      single: true,
    );
  }

  final String orgId;
  final String name;
  final String sigle;
  final String address;
  final String adminUserId;
  final String? technicalUserId;
  final bool single;

  _DemoData build() {
    final unitTypes = <Map<String, dynamic>>[];
    final units = <Map<String, dynamic>>[];
    final profiles = <Map<String, dynamic>>[];
    final scopes = <Map<String, dynamic>>[];
    final accounts = _accounts();
    final journals = _journals();
    final financialAccounts = <Map<String, dynamic>>[];
    final centers = <Map<String, dynamic>>[];
    final families = <Map<String, dynamic>>[];
    final members = <Map<String, dynamic>>[];
    final thirdParties = <Map<String, dynamic>>[];
    final programs = <Map<String, dynamic>>[];
    final campaigns = <Map<String, dynamic>>[];
    final pledges = <Map<String, dynamic>>[];
    final movements = <Map<String, dynamic>>[];
    final entries = <Map<String, dynamic>>[];
    final entryLines = <Map<String, dynamic>>[];
    final bankStatements = <Map<String, dynamic>>[];
    final bankStatementLines = <Map<String, dynamic>>[];
    final budgets = <Map<String, dynamic>>[];
    final budgetLines = <Map<String, dynamic>>[];
    final immobilisations = <Map<String, dynamic>>[];
    final monthlyReports = <Map<String, dynamic>>[];
    final rootTypeId = _id(single ? '2100' : '1100', 1);
    final localTypeId = _id(single ? '2100' : '1100', single ? 1 : 4);
    final sectionTypeId = _id('1100', 5);
    final rootId = _id(single ? '2200' : '1200', 1);
    final exerciceId = _id(single ? '2a00' : '1a00', 1);

    if (single) {
      unitTypes.add(
        _unitType(rootTypeId, 'eglise_unique', 'Eglise unique', 0, true),
      );
      units.add(
        _unit(rootId, rootTypeId, null, name, 'ALPN-ROOT', 'Porto-Novo'),
      );
    } else {
      unitTypes.addAll([
        _unitType(rootTypeId, 'national', 'National', 0, false),
        _unitType(_id('1100', 2), 'region', 'Region', 1, false),
        _unitType(_id('1100', 3), 'district', 'District', 2, false),
        _unitType(localTypeId, 'assemblee', 'Assemblee', 3, true),
        _unitType(sectionTypeId, 'section', 'Section', 4, true),
      ]);
      units.add(_unit(rootId, rootTypeId, null, name, 'EAB-ROOT', 'Cotonou'));
      var unitIndex = 2;
      final regions = {
        'Littoral': ['Cotonou', 'Akpakpa'],
        'Atlantique': ['Abomey-Calavi', 'Ouidah'],
        'Oueme-Plateau': ['Porto-Novo', 'Sakete'],
        'Borgou-Alibori': ['Parakou', 'Kandi'],
      };
      for (final region in regions.entries) {
        final regionId = _id('1200', unitIndex++);
        units.add(
          _unit(
            regionId,
            _id('1100', 2),
            rootId,
            'Region ${region.key}',
            'REG-${_code(region.key)}',
            region.value.first,
          ),
        );
        for (final district in region.value) {
          final districtId = _id('1200', unitIndex++);
          units.add(
            _unit(
              districtId,
              _id('1100', 3),
              regionId,
              'District de $district',
              'DIS-${_code(district)}',
              district,
            ),
          );
          for (var a = 1; a <= 3; a++) {
            final assemblyId = _id('1200', unitIndex++);
            final assemblyName =
                'Assemblee ${district == 'Cotonou' && a == 1 ? 'Agla' : '$district $a'}';
            units.add(
              _unit(
                assemblyId,
                localTypeId,
                districtId,
                assemblyName,
                'ASS-${_code(district)}-$a',
                district,
              ),
            );
            for (var s = 1; s <= 2; s++) {
              final sectionId = _id('1200', unitIndex++);
              units.add(
                _unit(
                  sectionId,
                  sectionTypeId,
                  assemblyId,
                  'Section $s - $assemblyName',
                  'SEC-${_code(district)}-$a$s',
                  district,
                ),
              );
            }
          }
        }
      }
    }

    profiles.add(
      _profile(
        adminUserId,
        single ? 'Admin demo eglise unique' : 'Admin demo EAB',
        rootId,
      ),
    );
    scopes.add(_scope(adminUserId, rootId));
    if (technicalUserId != null && !single) {
      profiles.add(
        _profile(technicalUserId!, 'Administrateur technique', rootId),
      );
      scopes.add(_scope(technicalUserId!, rootId));
    }

    final localUnits = units
        .where((unit) => unit['type_id'] == (single ? rootTypeId : localTypeId))
        .toList();
    final financeUnits = single
        ? [units.first]
        : [
            units.first,
            ...localUnits,
            ...units.where((unit) => unit['type_id'] == sectionTypeId).take(16),
          ];
    for (var i = 0; i < financeUnits.length; i++) {
      final unit = financeUnits[i];
      financialAccounts.addAll(_financialAccounts(unit['id'] as String, i + 1));
    }
    final demoLocalUnitCount = single ? 1 : localUnits.length;
    for (var i = 0; i < localUnits.length && i < demoLocalUnitCount; i++) {
      final unit = localUnits[i];
      centers.add(
        _center(
          i + 1,
          unit['id'] as String,
          unit['nom'] as String,
          'assemblee_locale',
        ),
      );
      centers.add(
        _center(
          100 + i,
          unit['id'] as String,
          'Projet social ${unit['nom']}',
          'projet',
        ),
      );
      families.add(
        _family(i + 1, unit['id'] as String, 'Famille Demo ${i + 1}'),
      );
      members.addAll(
        _membersForUnit(i, unit['id'] as String, families.last['id'] as String),
      );
      programs.addAll(_programsForUnit(i, unit['id'] as String));
      monthlyReports.add(_monthlyReport(i + 1, unit['id'] as String));
    }
    final primaryLocalUnitId = localUnits.first['id'] as String;
    final primaryUnitFinancialAccounts = financialAccounts
        .where((account) => account['church_unit_id'] == primaryLocalUnitId)
        .toList();
    thirdParties.addAll(_thirdParties());
    campaigns.addAll(
      _campaigns(primaryLocalUnitId, programs.first['id'] as String),
    );
    pledges.addAll(
      _pledges(primaryLocalUnitId, campaigns, members, thirdParties),
    );
    movements.addAll(
      _movements(
        primaryLocalUnitId,
        campaigns,
        pledges,
        members,
        thirdParties,
        primaryUnitFinancialAccounts,
      ),
    );
    entries.addAll(_entries(primaryLocalUnitId));
    entryLines.addAll(_entryLines(centers, thirdParties));
    bankStatements.addAll(_bankStatements(primaryLocalUnitId));
    bankStatementLines.addAll(
      _bankStatementLines(primaryLocalUnitId, primaryUnitFinancialAccounts),
    );
    budgets.addAll(_budgets(primaryLocalUnitId, centers));
    budgetLines.addAll(_budgetLines(budgets));
    immobilisations.addAll(_immobilisations(primaryLocalUnitId, centers));

    return _DemoData(
      orgId: orgId,
      name: name,
      sigle: sigle,
      address: address,
      rootUnitId: rootId,
      exerciceId: exerciceId,
      fiscalIdentity: single ? _singleFiscalIdentity() : _eabFiscalIdentity(),
      unitTypes: unitTypes,
      units: units,
      profiles: profiles,
      scopes: scopes,
      accounts: accounts,
      journals: journals,
      financialAccounts: financialAccounts,
      centers: centers,
      families: families,
      members: members,
      thirdParties: thirdParties,
      programs: programs,
      campaigns: campaigns,
      pledges: pledges,
      movements: movements,
      exercices: [
        {
          'id': exerciceId,
          'organization_id': orgId,
          'annee': 2025,
          'date_debut': '2025-01-01',
          'date_fin': '2025-12-31',
          'libelle': 'Exercice comptable 2025',
          'est_ouvert': true,
          'est_cloture': false,
          'statut': 'ouvert',
        },
      ],
      entries: entries,
      entryLines: entryLines,
      bankStatements: bankStatements,
      bankStatementLines: bankStatementLines,
      budgets: budgets,
      budgetLines: budgetLines,
      immobilisations: immobilisations,
      monthlyReports: monthlyReports,
    );
  }

  Map<String, dynamic> _unitType(
    String id,
    String code,
    String label,
    int order,
    bool local,
  ) {
    return {
      'id': id,
      'organization_id': orgId,
      'code': code,
      'label': label,
      'level_order': order,
      'is_local': local,
      'is_financial_scope': true,
      'can_have_members': local,
      'can_have_cash_accounts': true,
      'can_have_bank_accounts': true,
      'can_have_mobile_money_accounts': true,
      'can_create_programs': true,
      'can_launch_contributions': true,
      'can_validate_finances': !local,
      'can_consolidate_finances': !local,
      'can_notify_descendants': !local,
      'can_view_descendants': true,
    };
  }

  Map<String, dynamic> _unit(
    String id,
    String typeId,
    String? parentId,
    String name,
    String code,
    String city,
  ) {
    return {
      'id': id,
      'organization_id': orgId,
      'type_id': typeId,
      'parent_id': parentId,
      'nom': name,
      'code': code,
      'ville': city,
      'adresse': city,
      'telephone':
          '+229 01 00 00 ${(id.hashCode.abs() % 90 + 10).toString().padLeft(2, '0')}',
      'email': '${code.toLowerCase()}@demo.eglisewise.local',
      'active': true,
      'metadata': {'demo': true},
    };
  }

  Map<String, dynamic> _profile(String userId, String fullName, String rootId) {
    return {
      'id': userId,
      'organization_id': orgId,
      'full_name': fullName,
      'role': 'admin_national',
      'primary_church_unit_id': rootId,
    };
  }

  Map<String, dynamic> _scope(String userId, String rootId) {
    return {
      'id': _stableId('scope', '$orgId$userId'),
      'organization_id': orgId,
      'user_id': userId,
      'unit_id': rootId,
      'role': 'admin_national',
      'can_manage_children': true,
    };
  }

  List<Map<String, dynamic>> _accounts() {
    final rows = [
      ['101', 'Fonds associatifs', 'passif'],
      ['213', 'Batiments cultuels', 'actif'],
      ['2183', 'Materiel et mobilier', 'actif'],
      ['2813', 'Amortissement batiments', 'passif'],
      ['401', 'Fournisseurs', 'passif'],
      ['411', 'Membres et adherents', 'actif'],
      ['5121', 'Banque - compte principal', 'actif'],
      ['531', 'Caisse', 'actif'],
      ['613', 'Locations et charges locatives', 'charge'],
      ['615', 'Entretien et reparations', 'charge'],
      ['645', 'Aides et actions sociales', 'charge'],
      ['701', 'Dimes', 'produit'],
      ['702', 'Offrandes', 'produit'],
      ['706', 'Dons et liberalites', 'produit'],
      ['758', 'Autres produits', 'produit'],
    ];
    return [
      for (var i = 0; i < rows.length; i++)
        {
          'id': _id(single ? '2600' : '1600', i + 1),
          'organization_id': orgId,
          'numero': rows[i][0],
          'intitule': rows[i][1],
          'nature': rows[i][2],
          'niveau': rows[i][0].length,
          'actif': true,
        },
    ];
  }

  List<Map<String, dynamic>> _journals() => [
    {
      'id': _id(single ? '2700' : '1700', 1),
      'organization_id': orgId,
      'code': 'CAI',
      'intitule': 'Journal de caisse',
      'type': 'caisse',
      'actif': true,
    },
    {
      'id': _id(single ? '2700' : '1700', 2),
      'organization_id': orgId,
      'code': 'BAN',
      'intitule': 'Journal de banque',
      'type': 'banque',
      'actif': true,
    },
    {
      'id': _id(single ? '2700' : '1700', 3),
      'organization_id': orgId,
      'code': 'OD',
      'intitule': 'Operations diverses',
      'type': 'operations_diverses',
      'actif': true,
    },
  ];

  List<Map<String, dynamic>> _financialAccounts(String unitId, int index) => [
    {
      'id': _id(single ? '2800' : '1800', index * 10 + 1),
      'organization_id': orgId,
      'church_unit_id': unitId,
      'type': 'cash',
      'label': 'Caisse principale',
      'provider': null,
      'account_number': null,
      'phone_number': null,
      'currency': 'FCFA',
      'opening_balance': 0,
      'journal_id': _id(single ? '2700' : '1700', 1),
      'comptable_account_id': _id(single ? '2600' : '1600', 8),
      'active': true,
    },
    {
      'id': _id(single ? '2800' : '1800', index * 10 + 2),
      'organization_id': orgId,
      'church_unit_id': unitId,
      'type': 'bank',
      'label': 'Banque - compte principal',
      'provider': null,
      'account_number': 'BJ66DEMO${index.toString().padLeft(8, '0')}',
      'phone_number': null,
      'currency': 'FCFA',
      'opening_balance': 0,
      'journal_id': _id(single ? '2700' : '1700', 2),
      'comptable_account_id': _id(single ? '2600' : '1600', 7),
      'active': true,
    },
    {
      'id': _id(single ? '2800' : '1800', index * 10 + 3),
      'organization_id': orgId,
      'church_unit_id': unitId,
      'type': 'mobile_money',
      'label': 'Mobile Money MTN',
      'provider': 'MTN',
      'account_number': null,
      'phone_number': '+229 61 00 00 ${index.toString().padLeft(2, '0')}',
      'currency': 'FCFA',
      'opening_balance': 0,
      'journal_id': _id(single ? '2700' : '1700', 1),
      'comptable_account_id': _id(single ? '2600' : '1600', 8),
      'active': true,
    },
  ];

  Map<String, dynamic> _center(
    int index,
    String unitId,
    String label,
    String type,
  ) => {
    'id': _id(single ? '2900' : '1900', index),
    'organization_id': orgId,
    'church_unit_id': unitId,
    'code': 'CA-${index.toString().padLeft(3, '0')}',
    'nom': label,
    'type': type,
    'description': 'Centre analytique demo',
    'actif': true,
  };

  Map<String, dynamic> _family(int index, String unitId, String label) => {
    'id': _id(single ? '2b00' : '1b00', index),
    'organization_id': orgId,
    'church_unit_id': unitId,
    'nom': label,
  };

  List<Map<String, dynamic>> _membersForUnit(
    int unitIndex,
    String unitId,
    String familyId,
  ) {
    final names = [
      ['Jean', 'AHOUANDJINOU', 'male', 'pasteur'],
      ['Mireille', 'DOSSOU', 'female', 'diaconesse'],
      ['Samuel', 'HOUNTON', 'male', 'diacre'],
      ['Clarisse', 'KOSSOU', 'female', 'membre'],
      ['Aristide', 'SOSSOU', 'male', 'membre'],
      ['Grace', 'ADANDE', 'female', 'membre'],
    ];
    return [
      for (var i = 0; i < (single ? 6 : 4); i++)
        {
          'id': _id(single ? '2c00' : '1c00', unitIndex * 10 + i + 1),
          'organization_id': orgId,
          'church_unit_id': unitId,
          'id_famille': i < 2 ? familyId : null,
          'full_name': '${names[i][0]} ${names[i][1]}',
          'gender': names[i][2],
          'date_naissance': '${1975 + i}-0${(i % 9) + 1}-15',
          'phone':
              '+229 61 00 ${unitIndex.toString().padLeft(2, '0')} ${i.toString().padLeft(2, '0')}',
          'email': '${names[i][0]}.${names[i][1]}.$unitIndex@example.com'
              .toLowerCase(),
          'address': address,
          'statut_matrimonial': i < 2 ? 'marie' : 'celibataire',
          'date_conversion': '2020-01-15',
          'date_bapteme': '2021-03-20',
          'statut': 'actif',
          'role': names[i][3],
          'date_entree': '2022-01-01',
        },
    ];
  }

  List<Map<String, dynamic>> _programsForUnit(int unitIndex, String unitId) => [
    {
      'id': _id(single ? '2d00' : '1d00', unitIndex * 10 + 1),
      'organization_id': orgId,
      'church_unit_id': unitId,
      'type': 'culte',
      'date': '2025-03-02',
      'location': 'Temple principal',
      'description': 'Culte dominical de demonstration',
      'nombre_hommes': 42 + unitIndex,
      'nombre_femmes': 58 + unitIndex,
      'nombre_garcons': 12,
      'nombre_filles': 15,
      'conversions_hommes': 1,
      'conversions_femmes': 2,
      'nombre_classes_ecole_dimanche': 0,
      'nombre_moniteurs_hommes': 0,
      'nombre_monitrices_femmes': 0,
      'derniere_lecon_ecole_dimanche': null,
    },
    {
      'id': _id(single ? '2d00' : '1d00', unitIndex * 10 + 2),
      'organization_id': orgId,
      'church_unit_id': unitId,
      'type': 'reunion_priere',
      'date': '2025-03-05',
      'location': 'Salle de priere',
      'description': 'Reunion de priere hebdomadaire',
      'nombre_hommes': 18,
      'nombre_femmes': 26,
      'nombre_garcons': 4,
      'nombre_filles': 5,
      'conversions_hommes': 0,
      'conversions_femmes': 0,
      'nombre_classes_ecole_dimanche': 0,
      'nombre_moniteurs_hommes': 0,
      'nombre_monitrices_femmes': 0,
      'derniere_lecon_ecole_dimanche': null,
    },
    {
      'id': _id(single ? '2d00' : '1d00', unitIndex * 10 + 3),
      'organization_id': orgId,
      'church_unit_id': unitId,
      'type': 'sainte_cene',
      'date': '2025-03-09',
      'location': 'Temple principal',
      'description': 'Sainte cene mensuelle avec suivi pastoral',
      'nombre_hommes': 38 + unitIndex,
      'nombre_femmes': 54 + unitIndex,
      'nombre_garcons': 10,
      'nombre_filles': 13,
      'conversions_hommes': 0,
      'conversions_femmes': 1,
      'nombre_classes_ecole_dimanche': 0,
      'nombre_moniteurs_hommes': 0,
      'nombre_monitrices_femmes': 0,
      'derniere_lecon_ecole_dimanche': null,
    },
    {
      'id': _id(single ? '2d00' : '1d00', unitIndex * 10 + 4),
      'organization_id': orgId,
      'church_unit_id': unitId,
      'type': 'ecole_du_dimanche',
      'date': '2025-03-16',
      'location': 'Salle enfance',
      'description': 'Ecole du dimanche et suivi des enfants',
      'nombre_hommes': 4,
      'nombre_femmes': 6,
      'nombre_garcons': 28,
      'nombre_filles': 31,
      'conversions_hommes': 0,
      'conversions_femmes': 0,
      'nombre_classes_ecole_dimanche': 3,
      'nombre_moniteurs_hommes': 2,
      'nombre_monitrices_femmes': 3,
      'derniere_lecon_ecole_dimanche': 'La generosite et le service',
    },
  ];

  List<Map<String, dynamic>> _thirdParties() => [
    {
      'id': _id(single ? '2e00' : '1e00', 1),
      'organization_id': orgId,
      'church_unit_id': null,
      'nom': 'Fournisseur Demo Services',
      'type': 'fournisseur',
      'telephone': '+229 97 00 00 00',
      'email': 'fournisseur.demo@example.com',
      'adresse': address,
    },
    {
      'id': _id(single ? '2e00' : '1e00', 2),
      'organization_id': orgId,
      'church_unit_id': null,
      'nom': 'Partenaire Mission Solidarite',
      'type': 'partenaire',
      'telephone': '+229 95 00 00 02',
      'email': 'solidarite.demo@example.com',
      'adresse': address,
    },
    {
      'id': _id(single ? '2e00' : '1e00', 3),
      'organization_id': orgId,
      'church_unit_id': null,
      'nom': 'Bailleur Demo Diaspora',
      'type': 'bailleur',
      'telephone': '+229 96 00 00 03',
      'email': 'diaspora.demo@example.com',
      'adresse': address,
    },
  ];

  List<Map<String, dynamic>> _campaigns(String unitId, String programId) => [
    {
      'id': _id(single ? '2f00' : '1f00', 1),
      'organization_id': orgId,
      'church_unit_id': unitId,
      'programme_id': programId,
      'titre': 'Cotisation renovation temple',
      'type': 'projet',
      'description':
          'Campagne publique de demonstration avec promesses et paiements.',
      'objectif_montant': 1500000,
      'date_debut': '2025-03-01',
      'date_fin': '2025-06-30',
      'periodicite': 'mensuelle',
      'statut': 'active',
      'allow_partial_payments': true,
    },
    {
      'id': _id(single ? '2f00' : '1f00', 2),
      'organization_id': orgId,
      'church_unit_id': unitId,
      'programme_id': null,
      'titre': 'Soutien scolaire des orphelins',
      'type': 'cotisation',
      'description':
          'Cotisation trimestrielle pour kits scolaires, suivi social et accompagnement.',
      'objectif_montant': 850000,
      'date_debut': '2025-02-01',
      'date_fin': '2025-04-30',
      'periodicite': 'trimestrielle',
      'statut': 'active',
      'allow_partial_payments': true,
    },
    {
      'id': _id(single ? '2f00' : '1f00', 3),
      'organization_id': orgId,
      'church_unit_id': unitId,
      'programme_id': null,
      'titre': 'Conference jeunesse regionale',
      'type': 'activite',
      'description':
          'Activite ponctuelle avec inscriptions, promesses et depenses logistiques.',
      'objectif_montant': 1200000,
      'date_debut': '2025-05-01',
      'date_fin': '2025-05-31',
      'periodicite': 'ponctuelle',
      'statut': 'brouillon',
      'allow_partial_payments': true,
    },
  ];

  List<Map<String, dynamic>> _pledges(
    String unitId,
    List<Map<String, dynamic>> campaigns,
    List<Map<String, dynamic>> members,
    List<Map<String, dynamic>> thirdParties,
  ) => [
    {
      'id': _id(single ? '2f10' : '1f10', 1),
      'organization_id': orgId,
      'campagne_id': campaigns[0]['id'],
      'church_unit_id': unitId,
      'membre_id': members[0]['id'],
      'tiers_id': null,
      'contributeur_nom': null,
      'montant_promis': 150000,
      'date_promesse': '2025-03-03',
      'date_echeance': '2025-05-30',
      'statut': 'partielle',
      'notes': 'Promesse demo avec versement partiel.',
    },
    {
      'id': _id(single ? '2f10' : '1f10', 2),
      'organization_id': orgId,
      'campagne_id': campaigns[0]['id'],
      'church_unit_id': unitId,
      'membre_id': members[1]['id'],
      'tiers_id': null,
      'contributeur_nom': null,
      'montant_promis': 250000,
      'date_promesse': '2025-03-04',
      'date_echeance': '2025-06-15',
      'statut': 'ouverte',
      'notes': 'Promesse attendue pour la renovation.',
    },
    {
      'id': _id(single ? '2f10' : '1f10', 3),
      'organization_id': orgId,
      'campagne_id': campaigns[1]['id'],
      'church_unit_id': unitId,
      'membre_id': members[2]['id'],
      'tiers_id': null,
      'contributeur_nom': null,
      'montant_promis': 60000,
      'date_promesse': '2025-02-05',
      'date_echeance': '2025-03-31',
      'statut': 'reglee',
      'notes': 'Cotisation soldee pour les kits scolaires.',
    },
    {
      'id': _id(single ? '2f10' : '1f10', 4),
      'organization_id': orgId,
      'campagne_id': campaigns[1]['id'],
      'church_unit_id': unitId,
      'membre_id': null,
      'tiers_id': thirdParties[1]['id'],
      'contributeur_nom': null,
      'montant_promis': 300000,
      'date_promesse': '2025-02-12',
      'date_echeance': '2025-04-15',
      'statut': 'partielle',
      'notes': 'Appui partenaire pour le volet social.',
    },
    {
      'id': _id(single ? '2f10' : '1f10', 5),
      'organization_id': orgId,
      'campagne_id': campaigns[2]['id'],
      'church_unit_id': unitId,
      'membre_id': null,
      'tiers_id': thirdParties[2]['id'],
      'contributeur_nom': 'Collectif diaspora demo',
      'montant_promis': 500000,
      'date_promesse': '2025-05-02',
      'date_echeance': '2025-05-25',
      'statut': 'ouverte',
      'notes': 'Promesse de don pour la conference jeunesse.',
    },
  ];

  List<Map<String, dynamic>> _movements(
    String unitId,
    List<Map<String, dynamic>> campaigns,
    List<Map<String, dynamic>> pledges,
    List<Map<String, dynamic>> members,
    List<Map<String, dynamic>> thirdParties,
    List<Map<String, dynamic>> financialAccounts,
  ) {
    final cashAccountId = financialAccounts
        .firstWhere((account) => account['type'] == 'cash')['id']
        .toString();
    final bankAccountId = financialAccounts
        .firstWhere((account) => account['type'] == 'bank')['id']
        .toString();
    final momoAccountId = financialAccounts
        .firstWhere((account) => account['type'] == 'mobile_money')['id']
        .toString();
    return [
      {
        'id': _id(single ? '2f20' : '1f20', 1),
        'organization_id': orgId,
        'church_unit_id': unitId,
        'financial_account_id': cashAccountId,
        'campagne_id': campaigns[0]['id'],
        'programme_id': null,
        'promesse_id': pledges[0]['id'],
        'membre_id': members[0]['id'],
        'tiers_id': null,
        'contributeur_nom': null,
        'type': 'encaissement',
        'montant': 75000,
        'date_mouvement': '2025-03-10',
        'libelle': 'Versement partiel cotisation renovation',
        'mode_paiement': 'especes',
        'reference_externe': 'REC-COT-001',
        'piece_justificative_url': null,
        'statut': 'valide',
        'submitted_at': null,
        'validated_at': '2025-03-10T12:00:00Z',
        'rejet_motif': null,
        'ecriture_id': null,
      },
      {
        'id': _id(single ? '2f20' : '1f20', 2),
        'organization_id': orgId,
        'church_unit_id': unitId,
        'financial_account_id': bankAccountId,
        'campagne_id': campaigns[1]['id'],
        'programme_id': null,
        'promesse_id': pledges[2]['id'],
        'membre_id': members[2]['id'],
        'tiers_id': null,
        'contributeur_nom': null,
        'type': 'encaissement',
        'montant': 60000,
        'date_mouvement': '2025-02-20',
        'libelle': 'Cotisation soldee soutien scolaire',
        'mode_paiement': 'virement_bancaire',
        'reference_externe': 'VIR-SOC-001',
        'piece_justificative_url': null,
        'statut': 'valide',
        'submitted_at': null,
        'validated_at': '2025-02-20T12:00:00Z',
        'rejet_motif': null,
        'ecriture_id': null,
      },
      {
        'id': _id(single ? '2f20' : '1f20', 3),
        'organization_id': orgId,
        'church_unit_id': unitId,
        'financial_account_id': momoAccountId,
        'campagne_id': campaigns[1]['id'],
        'programme_id': null,
        'promesse_id': pledges[3]['id'],
        'membre_id': null,
        'tiers_id': thirdParties[1]['id'],
        'contributeur_nom': null,
        'type': 'encaissement',
        'montant': 120000,
        'date_mouvement': '2025-03-01',
        'libelle': 'Appui partenaire via Mobile Money',
        'mode_paiement': 'mobile_money',
        'reference_externe': 'MTN-SOC-001',
        'piece_justificative_url': null,
        'statut': 'soumis',
        'submitted_at': '2025-03-01T09:00:00Z',
        'validated_at': null,
        'rejet_motif': null,
        'ecriture_id': null,
      },
      {
        'id': _id(single ? '2f20' : '1f20', 4),
        'organization_id': orgId,
        'church_unit_id': unitId,
        'financial_account_id': cashAccountId,
        'campagne_id': campaigns[1]['id'],
        'programme_id': null,
        'promesse_id': null,
        'membre_id': null,
        'tiers_id': thirdParties[0]['id'],
        'contributeur_nom': null,
        'type': 'decaissement',
        'montant': 85000,
        'date_mouvement': '2025-03-12',
        'libelle': 'Achat kits scolaires orphelins',
        'mode_paiement': 'especes',
        'reference_externe': 'DEP-SOC-001',
        'piece_justificative_url': null,
        'statut': 'valide',
        'submitted_at': null,
        'validated_at': '2025-03-12T12:00:00Z',
        'rejet_motif': null,
        'ecriture_id': null,
      },
      {
        'id': _id(single ? '2f20' : '1f20', 5),
        'organization_id': orgId,
        'church_unit_id': unitId,
        'financial_account_id': momoAccountId,
        'campagne_id': campaigns[2]['id'],
        'programme_id': null,
        'promesse_id': pledges[4]['id'],
        'membre_id': null,
        'tiers_id': thirdParties[2]['id'],
        'contributeur_nom': 'Collectif diaspora demo',
        'type': 'encaissement',
        'montant': 200000,
        'date_mouvement': '2025-05-06',
        'libelle': 'Avance diaspora conference jeunesse',
        'mode_paiement': 'mobile_money',
        'reference_externe': 'MOMO-JEUNES-001',
        'piece_justificative_url': null,
        'statut': 'brouillon',
        'submitted_at': null,
        'validated_at': null,
        'rejet_motif': null,
        'ecriture_id': null,
      },
      {
        'id': _id(single ? '2f20' : '1f20', 6),
        'organization_id': orgId,
        'church_unit_id': unitId,
        'financial_account_id': cashAccountId,
        'campagne_id': campaigns[0]['id'],
        'programme_id': null,
        'promesse_id': pledges[1]['id'],
        'membre_id': members[1]['id'],
        'tiers_id': null,
        'contributeur_nom': null,
        'type': 'encaissement',
        'montant': 25000,
        'date_mouvement': '2025-03-18',
        'libelle': 'Versement refuse pour reference incomplete',
        'mode_paiement': 'especes',
        'reference_externe': 'REC-COT-002',
        'piece_justificative_url': null,
        'statut': 'rejete',
        'submitted_at': null,
        'validated_at': null,
        'rejet_motif': 'Reference de piece a completer avant validation.',
        'ecriture_id': null,
      },
    ];
  }

  List<Map<String, dynamic>> _bankStatements(String unitId) => [
    {
      'id': _id(single ? '2f25' : '1f25', 1),
      'organization_id': orgId,
      'church_unit_id': unitId,
      'id_journal_banque': _id(single ? '2700' : '1700', 2),
      'date_releve': '2025-03-31',
      'solde_initial': 0,
      'solde_final': -480000,
      'fichier_url': null,
    },
  ];

  List<Map<String, dynamic>> _bankStatementLines(
    String unitId,
    List<Map<String, dynamic>> financialAccounts,
  ) {
    final bankFinancialAccount = financialAccounts.firstWhere(
      (account) => account['type'] == 'bank',
    );
    final bankFinancialAccountId = bankFinancialAccount['id'].toString();
    final bankComptableAccountId = bankFinancialAccount['comptable_account_id']
        .toString();
    final statementId = _id(single ? '2f25' : '1f25', 1);
    final specs = [
      [
        1,
        '2025-03-04',
        'Dimes recues par virement bancaire',
        820000,
        820000,
        'VIR-DIM-001',
        true,
        2,
      ],
      [
        2,
        '2025-03-12',
        'Reglement location salle de formation',
        -95000,
        725000,
        'VIR-LOC-001',
        true,
        6,
      ],
      [
        3,
        '2025-03-15',
        'Reglement travaux batiment principal',
        -1200000,
        -475000,
        'VIR-BAT-001',
        true,
        7,
      ],
      [
        4,
        '2025-03-31',
        'Frais bancaires non encore comptabilises',
        -5000,
        -480000,
        'FRAIS-BQ-001',
        false,
        null,
      ],
    ];

    return [
      for (final spec in specs)
        {
          'id': _id(single ? '2f26' : '1f26', spec[0] as int),
          'organization_id': orgId,
          'releve_id': statementId,
          'church_unit_id': unitId,
          'id_compte_banque': bankComptableAccountId,
          'financial_account_id': bankFinancialAccountId,
          'date_operation': spec[1],
          'libelle': spec[2],
          'montant': spec[3],
          'solde_apres_operation': spec[4],
          'reference_operation': spec[5],
          'est_pointe': spec[6],
          'id_ecriture_comptable_liee': spec[7] == null
              ? null
              : _id(single ? '2f30' : '1f30', spec[7] as int),
        },
    ];
  }

  List<Map<String, dynamic>> _entries(String unitId) {
    final cashJournalId = _id(single ? '2700' : '1700', 1);
    final bankJournalId = _id(single ? '2700' : '1700', 2);
    return [
      _entry(
        1,
        unitId,
        cashJournalId,
        '2025-03-02',
        'REC-DEMO-001',
        'Offrandes du culte dominical',
      ),
      _entry(
        2,
        unitId,
        bankJournalId,
        '2025-03-04',
        'REC-DEMO-002',
        'Dimes recues par banque',
      ),
      _entry(
        3,
        unitId,
        cashJournalId,
        '2025-03-05',
        'REC-DEMO-003',
        'Don affecte action sociale',
      ),
      _entry(
        4,
        unitId,
        cashJournalId,
        '2025-03-08',
        'DEP-DEMO-001',
        'Travaux entretien du temple',
      ),
      _entry(
        5,
        unitId,
        cashJournalId,
        '2025-03-10',
        'DEP-DEMO-002',
        'Aide sociale a une famille',
      ),
      _entry(
        6,
        unitId,
        bankJournalId,
        '2025-03-12',
        'DEP-DEMO-003',
        'Location salle de formation',
      ),
      _entry(
        7,
        unitId,
        bankJournalId,
        '2025-03-15',
        'IMMO-DEMO-001',
        'Travaux batiment principal',
      ),
      _entry(
        8,
        unitId,
        _id(single ? '2700' : '1700', 3),
        '2025-03-18',
        'IMMO-DEMO-002',
        'Acquisition mobilier a credit',
      ),
    ];
  }

  Map<String, dynamic> _entry(
    int index,
    String unitId,
    String journalId,
    String date,
    String reference,
    String label,
  ) => {
    'id': _id(single ? '2f30' : '1f30', index),
    'organization_id': orgId,
    'church_unit_id': unitId,
    'id_journal': journalId,
    'date': date,
    'reference_piece': reference,
    'libelle': label,
    'statut': 'validee',
    'validated_at': '${date}T12:00:00Z',
  };

  List<Map<String, dynamic>> _entryLines(
    List<Map<String, dynamic>> centers,
    List<Map<String, dynamic>> thirdParties,
  ) {
    final centerId = centers.first['id'] as String;
    final projectCenterId = centers.length > 1
        ? centers[1]['id'] as String
        : centers.first['id'] as String;
    final fournisseurId = thirdParties.first['id'] as String;
    final partenaireId = thirdParties[1]['id'] as String;
    final lineSpecs = [
      [
        1,
        1,
        8,
        'Encaissement caisse offrandes',
        450000,
        0,
        'especes',
        centerId,
        null,
      ],
      [2, 1, 13, 'Offrandes culte', 0, 450000, null, centerId, null],
      [
        3,
        2,
        7,
        'Depot bancaire dimes',
        820000,
        0,
        'virement_bancaire',
        centerId,
        null,
      ],
      [4, 2, 12, 'Dimes du mois', 0, 820000, null, centerId, null],
      [
        5,
        3,
        8,
        'Don encaisse pour action sociale',
        300000,
        0,
        'especes',
        projectCenterId,
        partenaireId,
      ],
      [
        6,
        3,
        14,
        'Dons et liberalites affectes',
        0,
        300000,
        null,
        projectCenterId,
        partenaireId,
      ],
      [
        7,
        4,
        10,
        'Entretien et reparations temple',
        180000,
        0,
        null,
        centerId,
        fournisseurId,
      ],
      [
        8,
        4,
        8,
        'Sortie caisse entretien',
        0,
        180000,
        'especes',
        centerId,
        fournisseurId,
      ],
      [
        9,
        5,
        11,
        'Aide et action sociale',
        125000,
        0,
        null,
        projectCenterId,
        null,
      ],
      [
        10,
        5,
        8,
        'Sortie caisse aide sociale',
        0,
        125000,
        'especes',
        projectCenterId,
        null,
      ],
      [
        11,
        6,
        9,
        'Location salle de formation',
        95000,
        0,
        null,
        centerId,
        fournisseurId,
      ],
      [
        12,
        6,
        7,
        'Reglement banque location',
        0,
        95000,
        'virement_bancaire',
        centerId,
        fournisseurId,
      ],
      [
        13,
        7,
        2,
        'Immobilisation batiment',
        1200000,
        0,
        null,
        centerId,
        fournisseurId,
      ],
      [
        14,
        7,
        7,
        'Reglement banque travaux batiment',
        0,
        1200000,
        'virement_bancaire',
        centerId,
        fournisseurId,
      ],
      [15, 8, 3, 'Mobilier temple', 350000, 0, null, centerId, fournisseurId],
      [
        16,
        8,
        5,
        'Dette fournisseur mobilier',
        0,
        350000,
        null,
        centerId,
        fournisseurId,
      ],
    ];
    return [
      for (final spec in lineSpecs)
        {
          'id': _id(single ? '2f40' : '1f40', spec[0] as int),
          'id_ecriture': _id(single ? '2f30' : '1f30', spec[1] as int),
          'id_compte_comptable': _id(single ? '2600' : '1600', spec[2] as int),
          'id_centre_analytique': spec[7],
          'id_tiers': spec[8],
          'libelle': spec[3],
          'debit': spec[4],
          'credit': spec[5],
          'mode_paiement': spec[6],
        },
    ];
  }

  List<Map<String, dynamic>> _budgets(
    String unitId,
    List<Map<String, dynamic>> centers,
  ) {
    final selectedCenters = centers.take(3).toList();
    return [
      for (var i = 0; i < selectedCenters.length; i++)
        {
          'id': _id(single ? '2f50' : '1f50', i + 1),
          'organization_id': orgId,
          'church_unit_id': unitId,
          'id_centre_analytique': selectedCenters[i]['id'],
          'exercice': 2025,
          'libelle': i == 0
              ? 'Budget fonctionnement assemblee 2025'
              : 'Budget ${selectedCenters[i]['nom']} 2025',
          'est_verrouille': false,
        },
    ];
  }

  List<Map<String, dynamic>> _budgetLines(List<Map<String, dynamic>> budgets) {
    final lines = <Map<String, dynamic>>[];
    for (var i = 0; i < budgets.length; i++) {
      final budgetId = budgets[i]['id'];
      lines.addAll([
        {
          'id': _id(single ? '2f60' : '1f60', i * 3 + 1),
          'id_budget': budgetId,
          'id_compte_comptable': _id(single ? '2600' : '1600', 9),
          'montant_prevu': i == 0 ? 600000 : 250000,
          'montant_revu': i == 0 ? 650000 : null,
        },
        {
          'id': _id(single ? '2f60' : '1f60', i * 3 + 2),
          'id_budget': budgetId,
          'id_compte_comptable': _id(single ? '2600' : '1600', 10),
          'montant_prevu': i == 0 ? 900000 : 300000,
          'montant_revu': null,
        },
        {
          'id': _id(single ? '2f60' : '1f60', i * 3 + 3),
          'id_budget': budgetId,
          'id_compte_comptable': _id(
            single ? '2600' : '1600',
            i == 0 ? 13 : 14,
          ),
          'montant_prevu': i == 0 ? 4200000 : 1200000,
          'montant_revu': i == 0 ? 4500000 : null,
        },
      ]);
    }
    return lines;
  }

  List<Map<String, dynamic>> _immobilisations(
    String unitId,
    List<Map<String, dynamic>> centers,
  ) {
    final centerId = centers.first['id'] as String;
    final rows = [
      ['Batiment principal demo', 'batiment', '2022-01-15', 4500000, 25, 2, 4],
      ['Bancs et mobilier temple', 'mobilier', '2024-03-10', 650000, 8, 3, 4],
      [
        'Vehicule mission pastorale',
        'vehicule',
        '2023-07-20',
        3200000,
        5,
        3,
        4,
      ],
      ['Groupe electrogene demo', 'autre', '2025-02-01', 900000, 6, 3, 4],
    ];
    return [
      for (var i = 0; i < rows.length; i++)
        {
          'id': _id(single ? '2f80' : '1f80', i + 1),
          'organization_id': orgId,
          'church_unit_id': unitId,
          'id_centre_analytique': centerId,
          'libelle': rows[i][0],
          'type': rows[i][1],
          'date_acquisition': rows[i][2],
          'valeur_acquisition': rows[i][3],
          'valeur_residuelle': 0,
          'duree_utilite_en_annees': rows[i][4],
          'id_compte_immobilisation': _id(
            single ? '2600' : '1600',
            rows[i][5] as int,
          ),
          'id_compte_amortissement': _id(
            single ? '2600' : '1600',
            rows[i][6] as int,
          ),
          'id_compte_dotation': null,
          'est_sortie': false,
        },
    ];
  }

  Map<String, dynamic> _monthlyReport(int index, String unitId) => {
    'id': _id(single ? '2f70' : '1f70', index),
    'organization_id': orgId,
    'church_unit_id': unitId,
    'annee': 2025,
    'mois': 3,
    'stats_membres': {
      'total': 42 + index,
      'hommes': 20,
      'femmes': 22,
      'nouveaux': 2,
      'baptises': 1,
    },
    'stats_activites': {
      'cultes': 4,
      'reunions_priere': 4,
      'evangelisations': 1,
      'total_presents': 520,
    },
    'stats_finances': {
      'dimes': 250000,
      'offrandes': 300000,
      'dons': 75000,
      'charges': 50000,
    },
    'resume_activites':
        'Mois de demonstration avec cultes, prieres et suivi pastoral.',
    'projets_realisations': 'Campagne de renovation et action sociale.',
    'projets_mois_suivant': 'Preparation du rapport trimestriel.',
    'observations': 'Donnees fictives pour demonstration publique.',
  };
}

class _DemoData {
  const _DemoData({
    required this.orgId,
    required this.name,
    required this.sigle,
    required this.address,
    required this.rootUnitId,
    required this.exerciceId,
    required this.fiscalIdentity,
    required this.unitTypes,
    required this.units,
    required this.profiles,
    required this.scopes,
    required this.accounts,
    required this.journals,
    required this.financialAccounts,
    required this.centers,
    required this.families,
    required this.members,
    required this.thirdParties,
    required this.programs,
    required this.campaigns,
    required this.pledges,
    required this.movements,
    required this.exercices,
    required this.entries,
    required this.entryLines,
    required this.bankStatements,
    required this.bankStatementLines,
    required this.budgets,
    required this.budgetLines,
    required this.immobilisations,
    required this.monthlyReports,
  });

  final String orgId;
  final String name;
  final String sigle;
  final String address;
  final String rootUnitId;
  final String exerciceId;
  final Map<String, String> fiscalIdentity;
  final List<Map<String, dynamic>> unitTypes;
  final List<Map<String, dynamic>> units;
  final List<Map<String, dynamic>> profiles;
  final List<Map<String, dynamic>> scopes;
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> journals;
  final List<Map<String, dynamic>> financialAccounts;
  final List<Map<String, dynamic>> centers;
  final List<Map<String, dynamic>> families;
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> thirdParties;
  final List<Map<String, dynamic>> programs;
  final List<Map<String, dynamic>> campaigns;
  final List<Map<String, dynamic>> pledges;
  final List<Map<String, dynamic>> movements;
  final List<Map<String, dynamic>> exercices;
  final List<Map<String, dynamic>> entries;
  final List<Map<String, dynamic>> entryLines;
  final List<Map<String, dynamic>> bankStatements;
  final List<Map<String, dynamic>> bankStatementLines;
  final List<Map<String, dynamic>> budgets;
  final List<Map<String, dynamic>> budgetLines;
  final List<Map<String, dynamic>> immobilisations;
  final List<Map<String, dynamic>> monthlyReports;
}

String _id(String group, int index) {
  return '00000000-0000-0000-$group-${index.toString().padLeft(12, '0')}';
}

String _stableId(String group, String value) {
  final bytes = utf8.encode('$group:$value');
  var hash = 0;
  for (final byte in bytes) {
    hash = (hash * 31 + byte) & 0x7fffffff;
  }
  return '00000000-0000-0000-9${hash.toString().padLeft(3, '0').substring(0, 3)}-${hash.toString().padLeft(12, '0')}';
}

String _code(String value) {
  return value
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

String _requiredEnv(String key) {
  final value = Platform.environment[key]?.trim();
  if (value == null || value.isEmpty) {
    throw StateError("Variable d'environnement manquante: $key");
  }
  return value;
}

String? _argValue(List<String> args, String key) {
  final index = args.indexOf(key);
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}

void _assertExpectedProject(String baseUrl, String expectedProjectRef) {
  final host = Uri.parse(baseUrl).host;
  if (!host.startsWith('$expectedProjectRef.')) {
    throw StateError(
      'Projet Supabase inattendu: $host. '
      'Projet attendu: $expectedProjectRef.supabase.co',
    );
  }
}

class _AuthUser {
  const _AuthUser({required this.id, required this.email});

  final String id;
  final String email;

  factory _AuthUser.fromJson(Map<String, dynamic> json) {
    return _AuthUser(
      id: json['id'].toString(),
      email: json['email'].toString(),
    );
  }
}

class _SupabaseAdminClient {
  const _SupabaseAdminClient(this.baseUrl, this.serviceRoleKey);

  final String baseUrl;
  final String serviceRoleKey;

  Future<List<_AuthUser>> listAuthUsers() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/auth/v1/admin/users?page=1&per_page=1000'),
          headers: _headers,
        )
        .timeout(_timeout);
    _throwIfFailed(response, 'GET auth users');
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['users'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_AuthUser.fromJson)
        .toList(growable: false);
  }

  Future<_AuthUser> ensureAuthUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final users = await listAuthUsers();
    final existing = users
        .where((user) => user.email.toLowerCase() == email.toLowerCase())
        .firstOrNull;
    final body = jsonEncode({
      'email': email,
      'password': password,
      'email_confirm': true,
      'user_metadata': {'full_name': fullName},
    });
    if (existing == null) {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/v1/admin/users'),
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(_timeout);
      _throwIfFailed(response, 'CREATE auth user $email');
      return _AuthUser.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    final response = await http
        .put(
          Uri.parse('$baseUrl/auth/v1/admin/users/${existing.id}'),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);
    _throwIfFailed(response, 'UPDATE auth user $email');
    return _AuthUser.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<Map<String, dynamic>>> list(
    String table, {
    required String select,
    Map<String, String> filters = const {},
    String? order,
    int? limit,
  }) async {
    final query = <String, String>{
      'select': select,
      ...filters,
      if (order != null) 'order': order,
      if (limit != null) 'limit': limit.toString(),
    };
    final response = await http
        .get(_uri('/rest/v1/$table', query), headers: _headers)
        .timeout(_timeout);
    _throwIfFailed(response, 'LIST $table');
    return (jsonDecode(response.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  Future<void> insert(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    for (final chunk in _chunks(rows, 100)) {
      final response = await http
          .post(
            _uri('/rest/v1/$table'),
            headers: {
              ..._headers,
              'Content-Type': 'application/json',
              'Prefer': 'return=minimal',
            },
            body: jsonEncode(chunk),
          )
          .timeout(_timeout);
      _throwIfFailed(response, 'INSERT $table');
    }
  }

  Future<void> upsert(
    String table,
    List<Map<String, dynamic>> rows, {
    required String onConflict,
  }) async {
    if (rows.isEmpty) return;
    for (final chunk in _chunks(rows, 100)) {
      final response = await http
          .post(
            _uri('/rest/v1/$table', {'on_conflict': onConflict}),
            headers: {
              ..._headers,
              'Content-Type': 'application/json',
              'Prefer': 'resolution=merge-duplicates,return=minimal',
            },
            body: jsonEncode(chunk),
          )
          .timeout(_timeout);
      _throwIfFailed(response, 'UPSERT $table');
    }
  }

  Future<void> deleteWhere(String table, Map<String, String> filters) async {
    final response = await http
        .delete(
          _uri('/rest/v1/$table', filters),
          headers: {..._headers, 'Prefer': 'return=minimal'},
        )
        .timeout(_timeout);
    _throwIfFailed(response, 'DELETE $table');
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
}

Iterable<List<T>> _chunks<T>(List<T> values, int size) sync* {
  for (var index = 0; index < values.length; index += size) {
    final end = (index + size).clamp(0, values.length).toInt();
    yield values.sublist(index, end);
  }
}
