import 'package:flutter/material.dart';

import '../../features/programs/presentation/programs_screen_v2.dart';

/// Compatibility wrapper for old imports.
class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) => const ProgramsScreenV2();
}
