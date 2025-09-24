import 'package:driverr/presentation/pages/login/secondRegistrationScreen.dart';
import 'package:driverr/presentation/pages/otp_registration/otp_registration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

import '../../../data/datasources/resources/color_manager.dart';
import '../../../data/datasources/resources/values_manager.dart';
import '../../providers/Authentication/login/auth_serviceRegister.dart';
import '../HomePage/HomeScreen.dart';
import 'login_page.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => SignUpScreenState();
}

class SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedGender;
  String? _selectedVehicleType;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validateConfirmPassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.removeListener(_validateConfirmPassword);
    _confirmPasswordController.removeListener(_validateConfirmPassword);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateConfirmPassword() {
    setState(() {});
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select your gender.',
                  style: TextStyle(fontFamily: 'Poppins'))),
        );
        return;
      }
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select your date of birth.',
                  style: TextStyle(fontFamily: 'Poppins'))),
        );
        return;
      }
      // if (_selectedVehicleType == null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //         content: Text('Please select your vehicle type.',
      //             style: TextStyle(fontFamily: 'Poppins'))),
      //   );
      //   return;
      // }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Creating account...',
                style: TextStyle(fontFamily: 'Poppins'))),
      );

      final signUpNotifier = ref.read(signUpProvider.notifier);

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        print('FCM Token: $fcmToken');
      } catch (e) {
        print('Error getting FCM token: $e');
      }

      String? deviceName;
      try {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          deviceName = androidInfo.model;
        } else if (Platform.isIOS) {
          IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
          deviceName = iosInfo.name;
        }
        print('Device Name: $deviceName');
      } catch (e) {
        print('Error getting device name: $e');
      }
      final String formattedBirthDate =
          "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      await signUpNotifier.signUp(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        // vehicleType: _selectedVehicleType!,
        password: _passwordController.text,
        gender: _selectedGender!,
        birthDate: formattedBirthDate,
        confirmPassword: _confirmPasswordController.text,
        fcmToken: fcmToken,
        deviceName: deviceName,
      );

      final state = ref.read(signUpProvider);

      // --- MODIFIED LOGIC ---
      if (state.isSignedUp && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registration successful! Redirecting...',
                  style: TextStyle(fontFamily: 'Poppins'))),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OTPPageRegistration(phoneNumber: _phoneController.text)),
        );
      } else if (state.error != null && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        print('API Response Status: FAILED');
        print('API Response Message: ${state.error!}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${state.error!}',
                  style: const TextStyle(fontFamily: 'Poppins'))),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1920, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Helper widget to build a gender selection button
  Widget _buildGenderOption({required String title, required String value}) {
    final bool isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          decoration: BoxDecoration(
            color:
            isSelected ? ColorManager.lightBlueBackground : Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            border: isSelected
                ? null
                : Border.all(color: ColorManager.lightBlueBackground, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Radio<String>(
                value: value,
                groupValue: _selectedGender,
                onChanged: (String? v) {
                  setState(() {
                    _selectedGender = v;
                  });
                },
                fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.blue;
                  }
                  return ColorManager.transparent;
                }),
              ),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: ColorManager.darkGreyBlue,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// [NEW] Helper widget to build the individual date part containers (Day, Month, Year)
  Widget _buildDatePartDisplay({required String hint, String? value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        value ?? hint,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: value == null
              ? ColorManager.darkGreyBlue.withOpacity(0.7)
              : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int pageCount, int currentPage) {
    // This function implementation remains the same.
    int activeDotIndex = 0;
    List<Widget> visualIndicators = [];
    for (int i = 0; i < 5; i++) {
      visualIndicators.add(
        Container(
          width: i == activeDotIndex ? 16.0 : 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: i == activeDotIndex
                ? ColorManager.blue
                : ColorManager.lightBlueBackground,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: visualIndicators,
    );
  }

  @override
  Widget build(BuildContext context) {
    final signUpState = ref.watch(signUpProvider);
    final bool passwordsMatch = _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSize.s50),
                  Text(
                    "Create Account",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppSize.s32,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.blue,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: AppSize.s40),
                  Text(
                    "Driver's Information",
                    style: TextStyle(
                      fontSize: AppSize.s16,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.darkGreyBlue,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: AppSize.s20),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(fontFamily: 'Poppins'),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: ColorManager.lightBlueBackground,
                            hintText: 'First Name',
                            hintStyle: TextStyle(
                                fontFamily: 'Poppins',
                                color: ColorManager.darkGreyBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16.0),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(fontFamily: 'Poppins'),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: ColorManager.lightBlueBackground,
                            hintText: 'Last Name',
                            hintStyle: TextStyle(
                                fontFamily: 'Poppins',
                                color: ColorManager.darkGreyBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16.0),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your last name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: ColorManager.lightBlueBackground,
                      hintText: "Phone Number",
                      hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          color: ColorManager.darkGreyBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16.0),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (!RegExp(r'^\+?[0-9]{10,}$').hasMatch(value)) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: ColorManager.lightBlueBackground,
                      hintText: 'Email',
                      hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          color: ColorManager.darkGreyBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16.0),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildGenderOption(title: 'Male', value: 'Male'),
                      const SizedBox(width: 16),
                      _buildGenderOption(title: 'Female', value: 'Female'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: ColorManager.lightBlueBackground,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Birth Date',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                color: ColorManager.darkGreyBlue,
                                fontSize: 16),
                          ),
                          Row(
                            children: [
                              _buildDatePartDisplay(
                                hint: 'Day',
                                value: _selectedDate?.day.toString(),
                              ),
                              _buildDatePartDisplay(
                                hint: 'Month',
                                value: _selectedDate?.month.toString(),
                              ),
                              _buildDatePartDisplay(
                                hint: 'Year',
                                value: _selectedDate?.year.toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                      hintText: "Password",
                      hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          color: ColorManager.darkGreyBlue),
                      filled: true,
                      fillColor: ColorManager.lightBlueBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16.0),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility,
                          color: ColorManager.darkGreyBlue,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                      hintText: 'Confirm Password',
                      hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          color: ColorManager.darkGreyBlue),
                      filled: true,
                      fillColor: ColorManager.lightBlueBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16.0),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility,
                          color: ColorManager.darkGreyBlue,
                        ),
                        onPressed: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  if (passwordsMatch)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0, left: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Passwords match',
                            style: TextStyle(
                                color: Colors.green,
                                fontFamily: 'Poppins',
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: AppSize.s60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: signUpState.isLoading ? null : _createAccount,
                      child: signUpState.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Next Step",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppSize.s18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSize.s24),
                  _buildPageIndicator(5, 4),
                  const SizedBox(height: AppSize.s24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}