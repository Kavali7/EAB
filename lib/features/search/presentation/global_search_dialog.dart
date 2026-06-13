import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/core/theme.dart';
import 'package:eab/providers/user_profile_providers.dart';
import 'package:eab/ui/ui.dart';

import '../application/search_providers.dart';
import '../data/search_repository.dart';

void showGlobalSearch(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.42),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
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
      setState(() {
        _results = [];
        _isSearching = false;
        _selectedIndex = 0;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      if (mounted) {
        setState(() {
          _results = [];
          _isSearching = false;
          _selectedIndex = 0;
        });
      }
      return;
    }

    final profile = ref.read(profilUtilisateurCourantProvider);
    if (profile == null) {
      if (mounted) setState(() => _isSearching = false);
      return;
    }

    try {
      final repo = ref.read(searchRepositoryProvider);
      final results = await repo.search(profile.id, query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _selectedIndex = 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _moveSelection(int delta) {
    if (_results.isEmpty) return;
    final next = (_selectedIndex + delta).clamp(0, _results.length - 1);
    setState(() => _selectedIndex = next);
  }

  void _navigateTo(SearchResult result) {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(result.route);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final compact = size.width < 640;
    final hasQuery = _searchCtrl.text.trim().isNotEmpty;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).maybePop();
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _moveSelection(1);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _moveSelection(-1);
        } else if (event.logicalKey == LogicalKeyboardKey.enter &&
            _results.isNotEmpty) {
          _navigateTo(_results[_selectedIndex]);
        }
      },
      child: Dialog(
        alignment: compact ? Alignment.topCenter : Alignment.topCenter,
        insetPadding: EdgeInsets.fromLTRB(
          compact ? 12 : 24,
          compact ? 18 : 72,
          compact ? 12 : 24,
          18,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 680,
            maxHeight: compact ? size.height - 36 : 620,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.xlAll,
            child: Material(
              color: AppColors.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SearchHeader(
                    controller: _searchCtrl,
                    focusNode: _focusNode,
                    isSearching: _isSearching,
                    onChanged: _onQueryChanged,
                    onClear: () {
                      _searchCtrl.clear();
                      setState(() {
                        _results = [];
                        _isSearching = false;
                        _selectedIndex = 0;
                      });
                      _focusNode.requestFocus();
                    },
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: AppAnimation.fast,
                      child: _SearchBody(
                        key: ValueKey(
                          '${_results.length}-$hasQuery-$_isSearching',
                        ),
                        hasQuery: hasQuery,
                        isSearching: _isSearching,
                        results: _results,
                        selectedIndex: _selectedIndex,
                        onSelect: _navigateTo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.isSearching,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: AppRadius.mdAll,
            ),
            child: const Icon(Icons.search, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  style: AppTextStyles.body.copyWith(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    suffixIcon: isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(13),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : value.text.isNotEmpty
                        ? IconButton(
                            tooltip: 'Effacer',
                            onPressed: onClear,
                            icon: const Icon(Icons.close),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'Fermer',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({
    super.key,
    required this.hasQuery,
    required this.isSearching,
    required this.results,
    required this.selectedIndex,
    required this.onSelect,
  });

  final bool hasQuery;
  final bool isSearching;
  final List<SearchResult> results;
  final int selectedIndex;
  final ValueChanged<SearchResult> onSelect;

  @override
  Widget build(BuildContext context) {
    if (!hasQuery) {
      return const _SearchPlaceholder();
    }

    if (results.isEmpty && !isSearching) {
      return const EmptyState(
        icon: Icons.search_off_outlined,
        message: 'Aucun resultat trouve.',
      );
    }

    if (results.isEmpty && isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        return _ResultTile(
          result: results[index],
          isSelected: index == selectedIndex,
          onTap: () => onSelect(results[index]),
        );
      },
    );
  }
}

class _SearchPlaceholder extends StatelessWidget {
  const _SearchPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(
              Icons.manage_search_outlined,
              color: AppColors.textTertiary,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun terme saisi.',
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
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
    'membre' => Icons.person_outline,
    'programme' => Icons.event_note_outlined,
    'ecriture' => Icons.receipt_long_outlined,
    _ => Icons.search,
  };

  Color get _color => switch (result.category) {
    'membre' => AppColors.info,
    'programme' => AppColors.success,
    'ecriture' => AppColors.secondary,
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.07)
            : Colors.transparent,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          borderRadius: AppRadius.mdAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.11),
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Icon(_icon, color: _color, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subtitle,
                      ),
                      if (result.subtitle?.isNotEmpty == true) ...[
                        const SizedBox(height: 3),
                        Text(
                          result.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Text(
                    result.categoryLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: _color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
