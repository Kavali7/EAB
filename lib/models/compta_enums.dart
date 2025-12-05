/// Enums comptables (SYCEBNL) utilises par les modeles.
///
/// Conserve volontairement les libelles francophones pour coller au domaine.
/// Pas de generation JSON dediee ici : les enums sont relies par les autres
/// modeles Freezed/JsonSerializable.
enum NatureCompte {
  actif,
  passif,
  charge,
  produit,
  horsActiviteOrdinaire,
  engagement,
  autre,
}

/// Type de journal comptable.
enum TypeJournalComptable {
  caisse, // journal de caisse (especes)
  banque, // journal de banque
  operationsDiverses, // OD / ajustements / ecritures diverses
}

/// Type de tiers (personne ou entite liee).
enum TypeTiers {
  membre,
  fournisseur,
  bailleur,
  employe,
  partenaire,
  autre,
}

/// Type de centre analytique.
enum TypeCentreAnalytique {
  assembleeLocale,
  projet,
  activite,
  departement,
  autre,
}

/// Mode de paiement adapte au contexte beninois.
enum ModePaiement {
  especes,
  cheque,
  virementBancaire,
  mobileMoney,
  microfinance,
  autre,
}
