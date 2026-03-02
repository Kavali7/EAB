/// Panneau de notifications et badge pour le sidebar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/theme.dart';
import '../application/notifications_provider.dart';

/// Badge de notification à placer sur une icône.
class NotificationBadge extends ConsumerWidget {
  const NotificationBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificationCountProvider);

    if (count == 0) return child;

    return Badge(
      label: Text('$count', style: const TextStyle(fontSize: 10)),
      backgroundColor: Colors.red,
      child: child,
    );
  }
}

/// Panneau de notifications (popup ou bottom sheet).
class NotificationPanel extends ConsumerWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(appNotificationsProvider);

    if (notifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Aucune notification',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400, maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.notifications_active,
                    size: 20, color: ChurchTheme.navy),
                const SizedBox(width: 8),
                Text(
                  '${notifications.length} notification${notifications.length > 1 ? "s" : ""}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final style = _priorityStyle(notif.priority);

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: style.color.withValues(alpha: 0.15),
                    child: Icon(style.icon, color: style.color, size: 16),
                  ),
                  title: Text(
                    notif.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    notif.message,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: Icon(Icons.chevron_right,
                      size: 16, color: Colors.grey[400]),
                  onTap: () {
                    Navigator.of(context).pop(); // Fermer le popup
                    Navigator.of(context)
                        .pushReplacementNamed(notif.route);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  ({IconData icon, Color color}) _priorityStyle(NotifPriority p) =>
      switch (p) {
        NotifPriority.urgent => (
            icon: Icons.error_outline,
            color: Colors.red
          ),
        NotifPriority.warning => (
            icon: Icons.warning_amber_outlined,
            color: Colors.orange
          ),
        NotifPriority.info => (
            icon: Icons.info_outline,
            color: Colors.blue
          ),
      };
}

/// Helper pour afficher le panneau en popup.
void showNotificationPanel(BuildContext context) {
  final button = context.findRenderObject() as RenderBox?;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;

  if (button != null && overlay != null) {
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      constraints: const BoxConstraints(maxWidth: 380, maxHeight: 450),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: const NotificationPanel(),
        ),
      ],
    );
  }
}
