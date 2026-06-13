/// Widget de rendu dynamique d'un champ fiscal template.
///
/// Supporte les types : money, text, date, select, bool, percent, integer.
/// Les champs computed sont affichés en grisé avec badge "Auto".
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:eab/core/theme.dart';
import 'package:eab/features/fiscal_dossier/domain/fiscal_models.dart';

class FiscalFieldWidget extends StatelessWidget {
  final FiscalTemplateField field;
  final dynamic value;
  final bool readOnly;
  final ValueChanged<dynamic>? onChanged;

  const FiscalFieldWidget({
    super.key,
    required this.field,
    this.value,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = readOnly || field.isReadonly;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + badges
          Row(
            children: [
              Expanded(
                child: Text(
                  field.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: field.isBold
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: field.isHighlighted
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (field.required)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    '*',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              if (field.isComputed) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Auto',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // Field input
          _buildInput(context, isLocked),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context, bool isLocked) {
    switch (field.fieldType) {
      case 'money':
        return _buildMoneyField(isLocked);
      case 'text':
        return _buildTextField(isLocked);
      case 'date':
        return _buildDateField(context, isLocked);
      case 'select':
        return _buildSelectField(isLocked);
      case 'bool':
        return _buildBoolField(isLocked);
      case 'percent':
        return _buildNumberField(isLocked, suffix: '%');
      case 'integer':
        return _buildNumberField(isLocked);
      default:
        return _buildTextField(isLocked);
    }
  }

  Widget _buildMoneyField(bool isLocked) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    final displayValue = value != null ? formatter.format(_toNum(value)) : '';

    if (isLocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          displayValue.isEmpty ? '—' : '$displayValue FCFA',
          style: TextStyle(
            fontSize: 14,
            fontWeight: field.isBold ? FontWeight.bold : FontWeight.normal,
            color: field.isHighlighted
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      );
    }

    return TextFormField(
      initialValue: value != null ? _toNum(value).toStringAsFixed(0) : '',
      decoration: InputDecoration(
        suffixText: 'FCFA',
        hintText: field.placeholder ?? '0',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d-]'))],
      onChanged: (v) => onChanged?.call(double.tryParse(v) ?? 0),
    );
  }

  Widget _buildTextField(bool isLocked) {
    if (isLocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          _toStr(value).isEmpty ? '—' : _toStr(value),
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      );
    }

    return TextFormField(
      initialValue: _toStr(value),
      decoration: InputDecoration(hintText: field.placeholder),
      onChanged: (v) => onChanged?.call(v),
    );
  }

  Widget _buildDateField(BuildContext context, bool isLocked) {
    final dateStr = _toStr(value);
    final display = dateStr.isNotEmpty
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr))
        : '';

    if (isLocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          display.isEmpty ? '—' : display,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      );
    }

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: dateStr.isNotEmpty
              ? DateTime.parse(dateStr)
              : DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          onChanged?.call(date.toIso8601String().substring(0, 10));
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: field.placeholder ?? 'JJ/MM/AAAA',
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(display.isEmpty ? '' : display),
      ),
    );
  }

  Widget _buildSelectField(bool isLocked) {
    final options = field.selectOptions ?? [];

    if (isLocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          _toStr(value).isEmpty ? '—' : _toStr(value),
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: options.contains(_toStr(value)) ? _toStr(value) : null,
      decoration: InputDecoration(hintText: field.placeholder),
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: (v) => onChanged?.call(v),
    );
  }

  Widget _buildBoolField(bool isLocked) {
    final checked = value == true || value == 'true';
    return Row(
      children: [
        Checkbox(
          value: checked,
          onChanged: isLocked ? null : (v) => onChanged?.call(v),
        ),
        Expanded(
          child: Text(
            field.hint ?? field.label,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(bool isLocked, {String? suffix}) {
    if (isLocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          value != null
              ? '${_toNum(value).toStringAsFixed(0)}${suffix ?? ''}'
              : '—',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      );
    }

    return TextFormField(
      initialValue: value != null ? _toNum(value).toStringAsFixed(0) : '',
      decoration: InputDecoration(
        suffixText: suffix,
        hintText: field.placeholder ?? '0',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (v) => onChanged?.call(int.tryParse(v) ?? 0),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _toStr(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  double _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
