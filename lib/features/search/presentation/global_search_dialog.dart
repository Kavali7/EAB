/// Modal de recherche globale (Ctrl+K).
///
/// Recherche dans : Membres, Programmes, Écritures comptables.
/// Debounce 300ms, résultats catégorisés avec navigation.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/ui/ui.dart';
import 'package:eab/providers/user_profile_providers.dart';
import '../application/search_providers.dart';
import '../data/search_repository.dart';

/// Ouvre le modal de recherche globale.
void showGlobalSearch(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const _GlobalSearchDialog(),
  );
}

class _GlobalSearchDialog extends ConsumerStatefulWidget {
  const _GlobalSearchDialog();

  @override
  ConsumerState<_GlobalSearchDialog> createState() =>
      _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends ConsumerState<_GlobalSearchDialog> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<SearchResult> _results = [];
  bool _isSearching = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    final profile = ref.read(currentUserProfileProvider).value;
    if (profile == null) return;
    final orgId = profile.organizationId;
    if (orgId == null || orgId.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final repo = ref.read(searchRepositoryProvider);
      final results = await repo.search(orgId, query);
      if (mounted) {
        setState(() {
          _results = results;
          _selectedIndex = 0;
        });
      }
    } catch (_) {
      // Silently fail
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _navigateTo(SearchResult result) {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(result.route);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<SearchResult>>{};
    for (final r in _results) {
      (grouped[r.category] ??= []).add(r);
    }

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            setState(() {
              _selectedIndex = (_selectedIndex + 1).clamp(0, _results.length - 1);
            });
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            setState(() {
              _selectedIndex = (_selectedIndex - 1).clamp(0, _results.length - 1);
            });
          } else if (event.logicalKey == LogicalKeyboardKey.enter &&
              _results.isNotEmpty) {
            _navigateTo(_results[_selectedIndex]);
          }
        }
      },
      child: Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 80, left: 100, right: 100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _focusNode,
                  onChanged: _onQueryChanged,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Rechercher membres, programmes, écritures...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _results = []);
                                },
                              )
                            : null,
                    border: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
              const Divider(height: 1),

              // Results
              if (_results.isEmpty && _searchCtrl.text.length >= 2 && !_isSearching)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'Aucun résultat',
                    subtitle: 'Essayez un autre terme de recherche.',
                  ),
                )
              else if (_results.isNotEmpty)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (_, i) {
                      final r = _results[i];
                      final isSelected = i == _selectedIndex;
                      return _ResultTile(
                        result: r,
                        isSelected: isSelected,
                        onTap: () => _navigateTo(r),
                      );
                    },
                  ),
                )
              else if (_searchCtrl.text.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.search, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text(
                        'Tapez au moins 2 caractères',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),

              // Footer
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _shortcutKey('↑↓'),
                    const SizedBox(width: 4),
                    Text('naviguer', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    const SizedBox(width: 16),
                    _shortcutKey('↵'),
                    const SizedBox(width: 4),
                    Text('ouvrir', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    const SizedBox(width: 16),
                    _shortcutKey('Esc'),
                    const SizedBox(width: 4),
                    Text('fermer', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shortcutKey(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600])),
      );
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.result,
    required this.isSelected,
    required this.onTap,
  });
  final SearchResult result;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon => switch (result.category) {
        'membre' => Icons.person,
        'programme' => Icons.event,
        'ecriture' => Icons.receipt_long,
        _ => Icons.search,
      };

  Color get _color => switch (result.category) {
        'membre' => Colors.blue,
        'programme' => Colors.green,
        'ecriture' => Colors.orange,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      leading: CircleAvatar(
        backgroundColor: _color.withOpacity(0.1),
        child: Icon(_icon, color: _color, size: 20),
      ),
      title: Text(
        result.title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: result.subtitle != null
          ? Text(
              result.subtitle!,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          result.categoryLabel,
          style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600),
        ),
      ),
      onTap: onTap,
    );
  }
}
