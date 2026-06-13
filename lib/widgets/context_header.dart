import 'package:flutter/material.dart';

/// Ancien bandeau de contexte utilisateur / assemblee.
///
/// Il est conserve comme composant no-op pour ne pas casser les ecrans qui
/// l'appellent encore, mais l'information n'est plus affichee dans le contenu
/// des pages afin de laisser la priorite aux donnees utiles de chaque module.
class ContextHeader extends StatelessWidget {
  const ContextHeader({
    super.key,
    this.showPorteeComptable = false,
    this.showAsCard = true,
  });

  final bool showPorteeComptable;
  final bool showAsCard;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
