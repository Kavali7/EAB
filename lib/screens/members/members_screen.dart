import 'package:flutter/material.dart';

import '../../features/members/presentation/members_screen_v2.dart';

/// Compatibility wrapper for old imports.
class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) => const MembersScreenV2();
}
