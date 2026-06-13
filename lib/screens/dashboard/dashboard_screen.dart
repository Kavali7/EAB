import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/dashboard_screen_v2.dart';

/// Compatibility wrapper for old imports.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const DashboardScreenV2();
}
