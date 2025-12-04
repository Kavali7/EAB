import 'package:freezed_annotation/freezed_annotation.dart';

part 'region_eglise.freezed.dart';
part 'region_eglise.g.dart';

@freezed
abstract class RegionEglise with _$RegionEglise {
  const RegionEglise._();

  const factory RegionEglise({
    required String id,
    required String nom,
    String? code,
    String? description,
  }) = _RegionEglise;

  factory RegionEglise.fromJson(Map<String, dynamic> json) =>
      _$RegionEgliseFromJson(json);
}
