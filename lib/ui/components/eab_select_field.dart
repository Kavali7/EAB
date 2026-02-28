/// Champ de sélection dropdown standard EAB.
library;

import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Champ dropdown réutilisable avec label et validation.
class EabSelectField<T> extends StatelessWidget {
  const EabSelectField({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.hint,
    this.errorText,
    this.validator,
    this.prefixIcon,
    this.isExpanded = true,
  });

  final String label;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? errorText;
  final FormFieldValidator<T>? validator;
  final IconData? prefixIcon;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      isExpanded: isExpanded,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.inputPaddingH,
          vertical: AppSpacing.inputPaddingV,
        ),
      ),
    );
  }
}
