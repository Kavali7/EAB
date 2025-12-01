import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/services/data_service.dart';
import '../models/accounting_entry.dart';
import 'data_service_provider.dart';

final accountingEntriesProvider =
    AsyncNotifierProvider<AccountingEntriesNotifier, List<AccountingEntry>>(
      AccountingEntriesNotifier.new,
    );

class AccountingEntriesNotifier extends AsyncNotifier<List<AccountingEntry>> {
  late final DataService _service;

  @override
  Future<List<AccountingEntry>> build() async {
    _service = ref.read(dataServiceProvider);
    return _service.getAccountingEntries();
  }

  Future<void> addEntry(AccountingEntry entry) async {
    await _service.addAccountingEntry(entry);
    final current = state.value ?? [];
    state = AsyncData([...current, entry]);
  }

  Future<void> updateEntry(AccountingEntry entry) async {
    await _service.updateAccountingEntry(entry);
    final current = state.value ?? [];
    state = AsyncData([
      for (final e in current)
        if (e.id == entry.id) entry else e,
    ]);
  }

  Future<void> removeEntry(String id) async {
    await _service.deleteAccountingEntry(id);
    final current = state.value ?? [];
    state = AsyncData(current.where((e) => e.id != id).toList());
  }

  double totalIncome() => (state.value ?? [])
      .where((e) => e.type == AccountingType.income)
      .fold(0, (p, e) => p + e.amount);

  double totalExpenses() => (state.value ?? [])
      .where((e) => e.type == AccountingType.expense)
      .fold(0, (p, e) => p + e.amount);
}
