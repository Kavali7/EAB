import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/accounting_entry.dart';
import '../../providers/accounting_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/info_card.dart';

class AccountingScreen extends ConsumerStatefulWidget {
  const AccountingScreen({super.key});

  @override
  ConsumerState<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends ConsumerState<AccountingScreen> {
  AccountingType? _typeFilter;
  String? _categoryFilter;
  String _query = '';
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(accountingEntriesProvider);
    final entries = entriesAsync.value ?? [];
    final entriesInRange = entries.where((e) {
      if (_dateRange == null) return true;
      return !e.date.isBefore(_dateRange!.start) &&
          !e.date.isAfter(_dateRange!.end);
    }).toList();
    final filtered = entriesInRange.where((e) {
      final matchesType = _typeFilter == null || e.type == _typeFilter;
      final matchesCategory =
          _categoryFilter == null || e.category == _categoryFilter;
      final matchesQuery =
          _query.isEmpty ||
          (e.description ?? '').toLowerCase().contains(_query.toLowerCase()) ||
          e.category.toLowerCase().contains(_query.toLowerCase());
      return matchesType && matchesCategory && matchesQuery;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalIncome = filtered
        .where((e) => e.type == AccountingType.income)
        .fold<double>(0, (p, e) => p + e.amount);
    final totalExpense = filtered
        .where((e) => e.type == AccountingType.expense)
        .fold<double>(0, (p, e) => p + e.amount);

    return DefaultTabController(
      length: 2,
      child: AppShell(
        title: 'Comptabilite',
        currentRoute: '/accounting',
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Ecritures'),
            Tab(text: 'Synthese'),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle ecriture'),
        ),
        body: TabBarView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<AccountingType?>(
                        decoration: const InputDecoration(labelText: 'Type'),
                        initialValue: _typeFilter,
                        items: const [
                          DropdownMenuItem<AccountingType?>(
                            value: null,
                            child: Text('Tous'),
                          ),
                          DropdownMenuItem<AccountingType?>(
                            value: AccountingType.income,
                            child: Text('Recette'),
                          ),
                          DropdownMenuItem<AccountingType?>(
                            value: AccountingType.expense,
                            child: Text('Depense'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _typeFilter = value),
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(_dateRange == null
                          ? 'Periode'
                          : '${dateFormatter.format(_dateRange!.start)} - ${dateFormatter.format(_dateRange!.end)}'),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          initialDateRange: _dateRange,
                        );
                        if (picked != null) {
                          setState(() => _dateRange = picked);
                        }
                      },
                    ),
                    if (_dateRange != null)
                      IconButton(
                        tooltip: 'Effacer periode',
                        onPressed: () => setState(() => _dateRange = null),
                        icon: const Icon(Icons.clear),
                      ),
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<String?>(
                        decoration: const InputDecoration(
                          labelText: 'Categorie',
                        ),
                        initialValue: _categoryFilter,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Toutes'),
                          ),
                          ...(_typeFilter == AccountingType.expense
                                  ? expenseCategories
                                  : _typeFilter == AccountingType.income
                                  ? incomeCategories
                                  : [...incomeCategories, ...expenseCategories])
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              ),
                        ],
                        onChanged: (value) =>
                            setState(() => _categoryFilter = value),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Rechercher',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: entriesAsync.isLoading && entries.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : Card(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Type')),
                                DataColumn(label: Text('Categorie')),
                                DataColumn(label: Text('Montant')),
                                DataColumn(label: Text('Mode')),
                                DataColumn(label: Text('Description')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: filtered
                                  .map(
                                    (e) => DataRow(
                                      cells: [
                                        DataCell(
                                          Text(dateFormatter.format(e.date)),
                                        ),
                                        DataCell(
                                          Text(accountingTypeLabels[e.type]!),
                                        ),
                                        DataCell(Text(e.category)),
                                        DataCell(
                                          Text(
                                            currencyFormatter.format(e.amount),
                                          ),
                                        ),
                                        DataCell(Text(e.paymentMethod ?? '-')),
                                        DataCell(Text(e.description ?? '-')),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                ),
                                                onPressed: () => _openForm(
                                                  context,
                                                  entry: e,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.redAccent,
                                                ),
                                                onPressed: () =>
                                                    _confirmDelete(e),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 260,
                        child: InfoCard(
                          title: 'Total recettes',
                          value: currencyFormatter.format(totalIncome),
                          icon: Icons.trending_up,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: InfoCard(
                          title: 'Total depenses',
                          value: currencyFormatter.format(totalExpense),
                          icon: Icons.trending_down,
                          color: Colors.red[600],
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: InfoCard(
                          title: 'Balance',
                          value: currencyFormatter.format(
                            totalIncome - totalExpense,
                          ),
                          icon: Icons.account_balance_wallet_outlined,
                          color: ChurchTheme.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Exporter CSV (stub)'),
                        onPressed: () => _showExportStub(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Flux sur 6 mois',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 240,
                            child: LineChart(_sixMonthsLine(filtered)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Top categories',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._topCategories(filtered).map(
                            (item) => ListTile(
                              dense: true,
                              title: Text(item.category),
                              subtitle: Text(accountingTypeLabels[item.type]!),
                              trailing: Text(
                                currencyFormatter.format(item.total),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tableau croise categories',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Type')),
                                DataColumn(label: Text('Categorie')),
                                DataColumn(label: Text('Montant')),
                              ],
                              rows: _aggregateByCategory(filtered)
                                  .map(
                                    (item) => DataRow(
                                      cells: [
                                        DataCell(
                                            Text(accountingTypeLabels[item.type]!)),
                                        DataCell(Text(item.category)),
                                        DataCell(Text(
                                            currencyFormatter.format(item.total))),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {AccountingEntry? entry}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AccountingEntryForm(entry: entry),
    );
  }

  Future<void> _confirmDelete(AccountingEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer l\'ecriture ${entry.category} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(accountingEntriesProvider.notifier).removeEntry(entry.id);
    }
  }

  void _showExportStub(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export CSV/Excel sera branche cote backend'),
      ),
    );
  }

  LineChartData _sixMonthsLine(List<AccountingEntry> entries) {
    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - (5 - i)),
    );
    final income = <FlSpot>[];
    final expense = <FlSpot>[];
    for (var i = 0; i < months.length; i++) {
      final month = months[i];
      final incomeSum = entries
          .where(
            (e) =>
                e.type == AccountingType.income &&
                e.date.year == month.year &&
                e.date.month == month.month,
          )
          .fold<double>(0, (p, e) => p + e.amount);
      final expenseSum = entries
          .where(
            (e) =>
                e.type == AccountingType.expense &&
                e.date.year == month.year &&
                e.date.month == month.month,
          )
          .fold<double>(0, (p, e) => p + e.amount);
      income.add(FlSpot(i.toDouble(), incomeSum / 1000));
      expense.add(FlSpot(i.toDouble(), expenseSum / 1000));
    }
    return LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= months.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  monthFormatter.format(months[index]),
                  style: const TextStyle(fontSize: 11),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text('${value.toInt()}k'),
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: income,
          isCurved: true,
          color: Colors.green[700],
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: expense,
          isCurved: true,
          color: Colors.red[600],
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }

  List<_CategoryTotal> _topCategories(List<AccountingEntry> entries) {
    final map = <String, _CategoryTotal>{};
    for (final e in entries) {
      final key = '${e.type.name}-${e.category}';
      final current =
          map[key] ??
          _CategoryTotal(category: e.category, total: 0, type: e.type);
      map[key] = current.copyWith(total: current.total + e.amount);
    }
    final list = map.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list.take(6).toList();
  }

  List<_CategoryTotal> _aggregateByCategory(List<AccountingEntry> entries) {
    final map = <String, _CategoryTotal>{};
    for (final e in entries) {
      final key = '${e.type.name}-${e.category}';
      final current =
          map[key] ??
          _CategoryTotal(category: e.category, total: 0, type: e.type);
      map[key] = current.copyWith(total: current.total + e.amount);
    }
    final list = map.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list.take(12).toList();
  }
}

class AccountingEntryForm extends ConsumerStatefulWidget {
  const AccountingEntryForm({super.key, this.entry});

  final AccountingEntry? entry;

  @override
  ConsumerState<AccountingEntryForm> createState() =>
      _AccountingEntryFormState();
}

class _AccountingEntryFormState extends ConsumerState<AccountingEntryForm> {
  final _formKey = GlobalKey<FormState>();
  AccountingType? _type = AccountingType.income;
  String? _category;
  String? _paymentMethod;
  DateTime _date = DateTime.now();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    if (e != null) {
      _type = e.type;
      _category = e.category;
      _paymentMethod = e.paymentMethod;
      _date = e.date;
      _amountCtrl.text = e.amount.toStringAsFixed(0);
      _descriptionCtrl.text = e.description ?? '';
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null;
    final categories = _type == AccountingType.expense
        ? expenseCategories
        : incomeCategories;
    return AlertDialog(
      title: Text(isEditing ? 'Modifier l\'ecriture' : 'Nouvelle ecriture'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<AccountingType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                      value: AccountingType.income,
                      child: Text('Recette'),
                    ),
                    DropdownMenuItem(
                      value: AccountingType.expense,
                      child: Text('Depense'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _type = value;
                    _category = null;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Categorie'),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => setState(() => _category = value),
                  validator: (v) => v == null ? 'Categorie requise' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(labelText: 'Montant'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Montant requis';
                    final parsed = double.tryParse(v.replaceAll(',', '.'));
                    if (parsed == null) return 'Montant invalide';
                    if (parsed < 0) return 'Montant negatif non autorise';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Mode de paiement',
                  ),
                  items: paymentMethods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (value) => setState(() => _paymentMethod = value),
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: 'Date',
                  value: _date,
                  onSelected: (d) =>
                      setState(() => _date = d ?? DateTime.now()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Mettre a jour' : 'Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
    final notifier = ref.read(accountingEntriesProvider.notifier);
    final entry = AccountingEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      date: _date,
      amount: amount,
      type: _type ?? AccountingType.income,
      category: _category ?? '',
      paymentMethod: _paymentMethod,
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
    );
    if (widget.entry == null) {
      await notifier.addEntry(entry);
    } else {
      await notifier.updateEntry(entry);
    }
    if (mounted) Navigator.of(context).pop();
  }
}

class _CategoryTotal {
  const _CategoryTotal({
    required this.category,
    required this.total,
    required this.type,
  });

  final String category;
  final double total;
  final AccountingType type;

  _CategoryTotal copyWith({
    String? category,
    double? total,
    AccountingType? type,
  }) {
    return _CategoryTotal(
      category: category ?? this.category,
      total: total ?? this.total,
      type: type ?? this.type,
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onSelected,
  });

  final String label;
  final DateTime? value;
  final void Function(DateTime?) onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (picked != null) {
          onSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.date_range),
        ),
        child: Text(value != null ? dateFormatter.format(value!) : 'Choisir'),
      ),
    );
  }
}
