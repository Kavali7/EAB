/// Multi-tenant branding configuration.
library;

import 'package:flutter/material.dart';

import 'package:eab/core/product_branding.dart';
import 'package:eab/features/organization/data/organization_model.dart';

class OrganisationBranding {
  const OrganisationBranding({
    required this.nom,
    required this.sigle,
    this.logoUrl,
    this.couleurPrimaire = const Color(0xFF0B2E4B),
    this.couleurSecondaire = const Color(0xFFF2C94C),
    this.couleurAccent = const Color(0xFF2563EB),
  });

  final String nom;
  final String sigle;
  final String? logoUrl;
  final Color couleurPrimaire;
  final Color couleurSecondaire;
  final Color couleurAccent;

  static const defaultBranding = OrganisationBranding(
    nom: ProductBranding.appName,
    sigle: ProductBranding.appShortName,
  );

  factory OrganisationBranding.fromOrganization(Organization? org) {
    if (org == null) return defaultBranding;

    final nom = org.nom.trim().isEmpty ? defaultBranding.nom : org.nom.trim();
    final sigle = _firstNonEmpty([
      org.sigle,
      org.parametres?['sigle']?.toString(),
      _initials(nom),
    ]);

    return OrganisationBranding(
      nom: nom,
      sigle: sigle,
      logoUrl: _nullIfBlank(org.logoUrl),
      couleurPrimaire: _parseHexColor(
        org.couleurPrimaire,
        defaultBranding.couleurPrimaire,
      ),
      couleurSecondaire: _parseHexColor(
        org.couleurSecondaire,
        defaultBranding.couleurSecondaire,
      ),
    );
  }

  ColorScheme toColorScheme({Brightness brightness = Brightness.light}) {
    return ColorScheme.fromSeed(
      seedColor: couleurPrimaire,
      brightness: brightness,
      primary: couleurPrimaire,
      secondary: couleurSecondaire,
      tertiary: couleurAccent,
    );
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final clean = value?.trim();
      if (clean != null && clean.isNotEmpty) return clean;
    }
    return defaultBranding.sigle;
  }

  static String? _nullIfBlank(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return null;
    return clean;
  }

  static String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return defaultBranding.sigle;
    return words
        .take(2)
        .map((word) => word.substring(0, 1).toUpperCase())
        .join();
  }

  static Color _parseHexColor(String? value, Color fallback) {
    final clean = value?.replaceAll('#', '').trim();
    if (clean == null || clean.length != 6) return fallback;
    try {
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}
