/// Champ de texte standard EAB.
///
/// Remplace les InputDecoration ad-hoc dans les formulaires par un composant
/// unique avec label, validation, hint, et suffixe optionnel.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_spacing.dart';

/// Champ de saisie texte réutilisable.
class EabTextField extends StatelessWidget {
  const EabTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.helper,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final String? helper;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final bool readOnly;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.inputPaddingH,
          vertical: AppSpacing.inputPaddingV,
        ),
      ),
      obscureText: obscureText,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      autofocus: autofocus,
      onChanged: onChanged,
      onSaved: onSaved,
      validator: validator,
    );
  }
}

/// Champ de saisie numérique.
class EabNumberField extends StatelessWidget {
  const EabNumberField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.readOnly = false,
    this.allowDecimal = true,
    this.suffixText,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final bool readOnly;
  final bool allowDecimal;
  final String? suffixText;

  @override
  Widget build(BuildContext context) {
    return EabTextField(
      label: label,
      controller: controller,
      initialValue: initialValue,
      hint: hint,
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixText != null
          ? Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(suffixText!, style: const TextStyle(fontSize: 13)),
            )
          : null,
      onChanged: onChanged,
      onSaved: onSaved,
      validator: validator,
      readOnly: readOnly,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowDecimal ? RegExp(r'[\d.,]') : RegExp(r'\d'),
        ),
      ],
    );
  }
}
