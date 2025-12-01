import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'side_navigation.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.body,
    required this.currentRoute,
    this.floatingActionButton,
    this.actions,
    this.bottom,
  });

  final String title;
  final Widget body;
  final String currentRoute;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions, bottom: bottom),
      drawer: isWide
          ? null
          : Drawer(child: SideNavigation(currentRoute: currentRoute)),
      body: Row(
        children: [
          if (isWide)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Material(
                elevation: 1,
                color: Colors.white,
                child: SafeArea(
                  child: SideNavigation(currentRoute: currentRoute),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          Expanded(
            child: Container(
              color: ChurchTheme.cloud,
              child: Padding(padding: const EdgeInsets.all(12), child: body),
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
