// auth_service-login.dart
import 'dart:io';
import 'dart:developer';
import 'dart:convert';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as FBAuth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/app/constants.dart';
import '../../../../data/app/utils.dart';
import '../../../../data/datasources/resources/language/language_notifier.dart';
import '../../../../data/models/loginResponse/loginResponse.dart';
import '../../../../data/models/user/user.dart';
import '../../../pages/HomePage/HomeScreen.dart';

/// Interceptor to add the current app language to the 'Accept-Language' header.
class LanguageInterceptor extends Interceptor {
  final Ref _ref;

  LanguageInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Read the current locale from the provider
    final locale = _ref.read(localeProvider);
    // Set the language code in the header
    options.headers['Accept-Language'] = locale.languageCode;
    log('LanguageInterceptor: Added "Accept-Language: ${locale.languageCode}" to header.');
    super.onRequest(options, handler);
  }
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    followRedirects: true,
    maxRedirects: 5,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Add the custom language interceptor
  dio.interceptors.add(LanguageInterceptor(ref));

  // Add the pretty logger for debugging
  dio.interceptors.add(
    PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: false,
    ),
  );

  return dio;
});

class AuthService {
  final Dio _dio;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FBAuth.FirebaseAuth _firebaseAuth = FBAuth.FirebaseAuth.instance;
  static const String _tokenKey = 'client_token';
  static const String _userProfileKey = 'user_profile';

  AuthService(this._dio);

  // Methods from the old 'APIs' class are now instance methods here
  Stream<FBAuth.User?> authStateChanges() => _firebaseAuth.authStateChanges();
  String getUserEmail() => _firebaseAuth.currentUser?.email ?? "User";

  // Note: The userExists() and createUser() methods are now legacy
  // if you fully switch to the /client/auth/social endpoint.
  // They are kept here for reference or if used elsewhere.
  Future<bool> userExists() async {
    await Future.delayed(const Duration(seconds: 1));
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      log('AuthService.userExists: No current user logged in.');
      return false;
    }

    try {
      final response = await _dio.get('${Constants.baseUrl}/v1/users/${user.uid}/exists');
      log('AuthService.userExists: Checking for user with UID: ${user.uid}. Status: ${response.statusCode}');
      return response.statusCode == 200 && response.data['exists'] == true;
    } on DioException catch (e) {
      log('Error checking user existence via API: ${e.message}');
      return false;
    }
  }

  Future<void> createUser() async {
    await Future.delayed(const Duration(seconds: 1));
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      log('AuthService.createUser: No current user to create a profile for.');
      return;
    }

    try {
      await _dio.post('${Constants.baseUrl}/v1/users', data: {
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName,
        // Add other initial user data
      });
      log('AuthService.createUser: User profile created for UID: ${user.uid} via API.');
    } on DioException catch (e) {
      log('Error creating user profile via API: ${e.message}');
    }
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    log('Token saved to SharedPreferences: $token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<User?> getUserProfileFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final userJsonString = prefs.getString(_userProfileKey);
    if (userJsonString != null) {
      return User.fromJson(jsonDecode(userJsonString));
    }
    return null;
  }

  Future<void> deleteTokenAndProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userProfileKey);
    log('Token and User Profile deleted from SharedPreferences');
  }

  Future<bool> validateTokenApi() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      log('validateTokenApi: No token found. Returning false.');
      return false;
    }

    try {
      log('validateTokenApi: Attempting to validate token with backend...');
      final url = '${Constants.baseUrl1}/client/auth/validate-token';
      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      ).timeout(const Duration(seconds: 15));

      log('validateTokenApi: Response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        log('validateTokenApi: Token is valid. Returning true.');
        return true;
      } else {
        log('validateTokenApi: Token validation failed. Unexpected status code: ${response.statusCode}. Returning false.');
        return false;
      }
    } on TimeoutException {
      log('validateTokenApi: Request timed out. Returning false.');
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        log('validateTokenApi: Token invalid or expired (401/403). Deleting token and returning false.');
        await deleteTokenAndProfile();
      } else {
        log('validateTokenApi: DioException occurred. Message: ${e.message}. Status code: ${e.response?.statusCode}. Returning false.');
      }
      return false;
    } catch (e) {
      log('validateTokenApi: An unexpected error occurred. Error: $e. Returning false.');
      return false;
    }
  }




  Future<String?> getFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      log('FCM Token: $fcmToken');
      return fcmToken;
    } catch (e) {
      log('Error getting FCM token: $e');
      return null;
    }
  }


  Future<String?> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.model; // e.g., "Pixel 7"
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name; // e.g., "Mark's iPhone"
      }
    } catch (e) {
      log('Error getting device name: $e');
    }
    return null;
  }



// ## MODIFIED GOOGLE SIGN-IN HANDLER ##
  Future<void> handleGoogleBtnClick(BuildContext context, WidgetRef ref) async {
    Dialogs.showProgressBar(context);
    try {
      // Step 1: Sign in with Google to get user credentials and the ID token.
      final FBAuth.UserCredential? userCredential = await _signInWithGoogle(context);

      if (userCredential?.user != null) {
        final user = userCredential!.user!;
        log('Google Sign-In Success. User UID: ${user.uid}');



        final displayName = user.displayName ?? '';
        final names = displayName.split(' ');
        final firstName = names.isNotEmpty ? names.first : '';
        final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        final String SocialToken = googleUser!.id;

        final fcmToken = await getFcmToken();
        final deviceName = await getDeviceName();

        // Step 4: Call your backend's social login endpoint.
        final authService = ref.read(authServiceProvider);
        await authService.signInWithSocial(
          email: user.email ?? '',
          firstName: firstName,
          lastName: lastName,
          socialToken: SocialToken,
          socialType: 'google',
          fcmToken: fcmToken,     // Pass the actual FCM token
          deviceName: deviceName, // Pass the actual device name
        );

        // Step 5: If successful, navigate to the home screen.
        ref.invalidate(userProfileProvider);
        Navigator.pop(context); // Dismiss the progress bar
        if (context.mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => HomeScreen()));
        }

      } else {
        // This case handles when the user cancels the Google Sign-In prompt.
        Navigator.pop(context); // Dismiss the progress bar
      }
    } catch (error) {
      log('Error during Google Sign-In flow: $error');
      if(Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      if (context.mounted) {
        Dialogs.showSnackbar(context, 'Failed to sign in: ${error.toString().replaceFirst("Exception: ", "")}');
      }
    }
  }

  Future<FBAuth.UserCredential?> _signInWithGoogle(BuildContext context) async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException('No internet connection');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = FBAuth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      log('_signInWithGoogle error: $e');
      if (context.mounted) {
        String errorMessage = 'Something Went Wrong (Check Internet!)';
        if (e is SocketException) {
          errorMessage = 'No internet connection';
        } else if (e is FBAuth.FirebaseAuthException) {
          errorMessage = e.message ?? 'Firebase Auth error';
        }
        Dialogs.showSnackbar(context, errorMessage);
      }
      // Re-throw the exception so the calling function can handle it
      throw e;
    }
  }

  Future<User> fetchUserFromApi(String token) async {
    try {
      final url = '${Constants.baseUrl1}/client/get-profile';
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data['data'] as Map<String, dynamic>;
        final userData = responseData['user'] as Map<String, dynamic>;
        final subscriptionsData = responseData['subscriptions'] as Map<String, dynamic>;
        userData['subscriptions'] = subscriptionsData;
        return User.fromJson(userData);
      } else {
        throw Exception('Failed to fetch user data');
      }
    } on DioException catch (e) {
      throw Exception('Error fetching user data: ${e.message}');
    }
  }

  Future<User> login(String phoneNumber, String password, {String? fcmToken, String? deviceName}) async {
    try {
      log('⏳ Attempting login with phone: $phoneNumber');
      final url = '${Constants.baseUrl1}/driver/auth/login';

      final response = await _dio.post(
        url,
        data: {
          'phone': phoneNumber,
          'password': password,
          'fcm_token': fcmToken,
          'device_name': deviceName,
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;
        if (responseData is! Map<String, dynamic>) {
          log('❌ Invalid server response: Expected a JSON object, but received ${responseData.runtimeType}.');
          throw Exception('Login failed: Invalid server response.');
        }

        final loginResponse = LoginResponse.fromJson(responseData);

        if (loginResponse.status) {
          final token = loginResponse.data.user.token;
          if (token != null && token.isNotEmpty) {
            await saveToken(token);
            log('🔑 Token received and saved: ${token.substring(0, 10)}...');

            final User user = await fetchUserFromApi(token);
            log('🎉 Login successful! User profile fetched and saved.');
            return user;
          } else {
            log('⚠️ No token received in response or token is empty');
            throw Exception('Token not found in login response');
          }
        } else {
          log('❌ Login API returned status false: ${loginResponse.message}');
          throw Exception(loginResponse.message);
        }
      } else {
        log('❌ Login failed - Status code: ${response.statusCode}');
        throw Exception('Login failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Login failed';
      log('🚨 Throwing error: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      log('❌ Unexpected error: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  Future<User> signInWithSocial({
    required String firstName,
    required String lastName,
    required String email,
    required String socialToken,
    required String socialType,
    String? fcmToken,
    String? deviceName,
  }) async {
    try {
      log('⏳ Attempting social login with type: $socialType');
      final url = '${Constants.baseUrl1}/client/auth/social';

      final response = await _dio.post(
        url,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'social_token': socialToken,
          'social_type': socialType,
          'fcm_token': fcmToken,
          'device_name': deviceName,
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;
        if (responseData is! Map<String, dynamic>) {
          log('❌ Invalid server response: Expected a JSON object, but received ${responseData.runtimeType}.');
          throw Exception('Social login failed: Invalid server response.');
        }

        // Assuming the social login response is the same structure as the normal login
        final loginResponse = LoginResponse.fromJson(responseData);

        if (loginResponse.status) {
          final token = loginResponse.data.user.token;
          if (token != null && token.isNotEmpty) {
            await saveToken(token);
            log('🔑 Social Login: Token received and saved.');

            // Fetch the full user profile from your API using the new token
            final User user = await fetchUserFromApi(token);
            log('🎉 Social login successful! User profile fetched.');
            return user;
          } else {
            log('⚠️ No token received in social login response.');
            throw Exception('Token not found in social login response');
          }
        } else {
          log('❌ Social login API returned status false: ${loginResponse.message}');
          throw Exception(loginResponse.message);
        }
      } else {
        log('❌ Social login failed - Status code: ${response.statusCode}');
        throw Exception('Social login failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Social login failed';
      log('🚨 DioException during social login: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      log('❌ Unexpected error during social login: $e');
      throw Exception('An unexpected error occurred during social login');
    }
  }

  Future<void> signUp({
    required String name,
    required String phone,
    required String password,
    required String email,
    required String birthdate,
    required String gender,

    String? fcmToken,
    String? deviceName,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    log(
        'Signing up with: Name: $name, Phone: $phone, Password: $password, FCM Token: $fcmToken, Device Name: $deviceName');
    try {
      final response = await _dio.post(
          '${Constants.baseUrl1}/driver/auth/register',
          data: {
            'name': name,
            'email':email,
            'birthdate':birthdate,
            'gender': gender,
            'phone': phone,
            'password': password,
            'fcm_token': fcmToken,
            'device_name': deviceName,
          });
      if (response.statusCode == 200) {
        log('Signup successful!');
      } else {
        throw Exception(response.data['message'] ?? 'Signup failed');
      }
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  Future<FBAuth.UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes:[AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,] );
      final oAuthCredential = FBAuth.OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode
      );
      return await _firebaseAuth.signInWithCredential(oAuthCredential);
    }catch (e){
      print("Error During sign in with Apple: $e");
      return null;
    }
  }

  Future<void> logoutBackend() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        log('No token found for logout.');
        return;
      }

      final response = await _dio.post(
        '${Constants.baseUrl1}/driver/auth/logout',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        log('Successfully logged out from backend.');
      } else {
        log('Backend logout failed with status: ${response.statusCode}. Data: ${response.data}');
      }
    } on DioException catch (e) {
      log('Error during backend logout: ${e.message}');
    } catch (e) {
      log('An unexpected error occurred during backend logout: $e');
    }
  }

  Future<void> signOut(WidgetRef ref)async{
    await _firebaseAuth.signOut();
    await deleteTokenAndProfile();
    await logoutBackend();
    // ref.invalidate(upcomingRidesProvider);
    ref.invalidate(userProfileProvider);
  }
}

final authServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AuthService(dio);
});

final userProfileProvider = FutureProvider<User>((ref) async {
  final authService = ref.watch(authServiceProvider);

  final token = await authService.getToken();

  if (token == null || token.isEmpty) {
    throw Exception('User is not authenticated.');
  }

  return authService.fetchUserFromApi(token);
});