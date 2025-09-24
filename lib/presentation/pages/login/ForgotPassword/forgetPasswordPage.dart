import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // Ensure Dio is imported for DioException
import '../../../../data/datasources/resources/color_manager.dart';
import '../../../../data/datasources/resources/values_manager.dart';
import '../../../utils/routes_manager.dart';
import 'Auth_service.dart';



class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  // FIX 1: Renamed _PhoneController to _phoneController for Dart naming conventions
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthServiceForget _authService = AuthServiceForget();

  bool _isLoading = false;

  @override
  void dispose() {
    // FIX 2: Disposing the correctly named controller
    _phoneController.dispose();
    super.dispose();
  }

  // Helper method to show SnackBars consistently (already good)
  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.red, // Default to red for errors
      ),
    );
  }

  // Inside your _ForgetPasswordPageState in forget_password_page.dart

  Future<void> _onContinuePressed() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      // FIX 3: Using the correctly named controller
      final String phoneNumber = _phoneController.text.trim();
      // const String apiUrl ='${Constants.baseUrl1}/client/auth/forgot-password'; // This variable is not used and can be removed.
      // The API URL is now managed within AuthServiceForget

      // Define necessary headers. Only include what's truly needed for this request.
      final Map<String, dynamic> customHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // 'X-Requested-With': 'XMLHttpRequest', // Add if your API specifically requires it
        // 'Authorization': 'Bearer YOUR_AUTH_TOKEN', // Add if this endpoint requires authentication
      };

      try {
        // Call the service method. The service itself will construct the URL and make the POST request.
        Map<String, dynamic> apiResponse = await _authService.sendOtpAndCheckNumber(phoneNumber, customHeaders);

        print('\n--- API Response Details ---');
        print('Message: ${apiResponse['message']}');
        print('Status: ${apiResponse['status']}');
        print('--------------------------\n');

        if (apiResponse['status'] == true) { // Check for status true for success
          // Navigate to OTP screen only on successful OTP send
          if (mounted) { // Check if the widget is still mounted before navigating
            // FIX 4: Ensure phoneNumber is correctly passed as argument
            Navigator.pushNamed(
              context,
              Routes.resetPasswordRoute, // Navigate to resetPasswordRoute
              arguments: phoneNumber, // Pass the phoneNumber as an argument
            );

            _showSnackBar('OTP sent successfully to: $phoneNumber', backgroundColor: Colors.green);
          }
        } else {
          // Handle cases where status is false but no DioException was thrown
          String message = apiResponse['message'] ?? 'Phone number not found or OTP could not be sent.';
          _showSnackBar(message, backgroundColor: Colors.orange); // Indicate a non-critical issue
        }
      } on DioException catch (e) {
        // This catch block remains the same as it handles DioExceptions re-thrown from AuthServiceForget
        String errorMessage = 'Failed to connect to the server. Please check your internet connection.';
        if (e.response != null) {
          if (e.response!.data is Map<String, dynamic> && e.response!.data.containsKey('message')) {
            errorMessage = e.response!.data['message'];
          } else {
            errorMessage = 'API error: ${e.response!.statusCode} - ${e.response!.statusMessage}';
          }
        }
        _showSnackBar(errorMessage, backgroundColor: Colors.red);
        print('Error during phone number check: $e');
      } catch (e) {
        _showSnackBar('An unexpected error occurred. Please try again.', backgroundColor: Colors.red);
        print('Unexpected error: $e');
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSize.s24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSize.s20),
                Text(
                  "Forgot_Password".tr(),
                  style: TextStyle(
                    fontSize: AppSize.s32,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.blue,
                  ),
                ),
                const SizedBox(height: AppSize.s60),
                TextFormField(
                  // FIX 5: Using the correctly named controller
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: "Mobile_Number".tr(),
                    hintStyle: TextStyle(color: ColorManager.grey5),
                    filled: true,
                    fillColor: ColorManager.lightBlueBackground,
                    contentPadding: const EdgeInsets.symmetric(vertical: AppSize.s16, horizontal: AppSize.s16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: ColorManager.blue, width: 1.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please_enter_your_phone_number".tr(); // Field is required
                    }


                    if (value.length < 7) {
                      return "Phone_number_must_be_at_least_7_digits_long".tr();
                    }

                    return null;
                  },
                ),
                // FIX 6: Added const where appropriate for performance
                const SizedBox(height: AppSize.s32),
                SizedBox(
                  width: double.infinity,
                  height: AppSize.s60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onContinuePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white) // FIX 7: Added const
                        : Text(
                      "Continue".tr(),
                      style: const TextStyle( // FIX 8: Added const
                        fontSize: AppSize.s16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(isActive: true),
                      const SizedBox(width: AppSize.s12),
                      _buildDot(isActive: false),
                      const SizedBox(width:AppSize.s12),
                      _buildDot(isActive: false),
                    ],
                  ),
                ),
                const SizedBox(height: AppSize.s24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot({required bool isActive}) {
    return Container(
      width: AppSize.s32,
      height: 4,
      decoration: BoxDecoration(
        color: isActive ? ColorManager.blue : ColorManager.grey5,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}