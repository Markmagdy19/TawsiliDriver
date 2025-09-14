
import '../user/user.dart';

class LoginResponse {
  final String message;
  final bool status;
  final LoginData data;

  LoginResponse({
    required this.message,
    required this.status,
    required this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'],
      status: json['status'],
      data: LoginData.fromJson(json['data']),
    );
  }
}


class LoginData {
  final User user;

  LoginData({
    required this.user,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      user: User.fromJson(json['user']),
    );
  }
}