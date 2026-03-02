/// Système de notifications in-app basé sur les règles métier.
///
/// Les notifications sont dérivées de l'état actuel des données
/// (écritures brouillon, exercice non ouvert, etc.).
/// Pas de stockage serveur — calcul côté client.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/providers/accounting_providers.dart';
import 'package:eab/features/exercices/application/exercices_providers.dart';

/// Priorité de la notification.
enum NotifPriority { info, warning, urgent }

/// Modèle d'une notification.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.route,
    this.icon,
  });

  final String id;
  final String title;
  final String message;
  final NotifPriority priority;
  final String route; // Navigation cible au tap
  final String? icon;
}

/// Provider qui calcule les notifications à partir de l'état des données.
final appNotificationsProvider =
    Provider.autoDispose<List<AppNotification>>((ref) {
  final notifications = <AppNotification>[];

  // ── 1. Écritures en brouillon ──
  final ecrituresAsync = ref.watch(ecrituresComptablesProvider);
  ecrituresAsync.whenData((ecritures) {
    final brouillons =
        ecritures.where((e) => e.statut.name == 'brouillon').length;
    if (brouillons > 0) {
      notifications.add(AppNotification(
        id: 'draft_ecritures',
        title: 'Écritures en brouillon',
        message:
            '$brouillons écriture${brouillons > 1 ? "s" : ""} en attente de validation',
        priority:
            brouillons >= 5 ? NotifPriority.warning : NotifPriority.info,
        route: '/accounting',
      ));
    }
  });

  // ── 2. Aucun exercice ouvert ──
  final exerciceAsync = ref.watch(exerciceOuvertProvider);
  exerciceAsync.whenData((exercice) {
    if (exercice == null) {
      notifications.add(const AppNotification(
        id: 'no_exercice',
        title: 'Aucun exercice ouvert',
        message:
            'Créez et ouvrez un exercice comptable pour pouvoir saisir des écritures',
        priority: NotifPriority.urgent,
        route: '/accounting-exercices',
      ));
    }
  });

  // ── 3. Exercice proche de la fin ──
  exerciceAsync.whenData((exercice) {
    if (exercice != null && !exercice.estCloture) {
      final finExercice = exercice.dateFin;
      final joursRestants =
          finExercice.difference(DateTime.now()).inDays;
      if (joursRestants <= 30 && joursRestants > 0) {
        notifications.add(AppNotification(
          id: 'exercice_ending',
          title: 'Exercice bientôt terminé',
          message:
              'L\'exercice ${exercice.annee} se termine dans $joursRestants jour${joursRestants > 1 ? "s" : ""}',
          priority: NotifPriority.warning,
          route: '/accounting-exercices',
        ));
      }
    }
  });

  // Trier : urgent d'abord, puis warning, puis info
  notifications.sort((a, b) => b.priority.index.compareTo(a.priority.index));

  return notifications;
});

/// Nombre de notifications non nulles (pour le badge).
final notificationCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(appNotificationsProvider).length;
});
