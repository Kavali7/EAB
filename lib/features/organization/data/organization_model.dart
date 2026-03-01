/// Modèle de données pour une organisation.
///
/// Correspond à la table `organizations` de Supabase.
library;

import 'package:flutter/material.dart';

class Organization {
  const Organization({
    required this.id,
    required this.nom,
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

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      nom: json['nom'] as String? ?? json['name'] as String? ?? 'Organisation',
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
        'nom': nom,
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
}
