/// Modèle de données pour une organisation.
///
/// Correspond à la table `organizations` de Supabase.
library;

import 'package:flutter/material.dart';

class Organization {
  const Organization({
    required this.id,
    required this.nom,
    this.sigle,
    this.description,
    this.logoUrl,
    this.couleurPrimaire,
    this.couleurSecondaire,
    this.adresse,
    this.telephone,
    this.email,
    this.siteWeb,
    this.devise = 'FCFA',
    this.parametres,
    this.createdAt,
  });

  final String id;
  final String nom;
  final String? sigle;
  final String? description;
  final String? logoUrl;
  final String? couleurPrimaire;
  final String? couleurSecondaire;
  final String? adresse;
  final String? telephone;
  final String? email;
  final String? siteWeb;
  final String devise;
  final Map<String, dynamic>? parametres;
  final DateTime? createdAt;

  OrganizationFiscalProfile get fiscalProfile {
    return OrganizationFiscalProfile.fromOrganization(this);
  }

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      nom: json['nom'] as String? ?? json['name'] as String? ?? 'Organisation',
      sigle: json['sigle'] as String? ?? json['code'] as String?,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      couleurPrimaire: json['couleur_primaire'] as String?,
      couleurSecondaire: json['couleur_secondaire'] as String?,
      adresse: json['adresse'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      siteWeb: json['site_web'] as String?,
      devise: json['devise'] as String? ?? 'FCFA',
      parametres: json['parametres'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': nom,
    'sigle': sigle,
    'description': description,
    'logo_url': logoUrl,
    'couleur_primaire': couleurPrimaire,
    'couleur_secondaire': couleurSecondaire,
    'adresse': adresse,
    'telephone': telephone,
    'email': email,
    'site_web': siteWeb,
    'devise': devise,
    'parametres': parametres,
  };

  /// JSON sans 'id' — pour les appels UPDATE Supabase.
  Map<String, dynamic> toUpdateJson() => {
    'name': nom,
    'sigle': sigle,
    'description': description,
    'logo_url': logoUrl,
    'couleur_primaire': couleurPrimaire,
    'couleur_secondaire': couleurSecondaire,
    'adresse': adresse,
    'telephone': telephone,
    'email': email,
    'site_web': siteWeb,
    'devise': devise,
    'parametres': parametres,
  };

  /// Parse la couleur primaire hexadécimale en Color Flutter.
  Color get primaryColor {
    if (couleurPrimaire == null || couleurPrimaire!.isEmpty) {
      return const Color(0xFF1B2A4A); // Navy default
    }
    final hex = couleurPrimaire!.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Parse la couleur secondaire.
  Color get secondaryColor {
    if (couleurSecondaire == null || couleurSecondaire!.isEmpty) {
      return const Color(0xFFD4A843); // Gold default
    }
    final hex = couleurSecondaire!.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Map<String, dynamic> get onboarding {
    final raw = parametres?['onboarding'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  List<String> get onboardingSkippedSteps {
    final raw = onboarding['skipped_steps'];
    if (raw is List) {
      return raw
          .map((step) => step.toString().trim())
          .where((step) => step.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  List<String> get onboardingCompletedSteps {
    final raw = onboarding['completed_steps'];
    if (raw is List) {
      return raw
          .map((step) => step.toString().trim())
          .where((step) => step.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  String? get onboardingStructureModel {
    final value = onboarding['structure_model']?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  bool get hasPendingOnboardingSteps => onboardingSkippedSteps.isNotEmpty;
}

class OrganizationFiscalProfile {
  const OrganizationFiscalProfile({
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
  });

  static const paramKey = 'fiscal_identity';

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

  factory OrganizationFiscalProfile.fromOrganization(Organization org) {
    final raw = org.parametres?[paramKey] ?? org.parametres?['fiscal'];
    final data = raw is Map<String, dynamic>
        ? raw
        : raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};

    return OrganizationFiscalProfile(
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ifu': ifu,
      'registration_number': registrationNumber,
      'tax_center': taxCenter,
      'deposit_center': depositCenter,
      'country': country,
      'head_office_address': headOfficeAddress,
      'activity_description': activityDescription,
      'legal_representative_name': legalRepresentativeName,
      'legal_representative_title': legalRepresentativeTitle,
      'legal_representative_phone': legalRepresentativePhone,
      'accountant_name': accountantName,
      'accountant_title': accountantTitle,
      'accountant_phone': accountantPhone,
      'accountant_email': accountantEmail,
      'bank_name': bankName,
      'bank_account_label': bankAccountLabel,
      'bank_account_number': bankAccountNumber,
      'legal_form_code': legalFormCode,
      'tax_regime_code': taxRegimeCode,
      'country_code': countryCode,
      'establishments_in_country': establishmentsInCountry,
      'establishments_outside_country': establishmentsOutsideCountry,
      'first_fiscal_year': firstFiscalYear,
      'control_type_code': controlTypeCode,
      'main_activity_code': mainActivityCode,
      'social_security_number': socialSecurityNumber,
      'importer_code': importerCode,
      'legal_representative_fiscal_id': legalRepresentativeFiscalId,
    }..removeWhere((_, value) => value == null || value.toString().isEmpty);
  }

  static Map<String, dynamic> mergeIntoParametres(
    Map<String, dynamic>? current,
    OrganizationFiscalProfile profile,
  ) {
    return {...?current, paramKey: profile.toJson()};
  }

  static String? _read(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
