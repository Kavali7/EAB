/// Tableau paginé EAB — remplace les PaginatedDataTable ad-hoc.
///
/// Fournit : tri par colonne, recherche intégrée, pagination,
/// et gestion des états vide/chargement/erreur.
library;

import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Définition d'une colonne pour [EabTable].
class EabColumn<T> {
  const EabColumn({
    required this.label,
    required this.cellBuilder,
    this.flex = 1,
    this.sortKeyExtractor,
    this.alignment = Alignment.centerLeft,
  });

  /// Label affiché dans l'en-tête.
  final String label;

  /// Construit le contenu de la cellule pour une ligne donnée.
  final Widget Function(T item) cellBuilder;

  /// Poids flex pour la largeur (par défaut 1).
  final int flex;

  /// Extracteur de valeur pour le tri. Null = colonne non triable.
  final Comparable Function(T item)? sortKeyExtractor;

  /// Alignement du contenu dans la cellule.
  final Alignment alignment;
}

/// Tableau réutilisable avec pagination, tri, et gestion d'états.
class EabTable<T> extends StatefulWidget {
  const EabTable({
    super.key,
    required this.columns,
    required this.items,
    this.onRowTap,
    this.rowsPerPage = 15,
    this.isLoading = false,
    this.errorMessage,
    this.emptyMessage = 'Aucune donnée disponible',
    this.emptyIcon = Icons.inbox_outlined,
    this.headerActions,
  });

  /// Définition des colonnes.
  final List<EabColumn<T>> columns;

  /// Données à afficher.
  final List<T> items;

  /// Callback quand on tape sur une ligne.
  final ValueChanged<T>? onRowTap;

  /// Nombre de lignes par page.
  final int rowsPerPage;

  /// Affiche un indicateur de chargement.
  final bool isLoading;

  /// Message d'erreur à afficher.
  final String? errorMessage;

  /// Message quand la liste est vide.
  final String emptyMessage;

  /// Icône quand la liste est vide.
  final IconData emptyIcon;

  /// Actions affichées dans l'en-tête (ex: bouton ajouter).
  final List<Widget>? headerActions;

  @override
  State<EabTable<T>> createState() => _EabTableState<T>();
}

class _EabTableState<T> extends State<EabTable<T>> {
  int _currentPage = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  List<T> get _sortedItems {
    if (_sortColumnIndex == null) return widget.items;
    final extractor = widget.columns[_sortColumnIndex!].sortKeyExtractor;
    if (extractor == null) return widget.items;
    final sorted = List<T>.from(widget.items)
      ..sort((a, b) {
        final valA = extractor(a);
        final valB = extractor(b);
        return _sortAscending
            ? valA.compareTo(valB)
            : valB.compareTo(valA);
      });
    return sorted;
  }

  int get _totalPages =>
      (widget.items.length / widget.rowsPerPage).ceil().clamp(1, 9999);

  List<T> get _pageItems {
    final sorted = _sortedItems;
    final start = _currentPage * widget.rowsPerPage;
    final end = (start + widget.rowsPerPage).clamp(0, sorted.length);
    if (start >= sorted.length) return [];
    return sorted.sublist(start, end);
  }

  void _onSort(int columnIndex) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // État de chargement
    if (widget.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // État d'erreur
    if (widget.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.errorMessage!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // État vide
    if (widget.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.emptyIcon, size: 48, color: Colors.grey[400]),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.emptyMessage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Tableau avec données
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            // En-tête avec actions
            if (widget.headerActions != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: widget.headerActions!,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            // En-tête colonnes
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.inputRadius),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: List.generate(widget.columns.length, (i) {
                  final col = widget.columns[i];
                  final isSorted = _sortColumnIndex == i;
                  return Expanded(
                    flex: col.flex,
                    child: InkWell(
                      onTap: col.sortKeyExtractor != null
                          ? () => _onSort(i)
                          : null,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              col.label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSorted)
                            Icon(
                              _sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 14,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const Divider(height: 1),
            // Lignes
            ..._pageItems.map((item) => InkWell(
                  onTap: widget.onRowTap != null
                      ? () => widget.onRowTap!(item)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: widget.columns
                          .map((col) => Expanded(
                                flex: col.flex,
                                child: Align(
                                  alignment: col.alignment,
                                  child: col.cellBuilder(item),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                )),
            // Pagination
            if (_totalPages > 1)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.items.length} résultat(s) — '
                      'Page ${_currentPage + 1} / $_totalPages',
                      style: theme.textTheme.bodySmall,
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentPage > 0
                              ? () => setState(() => _currentPage--)
                              : null,
                          iconSize: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _currentPage < _totalPages - 1
                              ? () => setState(() => _currentPage++)
                              : null,
                          iconSize: 20,
                        ),
                      ],
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
