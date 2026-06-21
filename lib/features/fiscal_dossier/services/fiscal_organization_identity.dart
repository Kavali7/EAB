import 'package:eab/features/church_units/data/church_unit_model.dart';
import 'package:eab/features/organization/data/organization_model.dart';

class FiscalOrganizationIdentity {
  const FiscalOrganizationIdentity({
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

  factory FiscalOrganizationIdentity.from({
    required Organization organization,
    required Map<String, dynamic> values,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime previousPeriodEnd,
    ChurchUnit? churchUnit,
  }) {
    final profile = organization.fiscalProfile;
    final orgName = _firstFilled([
      _stringValue(values['org.name']),
      organization.nom,
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
    final periodLabel = _firstFilled([
      _stringValue(values['exercice.label']),
      'Exercice ${periodEnd.year}',
    ]);

    return FiscalOrganizationIdentity(
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
        OrganizationFiscalProfile.defaultApplicableNotes,
      ]),
      currency: _firstFilled([
        _stringValue(values['currency']),
        organization.devise,
      ]),
      periodLabel: periodLabel,
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
      'CENTRE DES IMPÔTS DE COTONOU': taxCenter,
      'CENTRE DES IMPOTS DE COTONOU': taxCenter,
      'AKODA ALIDOU ASSOCIER GERANT Tél 61218199': representativeLine,
      'AKODA ALIDOU ASSOCIER GERANT ': representativeLine,
      'AKODA ALIDOU ASSOCIER GERANT': representativeLine,
      'AKODA': representativeLastName,
      'ALIDOU': representativeFirstName,
      'Gérant': legalRepresentativeTitle,
      'GERANT': legalRepresentativeTitle,
      'Gerant': legalRepresentativeTitle,
      'Ernest Cyrille A. SOUROU': accountantName,
      'BIIC': bankName,
    };
  }

  static String? _stringValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
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
