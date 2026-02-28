/// Providers Riverpod pour les états financiers SYCEBNL.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/providers/data_service_provider.dart';
import '../data/reports_repository.dart';

/// Repository injecté.
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final ds = ref.watch(dataServiceProvider);
  return ReportsRepository(ds);
});
