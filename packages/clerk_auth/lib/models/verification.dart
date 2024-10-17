import 'package:json_annotation/json_annotation.dart';

import 'models.dart';

part 'verification.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class Verification {
  final Status status;
  final Strategy strategy;
  final int? attempts;
  final String? nonce;

  @JsonKey(fromJson: _convertDateTime)
  final DateTime? expireAt;

  const Verification({
    required this.status,
    required this.strategy,
    required this.attempts,
    required this.expireAt,
    this.nonce,
  });

  factory Verification.fromJson(Map<String, dynamic> json) =>
      _$VerificationFromJson(json);

  Map<String, dynamic> toJson() => _$VerificationToJson(this);

  static DateTime? _convertDateTime(int? expireAt) =>
      expireAt is int ? DateTime.fromMillisecondsSinceEpoch(expireAt) : null;
}