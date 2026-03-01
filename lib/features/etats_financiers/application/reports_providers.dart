/// Providers Riverpod pour les états financiers SYCEBNL.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eab/providers/data_service_provider.dart';
import 'package:eab/core/services/supabase_data_service.dart';
import '../data/reports_repository.dart';

/// Repository injecté.
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final ds = ref.watch(dataServiceProvider) as SupabaseDataService;
  return ReportsRepository(ds);
});
