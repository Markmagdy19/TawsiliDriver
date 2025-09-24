// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String?,
  first_name: json['first_name'] as String?,
  last_name: json['last_name'] as String?,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  profilePictureUrl: json['profilePictureUrl'] as String?,
  preferredLanguage: json['preferredLanguage'] as String?,
  subscriptions: Subscriptions.fromJson(
    json['subscriptions'] as Map<String, dynamic>,
  ),
  token: json['token'] as String?,
  name: json['name'] as String?,
  token_type: json['token_type'] as String?,
  is_social: json['is_social'] as bool?,
  lang: json['lang'] as String?,
  notifications: json['notifications'] as bool?,
  otp_approved: json['otp_approved'] as bool?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'first_name': instance.first_name,
  'last_name': instance.last_name,
  'email': instance.email,
  'phone': instance.phone,
  'profilePictureUrl': instance.profilePictureUrl,
  'preferredLanguage': instance.preferredLanguage,
  'subscriptions': instance.subscriptions,
  'token': instance.token,
  'name': instance.name,
  'token_type': instance.token_type,
  'is_social': instance.is_social,
  'lang': instance.lang,
  'notifications': instance.notifications,
  'otp_approved': instance.otp_approved,
};

Subscriptions _$SubscriptionsFromJson(Map<String, dynamic> json) =>
    Subscriptions(
      privateCar: (json['private_car'] as num).toInt(),
      universityBus: (json['university_bus'] as num).toInt(),
      schoolBus: (json['school_bus'] as num).toInt(),
    );

Map<String, dynamic> _$SubscriptionsToJson(Subscriptions instance) =>
    <String, dynamic>{
      'private_car': instance.privateCar,
      'university_bus': instance.universityBus,
      'school_bus': instance.schoolBus,
    };
