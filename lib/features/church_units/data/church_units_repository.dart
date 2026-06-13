import 'package:eab/core/services/supabase_data_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'church_unit_model.dart';

class ChurchUnitsRepository {
  ChurchUnitsRepository(this._dataService);

  final SupabaseDataService _dataService;

  Future<List<ChurchUnit>> fetchUnits() async {
    try {
      final response = await _dataService.client
          .from('church_units')
          .select('''
            id,
            organization_id,
            parent_id,
            nom,
            code,
            description,
            ville,
            quartier,
            adresse,
            telephone,
            email,
            active,
            legacy_region_id,
            legacy_district_id,
            legacy_assemblee_id,
            type:church_unit_types(
              code,
              label,
              level_order,
              is_local,
              is_financial_scope,
              can_have_members
            )
          ''')
          .eq('active', true)
          .order('nom', ascending: true);

      final units = (response as List)
          .map((json) => ChurchUnit.fromJson(json as Map<String, dynamic>))
          .toList();
      units.sort((a, b) {
        final level = a.levelOrder.compareTo(b.levelOrder);
        if (level != 0) return level;
        return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
      });
      return units;
    } on PostgrestException catch (e) {
      if (_isMissingFlexibleSchema(e)) return const [];
      rethrow;
    }
  }

  bool _isMissingFlexibleSchema(PostgrestException e) {
    final message = e.message.toLowerCase();
    return e.code == '42P01' ||
        message.contains('church_units') ||
        message.contains('church_unit_types');
  }
}
