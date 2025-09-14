// user.dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String? id;
  final String? first_name;
  final String? last_name;

  final String? email;
  final String? phone;
  final String? profilePictureUrl;
  final String? preferredLanguage;
  final Subscriptions subscriptions; // Now definitively non-nullable here

  final String? token;
  final String? name;
  final String? token_type;
  final bool? is_social;
  final String? lang;
  final bool? notifications;
  final bool? otp_approved;


  User({
    this.id,
    this.first_name,
    this.last_name,
    this.email,
    this.phone,
    this.profilePictureUrl,
    this.preferredLanguage,
    required this.subscriptions, // Mark as required in constructor
    this.token, // Include token in constructor
    this.name,
    this.token_type,
    this.is_social,
    this.lang,
    this.notifications,
    this.otp_approved,
  });

  // In domain/models/user.dart

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      first_name: json['first_name']?.toString(),
      last_name: json['last_name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      profilePictureUrl: json['profile_picture']?.toString(),
      preferredLanguage: json['lang']?.toString(),

      subscriptions: json['subscriptions'] != null
          ? Subscriptions.fromJson(json['subscriptions'] as Map<String, dynamic>)
          : Subscriptions(privateCar: 0, universityBus: 0, schoolBus: 0), // Provide a default empty/initial Subscriptions object or handle nullability in User model.
      // ------------------------
      token: json['token']?.toString(),
      name: json['name']?.toString(),
      token_type: json['token_type']?.toString(),
      is_social: json['is_social'] as bool?,
      lang: json['lang']?.toString(),
      notifications: json['notifications'] as bool?,
      otp_approved: json['otp_approved'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': first_name,
      'last_name': last_name,
      'email': email,
      'phone': phone,
      'profile_picture': profilePictureUrl,
      'preferred_language': preferredLanguage,
      'subscriptions': subscriptions.toJson(), // Non-nullable, so no `?`
      'token': token,
      'name': name,
      'token_type': token_type,
      'is_social': is_social,
      'lang': lang,
      'notifications': notifications,
      'otp_approved': otp_approved,
    };
  }
}

// Define the Subscriptions class here, as it's part of the user domain
@JsonSerializable()
class Subscriptions {
  @JsonKey(name: 'private_car')
  final int privateCar;
  @JsonKey(name: 'university_bus')
  final int universityBus;
  @JsonKey(name: 'school_bus')
  final int schoolBus;

  Subscriptions({
    required this.privateCar,
    required this.universityBus,
    required this.schoolBus,
  });

  factory Subscriptions.fromJson(Map<String, dynamic> json) {
    return Subscriptions(
      privateCar: json['private_car'] as int? ?? 0,
      universityBus: json['university_bus'] as int? ?? 0,
      schoolBus: json['school_bus'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'private_car': privateCar,
      'university_bus': universityBus,
      'school_bus': schoolBus,
    };
  }
}