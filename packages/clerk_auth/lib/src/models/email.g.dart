// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Email _$EmailFromJson(Map<String, dynamic> json) => Email(
      id: json['id'] as String,
      emailAddress: json['email_address'] as String,
      reserved: json['reserved'] as bool,
      verification: json['verification'] == null
          ? null
          : Verification.fromJson(json['verification'] as Map<String, dynamic>),
      updatedAt: intToDateTime(json['updated_at']),
      createdAt: intToDateTime(json['created_at']),
    );

Map<String, dynamic> _$EmailToJson(Email instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'email_address': instance.emailAddress,
    'reserved': instance.reserved,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('verification', instance.verification?.toJson());
  writeNotNull('updated_at', instance.updatedAt?.toIso8601String());
  writeNotNull('created_at', instance.createdAt?.toIso8601String());
  return val;
}