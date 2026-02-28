/// Configuration de branding multi-tenant.
///
/// Permet à chaque organisation d'avoir ses propres couleurs, logo, et nom.
/// Pour l'instant, valeurs par défaut EAB. Sera alimenté par la table
/// `organisations` de Supabase à terme.
library;

import 'package:flutter/material.dart';

/// Configuration de branding pour une organisation.
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

  /// Branding par défaut : EAB.
  static const defaultBranding = OrganisationBranding(
    nom: 'Église Apostolique du Bénin',
    sigle: 'EAB',
  );

  /// Génère un [ColorScheme] à partir du branding.
  ColorScheme toColorScheme({Brightness brightness = Brightness.light}) {
    return ColorScheme.fromSeed(
      seedColor: couleurPrimaire,
      brightness: brightness,
      primary: couleurPrimaire,
      secondary: couleurSecondaire,
      tertiary: couleurAccent,
    );
  }
}
