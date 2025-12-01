import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/constants.dart';

part 'member.freezed.dart';
part 'member.g.dart';

@freezed
abstract class Member with _$Member {
  const factory Member({
    required String id,
    required String fullName,
    required Gender gender,
    required DateTime birthDate,
    required MaritalStatus maritalStatus,
    DateTime? baptismDate,
    String? phone,
    String? email,
    String? address,
  }) = _Member;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
}
