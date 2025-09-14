import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/app/constants.dart';


class SignUpState {
  final bool isLoading;
  final String? error;
  final bool isSignedUp;

  SignUpState({this.isLoading = false, this.error, this.isSignedUp = false});

  SignUpState copyWith({bool? isLoading, String? error, bool? isSignedUp}) {
    return SignUpState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSignedUp: isSignedUp ?? this.isSignedUp,
    );
  }
}


final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));
});

class AuthServiceRegistration {
  final Dio _dio;

  AuthServiceRegistration(this._dio);


  Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword, // Add confirmPassword parameter
    String? fcmToken,
    required String gender, // ADD THIS LINE
    required String birthDate, // ADD THIS LINE
    required String vehicleType, // ADD THIS LINE

    String? deviceName,
  }) async {
    try {
      final response = await _dio.post(
        '${Constants.baseUrl1}/driver/auth/register',
        data: {
          'name': firstName + lastName,
          'phone': phone,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
          'type': 'car',
          'gender': gender.toLowerCase(), // ADD THIS LINE
          'fcm_token': fcmToken,
          'birthdate': birthDate,
          'device_name': deviceName,
        },
      );

      if (response.statusCode == 200) {
        if (response.data['status'] == true) {
          return {
            'success': true,
            'data': response.data['data'],
            'message': response.data['message'],
          };
        } else {
          return {
            'success': false,
            'message': response.data['message'] ?? 'Registration failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Server error: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error occurred';
      if (e.response != null) {
        errorMessage = e.response!.data['message'] ?? 'Error: ${e.response!.statusCode}';
      } else {
        errorMessage = e.message ?? 'Unknown network error';
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    try {
      final response = await _dio.post(
        '${Constants.baseUrl1}/client/auth/resendOtp',
        data: {
          'phone': phoneNumber, // Changed key from 'phone_number' to 'phone'
        },
      );

      print('OTP API Response Status Code: ${response.statusCode}');
      print('OTP API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'OTP sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to send OTP - Server error: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('OTP DioException: ${e.message}');
      print('OTP DioException Response: ${e.response?.data}');
      String errorMessage = 'Network error occurred during OTP request';
      if (e.response != null) {
        errorMessage = e.response!.data['message'] ?? 'Error: ${e.response!.statusCode}';
      } else {
        errorMessage = e.message ?? 'Unknown network error';
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('OTP Unexpected Error: ${e.toString()}');
      return {
        'success': false,
        'message': 'An unexpected error occurred during OTP request: ${e.toString()}',
      };
    }
  }
}


final AuthServiceProvider = Provider((ref) => AuthServiceRegistration(ref.read(dioProvider)));


class SignUpNotifier extends StateNotifier<SignUpState> {
  final AuthServiceRegistration _signUpAuthService;

  SignUpNotifier(this._signUpAuthService) : super(SignUpState());

  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword,
    required String gender, // ADD THIS LINE
    required String birthDate,
    required String vehicleType, // ADD THIS LINE
    String? fcmToken,
    String? deviceName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _signUpAuthService.registerUser(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        vehicleType: 'car',
        gender: gender, // ADD THIS LINE
        birthDate: birthDate,
        fcmToken: fcmToken,
        deviceName: deviceName,
      );

      if (result['success']) {
        state = state.copyWith(isLoading: false, isSignedUp: true);
        print('Registration successful: ${result['message']}');
        print('User Token: ${result['data']['user']['token']}');
      } else {
        state = state.copyWith(isLoading: false, error: result['message'], isSignedUp: false);
        print('Registration failed: ${result['message']}');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), isSignedUp: false);
      print('An error occurred during signup: $e');
    }
  }

  Future<bool> requestOtpForPhoneNumber(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _signUpAuthService.requestOtp(phoneNumber);
      if (result['success']) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result['message']);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final signUpProvider = StateNotifierProvider<SignUpNotifier, SignUpState>(
      (ref) => SignUpNotifier(ref.read(AuthServiceProvider)),
);