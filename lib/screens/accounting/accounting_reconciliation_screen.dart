import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/compte_comptable.dart';
import '../../models/ecriture_comptable.dart';
import '../../models/releve_bancaire.dart';
import '../../providers/accounting_providers.dart';
import '../../ui/ui.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/context_header.dart';

class AccountingReconciliationScreen extends ConsumerStatefulWidget {
  const AccountingReconciliationScreen({super.key});

  @override
  ConsumerState<AccountingReconciliationScreen> createState() =>
      _AccountingReconciliationScreenState();
}

class _AccountingReconciliationScreenState
    extends ConsumerState<AccountingReconciliationScreen> {
  String? _compteBanqueSelectionneId;
  bool _masquerLignesPointees = false;

  @override
  Widget build(BuildContext context) {
    final comptesAsync = ref.watch(comptesComptablesProvider);
    final ecritures = ref.watch(ecrituresFiltreesProvider);
    final relevesAsync = ref.watch(lignesRelevesBancairesProvider);

    return AppShell(
      title: 'Rapprochement bancaire',
      currentRoute: '/accounting-reconciliation',
      showBackButton: true,
      backRoute: '/accounting',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final padding = compact ? AppSpacing.lg : AppSpacing.pagePadding;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ContextHeader(showPorteeComptable: true),
                const SizedBox(height: AppSpacing.cardGap),
                Expanded(
                  child: comptesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, st) => Center(
                      child: Text('Erreur chargement plan de comptes : $err'),
                    ),
                    data: (comptes) {
                      final releves = relevesAsync.asData?.value ?? [];
                      final comptesBanque = comptes
                          .where((c) => c.numero.startsWith('512'))
                          .toList();
                      return _buildContent(
                        comptesBanque: comptesBanque,
                        ecritures: ecritures,
                        releves: releves,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent({
    required List<CompteComptable> comptesBanque,
    required List<EcritureComptable> ecritures,
    required List<LigneReleveBancaire> releves,
  }) {
    var selectedId = _compteBanqueSelectionneId;
    if (selectedId == null && comptesBanque.isNotEmpty) {
      selectedId = comptesBanque.first.id;
      _compteBanqueSelectionneId = selectedId;
    }

    if (selectedId == null) {
      return _emptyCard('Aucun compte bancaire disponible.');
    }

    final selectedCompte = _findCompte(comptesBanque, selectedId);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 920;
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildToolbar(
                    comptesBanque: comptesBanque,
                    selectedId: selectedId!,
                    compact: compact,
                  ),
                  const SizedBox(height: AppSpacing.cardGap),
                  if (selectedCompte != null)
                    _buildReconciliationPanels(
                      compte: selectedCompte,
                      ecritures: ecritures,
                      releves: releves,
                      compact: compact,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolbar({
    required List<CompteComptable> comptesBanque,
    required String selectedId,
    required bool compact,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _bankSelector(comptesBanque, selectedId),
                  const SizedBox(height: AppSpacing.md),
                  _hideMatchedSwitch(),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _bankSelector(comptesBanque, selectedId)),
                  const SizedBox(width: AppSpacing.cardGap),
                  SizedBox(width: 300, child: _hideMatchedSwitch()),
                ],
              ),
      ),
    );
  }

  Widget _bankSelector(List<CompteComptable> comptesBanque, String selectedId) {
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Compte bancaire',
        border: OutlineInputBorder(),
      ),
      items: comptesBanque
          .map(
            (c) => DropdownMenuItem(
              value: c.id,
              child: Text('${c.numero} - ${c.intitule}'),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() => _compteBanqueSelectionneId = v);
      },
    );
  }

  Widget _hideMatchedSwitch() {
    return SwitchListTile(
      value: _masquerLignesPointees,
      onChanged: (v) => setState(() => _masquerLignesPointees = v),
      title: const Text('Masquer les lignes pointees'),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildReconciliationPanels({
    required CompteComptable compte,
    required List<EcritureComptable> ecritures,
    required List<LigneReleveBancaire> releves,
    required bool compact,
  }) {
    final ecrituresCompte = ecritures
        .where((e) => e.lignes.any((l) => l.idCompteComptable == compte.id))
        .toList();
    final lignesEcritures = _lignesForCompte(ecrituresCompte, compte.id);
    final relevesCompte =
        releves.where((r) => r.idCompteBanque == compte.id).toList()
          ..sort((a, b) => a.dateOperation.compareTo(b.dateOperation));
    final relevesFiltres = _masquerLignesPointees
        ? relevesCompte.where((r) => !r.estPointe).toList()
        : relevesCompte;

    final soldeComptable = _calculerSoldeActif(compte.id, ecritures);
    final soldeReleve = relevesCompte.isEmpty
        ? 0.0
        : relevesCompte.last.soldeApresOperation;
    final ecart = soldeComptable - soldeReleve;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummary(
          soldeComptable: soldeComptable,
          soldeReleve: soldeReleve,
          ecart: ecart,
          compact: compact,
        ),
        const SizedBox(height: AppSpacing.cardGap),
        if (compact) ...[
          _buildEcrituresPanel(lignes: lignesEcritures, compact: true),
          const SizedBox(height: AppSpacing.cardGap),
          _buildRelevePanel(
            releves: relevesFiltres,
            ecritures: ecrituresCompte,
            compact: true,
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildEcrituresPanel(
                  lignes: lignesEcritures,
                  compact: false,
                ),
              ),
              const SizedBox(width: AppSpacing.cardGap),
              Expanded(
                child: _buildRelevePanel(
                  releves: relevesFiltres,
                  ecritures: ecrituresCompte,
                  compact: false,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSummary({
    required double soldeComptable,
    required double soldeReleve,
    required double ecart,
    required bool compact,
  }) {
    final items = [
      _SummaryTile(
        label: 'Solde comptable',
        value: _formatMoney(soldeComptable),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.primary,
      ),
      _SummaryTile(
        label: 'Solde releve',
        value: _formatMoney(soldeReleve),
        icon: Icons.receipt_long_outlined,
        color: AppColors.indigo,
      ),
      _SummaryTile(
        label: 'Ecart',
        value: _formatMoney(ecart),
        icon: ecart.abs() < 0.01 ? Icons.check_circle_outline : Icons.warning,
        color: ecart.abs() < 0.01 ? AppColors.success : AppColors.error,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact ? 1 : 3;
        final width =
            (constraints.maxWidth - (columns - 1) * AppSpacing.cardGap) /
            columns;
        return Wrap(
          spacing: AppSpacing.cardGap,
          runSpacing: AppSpacing.cardGap,
          children: [
            for (final item in items) SizedBox(width: width, child: item),
          ],
        );
      },
    );
  }

  Widget _buildEcrituresPanel({
    required List<_LigneEcritureCompte> lignes,
    required bool compact,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ecritures comptables', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            if (lignes.isEmpty)
              _emptyBox('Aucune ecriture sur ce compte.')
            else
              Column(
                children: [
                  for (final ligne in lignes)
                    _AccountingLineCard(
                      ligne: ligne,
                      formatMoney: _formatMoney,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelevePanel({
    required List<LigneReleveBancaire> releves,
    required List<EcritureComptable> ecritures,
    required bool compact,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Releve bancaire', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            if (releves.isEmpty)
              _emptyBox('Aucune ligne de releve a afficher.')
            else
              Column(
                children: [
                  for (final releve in releves)
                    _BankStatementCard(
                      releve: releve,
                      formatMoney: _formatMoney,
                      onToggle: (value) {
                        final notifier = ref.read(
                          lignesRelevesBancairesProvider.notifier,
                        );
                        notifier.mettreAJourLigneReleve(
                          releve.copyWith(estPointe: value),
                        );
                      },
                      onAssociate: () =>
                          _ouvrirDialogAssociation(releve, ecritures),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: _emptyBox(message),
          ),
        ),
      ),
    );
  }

  Widget _emptyBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(message, style: AppTextStyles.bodySmall),
    );
  }

  Future<void> _ouvrirDialogAssociation(
    LigneReleveBancaire ligne,
    List<EcritureComptable> ecritures,
  ) async {
    EcritureComptable? selection;
    await showDialog<void>(
      context: context,
      builder: (ctx) => EabDialog(
        title: 'Associer a une ecriture',
        width: 560,
        content: SizedBox(
          height: 420,
          child: ecritures.isEmpty
              ? const Center(child: Text('Aucune ecriture disponible.'))
              : ListView.separated(
                  itemCount: ecritures.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final e = ecritures[index];
                    return ListTile(
                      title: Text(e.libelle),
                      subtitle: Text(
                        '${_formatDate(e.date)} - Ref: ${e.referencePiece ?? ''}',
                      ),
                      onTap: () {
                        selection = e;
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
        ),
        actions: [
          EabButton(
            label: 'Annuler',
            variant: EabButtonVariant.ghost,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );

    if (selection != null) {
      final notifier = ref.read(lignesRelevesBancairesProvider.notifier);
      notifier.mettreAJourLigneReleve(
        ligne.copyWith(estPointe: true, idEcritureComptableLiee: selection!.id),
      );
    }
  }

  List<_LigneEcritureCompte> _lignesForCompte(
    List<EcritureComptable> ecrituresCompte,
    String compteId,
  ) {
    final lignes = <_LigneEcritureCompte>[];
    for (final e in ecrituresCompte) {
      double debit = 0;
      double credit = 0;
      for (final l in e.lignes) {
        if (l.idCompteComptable == compteId) {
          debit += l.debit ?? 0;
          credit += l.credit ?? 0;
        }
      }
      lignes.add(
        _LigneEcritureCompte(
          date: e.date,
          libelle: e.libelle,
          reference: e.referencePiece,
          debit: debit,
          credit: credit,
        ),
      );
    }
    lignes.sort((a, b) => a.date.compareTo(b.date));
    return lignes;
  }

  double _calculerSoldeActif(
    String idCompte,
    List<EcritureComptable> ecritures,
  ) {
    double debit = 0;
    double credit = 0;
    for (final e in ecritures) {
      for (final l in e.lignes) {
        if (l.idCompteComptable == idCompte) {
          debit += l.debit ?? 0;
          credit += l.credit ?? 0;
        }
      }
    }
    return debit - credit;
  }

  CompteComptable? _findCompte(List<CompteComptable> comptes, String id) {
    for (final compte in comptes) {
      if (compte.id == id) return compte;
    }
    return null;
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatMoney(double value) => currencyFormatter.format(value);
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: AppTextStyles.heading3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountingLineCard extends StatelessWidget {
  const _AccountingLineCard({required this.ligne, required this.formatMoney});

  final _LigneEcritureCompte ligne;
  final String Function(double value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ligne.libelle, style: AppTextStyles.subtitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${_formatDateStatic(ligne.date)} - Ref: ${ligne.reference ?? ''}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: Text('Debit ${formatMoney(ligne.debit)}')),
              Expanded(child: Text('Credit ${formatMoney(ligne.credit)}')),
              const Icon(Icons.check_circle_outline, color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }
}

class _BankStatementCard extends StatelessWidget {
  const _BankStatementCard({
    required this.releve,
    required this.formatMoney,
    required this.onToggle,
    required this.onAssociate,
  });

  final LigneReleveBancaire releve;
  final String Function(double value) formatMoney;
  final ValueChanged<bool> onToggle;
  final VoidCallback onAssociate;

  @override
  Widget build(BuildContext context) {
    final amountColor = releve.montant >= 0
        ? AppColors.success
        : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(
          color: releve.estPointe ? AppColors.success : AppColors.divider,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(releve.libelle, style: AppTextStyles.subtitle),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                formatMoney(releve.montant),
                style: AppTextStyles.subtitle.copyWith(color: amountColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${_formatDateStatic(releve.dateOperation)} - Solde ${formatMoney(releve.soldeApresOperation)}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                selected: releve.estPointe,
                label: Text(releve.estPointe ? 'Pointee' : 'A pointer'),
                avatar: Icon(
                  releve.estPointe
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  size: 18,
                ),
                onSelected: onToggle,
              ),
              OutlinedButton.icon(
                onPressed: onAssociate,
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Associer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LigneEcritureCompte {
  _LigneEcritureCompte({
    required this.date,
    required this.libelle,
    required this.reference,
    required this.debit,
    required this.credit,
  });

  final DateTime date;
  final String libelle;
  final String? reference;
  final double debit;
  final double credit;
}

String _formatDateStatic(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
