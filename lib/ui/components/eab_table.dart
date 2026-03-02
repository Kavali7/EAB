/// Tableau paginé EAB — Design premium avec colonnes larges et lisibles.
///
/// Inspiré des meilleures pratiques de DataGrid :
/// - Numéro de ligne (#)
/// - Alternance de couleurs (zebra striping)
/// - Colonnes à largeur fixe OU flex
/// - Texte toujours ellipsis
/// - Lignes spacieuses pour lisibilité (personnes âgées)
/// - Actions compactes à droite
/// - Tri par colonne
/// - Pagination
library;

import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Définition d'une colonne pour [EabTable].
class EabColumn<T> {
  const EabColumn({
    required this.label,
    required this.cellBuilder,
    this.flex,
    this.fixedWidth,
    this.sortKeyExtractor,
    this.alignment = Alignment.centerLeft,
    this.numeric = false,
  }) : assert(flex != null || fixedWidth != null,
            'EabColumn: flex ou fixedWidth requis');

  /// Label affiché dans l'en-tête.
  final String label;

  /// Construit le contenu de la cellule pour une ligne donnée.
  final Widget Function(T item) cellBuilder;

  /// Poids flex pour la largeur. Null si fixedWidth est défini.
  final int? flex;

  /// Largeur fixe en pixels. Utilisé pour les colonnes numériques et actions.
  final double? fixedWidth;

  /// Extracteur de valeur pour le tri. Null = colonne non triable.
  final Comparable Function(T item)? sortKeyExtractor;

  /// Alignement du contenu dans la cellule.
  final Alignment alignment;

  /// Si true, aligne le texte à droite (montants, quantités).
  final bool numeric;
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
    this.showRowNumbers = true,
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

  /// Affiche la colonne numéro de ligne (#).
  final bool showRowNumbers;

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
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
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

    final pageItems = _pageItems;

    // Tableau avec données — Design premium
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // En-tête avec actions
          if (widget.headerActions != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: widget.headerActions!,
              ),
            ),

          // Scroll horizontal si nécessaire
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 320,
              ),
              child: Column(
                children: [
                  // ── En-tête colonnes ──
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 2),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        // Colonne #
                        if (widget.showRowNumbers)
                          SizedBox(
                            width: 48,
                            child: Text(
                              '#',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        // Colonnes data
                        ...List.generate(widget.columns.length, (i) {
                          final col = widget.columns[i];
                          final isSorted = _sortColumnIndex == i;
                          return _buildHeaderCell(
                            col: col,
                            isSorted: isSorted,
                            index: i,
                            theme: theme,
                          );
                        }),
                      ],
                    ),
                  ),

                  // ── Lignes de données ──
                  ...List.generate(pageItems.length, (rowIndex) {
                    final item = pageItems[rowIndex];
                    final globalIndex =
                        _currentPage * widget.rowsPerPage + rowIndex + 1;
                    final isEven = rowIndex.isEven;

                    return InkWell(
                      onTap: widget.onRowTap != null
                          ? () => widget.onRowTap!(item)
                          : null,
                      hoverColor: Colors.blue.shade50,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isEven ? Colors.white : Colors.grey.shade50,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Numéro de ligne
                            if (widget.showRowNumbers)
                              SizedBox(
                                width: 48,
                                child: Text(
                                  '$globalIndex',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            // Cellules
                            ...widget.columns.map((col) =>
                                _buildDataCell(col: col, item: item)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── Pagination ──
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${widget.items.length} résultat${widget.items.length > 1 ? "s" : ""} — '
                    'Page ${_currentPage + 1} / $_totalPages',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  // Boutons page
                  _pageButton(
                    icon: Icons.first_page,
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage = 0)
                        : null,
                  ),
                  _pageButton(
                    icon: Icons.chevron_left,
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      '${_currentPage + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _pageButton(
                    icon: Icons.chevron_right,
                    onPressed: _currentPage < _totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                  _pageButton(
                    icon: Icons.last_page,
                    onPressed: _currentPage < _totalPages - 1
                        ? () => setState(() => _currentPage = _totalPages - 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Construit une cellule d'en-tête.
  Widget _buildHeaderCell({
    required EabColumn<T> col,
    required bool isSorted,
    required int index,
    required ThemeData theme,
  }) {
    final content = InkWell(
      onTap: col.sortKeyExtractor != null ? () => _onSort(index) : null,
      child: Row(
        mainAxisAlignment: col.numeric
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              col.label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.grey[700],
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (col.sortKeyExtractor != null) ...[
            const SizedBox(width: 4),
            Icon(
              isSorted
                  ? (_sortAscending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward)
                  : Icons.unfold_more,
              size: 14,
              color: isSorted ? theme.colorScheme.primary : Colors.grey[400],
            ),
          ],
        ],
      ),
    );

    if (col.fixedWidth != null) {
      return SizedBox(width: col.fixedWidth, child: content);
    }
    return Expanded(flex: col.flex ?? 1, child: content);
  }

  /// Construit une cellule de données.
  Widget _buildDataCell({
    required EabColumn<T> col,
    required T item,
  }) {
    final child = DefaultTextStyle.merge(
      style: const TextStyle(fontSize: 14, height: 1.4),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
      child: Align(
        alignment: col.numeric ? Alignment.centerRight : col.alignment,
        child: col.cellBuilder(item),
      ),
    );

    if (col.fixedWidth != null) {
      return SizedBox(width: col.fixedWidth, child: child);
    }
    return Expanded(flex: col.flex ?? 1, child: child);
  }

  Widget _pageButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) =>
      SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          icon: Icon(icon, size: 18),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      );
}
