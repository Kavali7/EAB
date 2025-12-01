import 'package:eab/core/constants.dart';
import 'package:eab/models/accounting_entry.dart';
import 'package:eab/models/member.dart';
import 'package:eab/providers/accounting_provider.dart';
import 'package:eab/providers/members_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const uuid = Uuid();

  test('Members notifier add and remove', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initial = await container.read(membersProvider.future);
    final notifier = container.read(membersProvider.notifier);
    final member = Member(
      id: uuid.v4(),
      fullName: 'Test User',
      gender: Gender.male,
      birthDate: DateTime(1990, 1, 1),
      maritalStatus: MaritalStatus.single,
    );

    await notifier.addMember(member);
    final afterAdd = container.read(membersProvider).value!;
    expect(afterAdd.length, initial.length + 1);
    expect(afterAdd.any((m) => m.id == member.id), isTrue);

    await notifier.removeMember(member.id);
    final afterRemove = container.read(membersProvider).value!;
    expect(afterRemove.length, initial.length);
    expect(afterRemove.any((m) => m.id == member.id), isFalse);
  });

  test('Accounting notifier updates totals', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(accountingEntriesProvider.future);
    final notifier = container.read(accountingEntriesProvider.notifier);
    final entryIncome = AccountingEntry(
      id: uuid.v4(),
      date: DateTime.now(),
      amount: 1000,
      type: AccountingType.income,
      category: 'Test income',
    );
    final entryExpense = AccountingEntry(
      id: uuid.v4(),
      date: DateTime.now(),
      amount: 400,
      type: AccountingType.expense,
      category: 'Test expense',
    );

    await notifier.addEntry(entryIncome);
    await notifier.addEntry(entryExpense);

    expect(notifier.totalIncome(), greaterThanOrEqualTo(entryIncome.amount));
    expect(notifier.totalExpenses(), greaterThanOrEqualTo(entryExpense.amount));

    await notifier.removeEntry(entryIncome.id);
    await notifier.removeEntry(entryExpense.id);
  });
}
