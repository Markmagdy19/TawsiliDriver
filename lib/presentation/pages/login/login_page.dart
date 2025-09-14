import 'package:driverr/presentation/pages/login/signUpPage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import '../../../data/datasources/resources/assets_manager.dart';
import '../../../data/datasources/resources/color_manager.dart';
import '../../../data/datasources/resources/values_manager.dart';
import '../../providers/Authentication/login/auth_service-login.dart';
import '../../providers/Authentication/login/login_auth.dart';
import '../HomePage/HomeScreen.dart';
import 'forgetPasswordPage.dart';


class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  // String _countryCode = '+966';

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

// In login_page.dart

  Future<String?> _getFcmToken() async {
    try {
      // Request permission first
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Proceed only if permission is granted
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? fcmToken = await messaging.getToken();
        print("FCM Token: $fcmToken");
        return fcmToken;
      } else {
        print('User declined or has not accepted permission');
        return null;
      }
    } catch (e) {
      print("Error getting FCM token: $e");
      return null;
    }
  }





  // Helper function to get Device Name
  Future<String?> _getDeviceName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.model; // Or androidInfo.device, androidInfo.brand, etc.
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name;
      } else {
        // Handle other platforms if necessary
        return null;
      }
    } catch (e) {
      print("Error getting device name: $e");
      return null;
    }
  }

// In login_page.dart

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      // Show a loading indicator to the user
      // ...

      final String? fcmToken = await _getFcmToken();
      final String? deviceName = await _getDeviceName();

      // --- CRITICAL CHECK ---
      if (fcmToken == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not initialize notifications. Please check your connection and try again.')),
        );
        // Hide loading indicator if you showed one
        return; // Stop the login process
      }

      try {
        await ref.read(authProvider.notifier).login(
          _phoneController.text,
          _passwordController.text,
          fcmToken: fcmToken,
          deviceName: deviceName,
        );

        final state = ref.read(authProvider);
        if (state.isAuthenticated && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else if (state.error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgetPasswordPage()),
    );
  }

  void _navigateToCreateAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }


  Widget _buildSocialSignInButton({
    required String label,
    required Widget icon,
    required VoidCallback onPressed,
    Color backgroundColor = ColorManager.lightBlueBackground,
    Color textColor = ColorManager.grey5,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          // Text color for the button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0), // Rounded corners
          ),
          side: BorderSide.none,
          // Explicitly remove the border
          padding: const EdgeInsets.symmetric(
              vertical: 15.0, horizontal: 10.0), // Adjust padding
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Center(child: icon),
            ),
            const SizedBox(width: 8.0),
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.normal,
                  color: textColor,
                  fontFamily: 'Poppins', // Added Poppins font
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSocialSignInButtons(AuthService authService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSocialSignInButton(
            backgroundColor: ColorManager.lightBlueBackground,
            label: 'Apple'.tr(),
            icon: const Icon(
                FontAwesomeIcons.apple, color: Colors.black, size: 20),
            onPressed: () => authService.signInWithApple(), // FIX: Add parentheses to call the function
            textColor: ColorManager.darkGreyBlue,
          ),
          const SizedBox(width: 15.0),
          _buildSocialSignInButton(
            backgroundColor: ColorManager.lightBlueBackground,
            label: 'Google'.tr(),
            icon: Image.asset(ImageAssets.google, height: 20.0),
            onPressed: () => authService.handleGoogleBtnClick(context,ref),
            textColor: ColorManager.darkGreyBlue,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authService = ref.read(authServiceProvider);


    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold( // The Scaffold must be the child of PopScope
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                // Ensure _formKey is defined in your StatefulWidget
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Sign_In".tr(),
                      style: TextStyle(
                        fontSize: AppSize.s32,
                        fontWeight: FontWeight.w600,
                        color: ColorManager.blue,
                        fontFamily: 'Poppins', // Added Poppins font
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Welcoming_message".tr(),
                      style: TextStyle(
                        fontSize: AppSize.s14,
                        color: ColorManager.darkGreyBlue,
                        fontFamily: 'Poppins', // Added Poppins font
                      ),
                    ),
                    const SizedBox(height: 88),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      // Ensure _phoneController is defined
                      keyboardType: TextInputType.phone,
                      // Added inputFormatters to allow only digits
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: ColorManager.lightBlueBackground,
                        hintText: "Phone_Number".tr(),
                        hintStyle: TextStyle(fontFamily: 'Poppins'), // Added Poppins font to hintText
                        border: OutlineInputBorder( // Apply circular border
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none, // No border by default
                        ),
                        // Re-added focusedBorder to be blue
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: ColorManager.blue,
                              width: 1.0), // Blue border when focused
                        ),
                        enabledBorder: OutlineInputBorder( // Apply circular border
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none, // No border when enabled
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 16.0),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        // Check if the value contains only digits
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'Please enter only numbers';
                        }
                        if (value.length < 10) {
                          return 'Phone number must be at least 10 digits';
                        }
                        return null;
                      },
                      style: TextStyle(fontFamily: 'Poppins'), // Added Poppins font to input text
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      // Ensure _passwordController is defined
                      obscureText: _obscurePassword,
                      // Ensure _obscurePassword is defined and managed with setState
                      decoration: InputDecoration(
                        hintText: "password".tr(),
                        hintStyle: TextStyle(fontFamily: 'Poppins'), // Added Poppins font to hintText
                        filled: true,
                        fillColor: ColorManager.lightBlueBackground,
                        border: OutlineInputBorder( // Apply circular border
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none, // No border by default
                        ),
                        // Re-added focusedBorder to be blue
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: ColorManager.blue,
                              width: 1.0), // Blue border when focused
                        ),
                        enabledBorder: OutlineInputBorder( // Apply circular border
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none, // No border when enabled
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 16.0),

                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            // This setState implies your widget is a StatefulWidget
                            // Ensure this build method is within a StatefulWidget
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please_enter_your_password".tr();
                        }
                        if (value.length < 6) {
                          return "Password_must_be_at_least_6_characters".tr();
                        }
                        return null;
                      },
                      style: TextStyle(fontFamily: 'Poppins'), // Added Poppins font to input text
                    ),
                    const SizedBox(height: 8),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _navigateToForgotPassword,
                        // Ensure _navigateToForgotPassword is defined
                        child: Text(
                          "forgetPasswordQuestion".tr(),
                          style: TextStyle(color: ColorManager.grey5, fontFamily: 'Poppins'), // Added Poppins font
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSize.s16),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text("Or".tr(), style: TextStyle(
                              color: ColorManager.black,
                              fontSize: AppSize.s14,
                              fontFamily: 'Poppins'),),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Social login - Using the new function
                    // Ensure buildSocialSignInButtons is defined and takes AuthService
                    buildSocialSignInButtons(authService),

                    const SizedBox(height: 50),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: AppSize.s60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        // Ensure _login is defined and handles the login logic
                        // and that authState.isLoading correctly reflects loading state
                        onPressed: authState.isLoading ? null : _login,
                        child: Text("Login".tr(), style: TextStyle(
                            color: Colors.white, fontFamily: 'Poppins')), // Added Poppins font
                      ),
                    ),
                    const SizedBox(height: AppSize.s16),

                    // Sign Up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don_have_an_account".tr(), style: TextStyle(fontFamily: 'Poppins')), // Added Poppins font
                        TextButton(
                          onPressed: _navigateToCreateAccount,
                          // Ensure _navigateToCreateAccount is defined
                          child: Text(
                            "Sign_Up".tr(),
                            style: TextStyle(
                              color: ColorManager.blue,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins', // Added Poppins font
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ), // Closing parenthesis for Scaffold and then PopScope
    );
  }
}