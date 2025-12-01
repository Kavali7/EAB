import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData? icon;
  final Color? color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Container(
                decoration: BoxDecoration(
                  color: (color ?? theme.colorScheme.primary).withAlpha(
                    (255 * 0.1).round(),
                  ),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: color ?? theme.colorScheme.primary),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
