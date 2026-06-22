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
    await client.insert('budgets_comptables', group.budgets);
    await client.insert('lignes_budgets', group.budgetLines);
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
  await client.insert('fiscal_dossier_values', values);
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
    final budgets = <Map<String, dynamic>>[];
    final budgetLines = <Map<String, dynamic>>[];
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
            ...localUnits.take(8),
            ...units.where((unit) => unit['type_id'] == sectionTypeId).take(8),
          ];
    for (var i = 0; i < financeUnits.length; i++) {
      final unit = financeUnits[i];
      financialAccounts.addAll(_financialAccounts(unit['id'] as String, i + 1));
    }
    for (var i = 0; i < localUnits.length && i < (single ? 1 : 8); i++) {
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
    thirdParties.addAll(_thirdParties());
    campaigns.addAll(
      _campaigns(
        localUnits.first['id'] as String,
        programs.first['id'] as String,
      ),
    );
    pledges.addAll(
      _pledges(
        campaigns.first['id'] as String,
        localUnits.first['id'] as String,
        members.first['id'] as String,
      ),
    );
    movements.addAll(
      _movements(
        campaigns.first['id'] as String,
        localUnits.first['id'] as String,
        members.first['id'] as String,
        financialAccounts.first['id'] as String,
      ),
    );
    entries.addAll(_entries(localUnits.first['id'] as String));
    entryLines.addAll(_entryLines());
    budgets.add(
      _budget(localUnits.first['id'] as String, centers.first['id'] as String),
    );
    budgetLines.addAll(_budgetLines());

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
      budgets: budgets,
      budgetLines: budgetLines,
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
      'type': 'mobile_money',
      'label': 'Mobile Money MTN',
      'provider': 'MTN',
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
    },
  ];

  List<Map<String, dynamic>> _thirdParties() => [
    {
      'id': _id(single ? '2e00' : '1e00', 1),
      'organization_id': orgId,
      'nom': 'Fournisseur Demo Services',
      'type': 'fournisseur',
      'telephone': '+229 97 00 00 00',
      'email': 'fournisseur.demo@example.com',
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
  ];

  List<Map<String, dynamic>> _pledges(
    String campaignId,
    String unitId,
    String memberId,
  ) => [
    {
      'id': _id(single ? '2f10' : '1f10', 1),
      'organization_id': orgId,
      'campagne_id': campaignId,
      'church_unit_id': unitId,
      'membre_id': memberId,
      'montant_promis': 150000,
      'date_promesse': '2025-03-03',
      'date_echeance': '2025-05-30',
      'statut': 'partielle',
      'notes': 'Promesse demo avec versement partiel.',
    },
  ];

  List<Map<String, dynamic>> _movements(
    String campaignId,
    String unitId,
    String memberId,
    String accountId,
  ) => [
    {
      'id': _id(single ? '2f20' : '1f20', 1),
      'organization_id': orgId,
      'church_unit_id': unitId,
      'financial_account_id': accountId,
      'campagne_id': campaignId,
      'membre_id': memberId,
      'type': 'encaissement',
      'montant': 75000,
      'date_mouvement': '2025-03-10',
      'libelle': 'Versement partiel cotisation renovation',
      'mode_paiement': 'especes',
      'statut': 'valide',
      'validated_at': '2025-03-10T12:00:00Z',
    },
  ];

  List<Map<String, dynamic>> _entries(String unitId) => [
    {
      'id': _id(single ? '2f30' : '1f30', 1),
      'organization_id': orgId,
      'church_unit_id': unitId,
      'id_journal': _id(single ? '2700' : '1700', 1),
      'date': '2025-03-02',
      'reference_piece': 'REC-DEMO-001',
      'libelle': 'Offrandes du culte dominical',
      'statut': 'validee',
      'validated_at': '2025-03-02T12:00:00Z',
    },
    {
      'id': _id(single ? '2f30' : '1f30', 2),
      'organization_id': orgId,
      'church_unit_id': unitId,
      'id_journal': _id(single ? '2700' : '1700', 1),
      'date': '2025-03-06',
      'reference_piece': 'DEP-DEMO-001',
      'libelle': 'Aide sociale a une famille',
      'statut': 'validee',
      'validated_at': '2025-03-06T12:00:00Z',
    },
  ];

  List<Map<String, dynamic>> _entryLines() => [
    {
      'id': _id(single ? '2f40' : '1f40', 1),
      'id_ecriture': _id(single ? '2f30' : '1f30', 1),
      'id_compte_comptable': _id(single ? '2600' : '1600', 8),
      'libelle': 'Encaissement caisse',
      'debit': 300000,
      'credit': 0,
      'mode_paiement': 'especes',
    },
    {
      'id': _id(single ? '2f40' : '1f40', 2),
      'id_ecriture': _id(single ? '2f30' : '1f30', 1),
      'id_compte_comptable': _id(single ? '2600' : '1600', 13),
      'libelle': 'Offrandes',
      'debit': 0,
      'credit': 300000,
    },
    {
      'id': _id(single ? '2f40' : '1f40', 3),
      'id_ecriture': _id(single ? '2f30' : '1f30', 2),
      'id_compte_comptable': _id(single ? '2600' : '1600', 11),
      'libelle': 'Aide sociale',
      'debit': 50000,
      'credit': 0,
    },
    {
      'id': _id(single ? '2f40' : '1f40', 4),
      'id_ecriture': _id(single ? '2f30' : '1f30', 2),
      'id_compte_comptable': _id(single ? '2600' : '1600', 8),
      'libelle': 'Sortie caisse',
      'debit': 0,
      'credit': 50000,
      'mode_paiement': 'especes',
    },
  ];

  Map<String, dynamic> _budget(String unitId, String centerId) => {
    'id': _id(single ? '2f50' : '1f50', 1),
    'organization_id': orgId,
    'church_unit_id': unitId,
    'id_centre_analytique': centerId,
    'exercice': 2025,
    'libelle': 'Budget de fonctionnement 2025',
    'est_verrouille': false,
  };

  List<Map<String, dynamic>> _budgetLines() => [
    {
      'id': _id(single ? '2f60' : '1f60', 1),
      'id_budget': _id(single ? '2f50' : '1f50', 1),
      'id_compte_comptable': _id(single ? '2600' : '1600', 9),
      'montant_prevu': 800000,
    },
    {
      'id': _id(single ? '2f60' : '1f60', 2),
      'id_budget': _id(single ? '2f50' : '1f50', 1),
      'id_compte_comptable': _id(single ? '2600' : '1600', 13),
      'montant_prevu': 3000000,
    },
  ];

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
    'statut': 'valide',
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
    required this.budgets,
    required this.budgetLines,
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
  final List<Map<String, dynamic>> budgets;
  final List<Map<String, dynamic>> budgetLines;
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
