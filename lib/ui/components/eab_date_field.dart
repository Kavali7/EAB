/// Champ de sélection de date EAB.
library;

import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Champ de date réutilisable avec date picker Material.
class EabDateField extends StatelessWidget {
  const EabDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.errorText,
    this.firstDate,
    this.lastDate,
    this.prefixIcon = Icons.calendar_today,
    this.readOnly = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String? hint;
  final String? errorText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final IconData? prefixIcon;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final displayText = value != null
        ? '${value!.day.toString().padLeft(2, '0')}/'
          '${value!.month.toString().padLeft(2, '0')}/'
          '${value!.year}'
        : '';

    return GestureDetector(
      onTap: readOnly
          ? null
          : () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: firstDate ?? DateTime(1900),
                lastDate: lastDate ?? DateTime(2100),
              );
              if (picked != null) {
                onChanged(picked);
              }
            },
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            hintText: hint ?? 'JJ/MM/AAAA',
            errorText: errorText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.inputPaddingH,
              vertical: AppSpacing.inputPaddingV,
            ),
          ),
          controller: TextEditingController(text: displayText),
          readOnly: true,
        ),
      ),
    );
  }
}
