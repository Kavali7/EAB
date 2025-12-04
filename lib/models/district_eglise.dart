import 'package:freezed_annotation/freezed_annotation.dart';

part 'district_eglise.freezed.dart';
part 'district_eglise.g.dart';

@freezed
abstract class DistrictEglise with _$DistrictEglise {
  const DistrictEglise._();

  const factory DistrictEglise({
    required String id,
    required String nom,
    String? code,
    required String idRegion,
    String? description,
  }) = _DistrictEglise;

  factory DistrictEglise.fromJson(Map<String, dynamic> json) =>
      _$DistrictEgliseFromJson(json);
}
