import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/pages/login/login_page.dart';
import '../../presentation/pages/login/secondRegistrationScreen.dart';
import '../../presentation/pages/onBoarding/onBoarding_view.dart';
import '../../presentation/providers/Authentication/login/auth_service-login.dart';
import '../app/app_preference.dart';
import '../datasources/resources/routes_manager.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  void _navigate(BuildContext context, WidgetRef ref, AppPreferences appPreferences) async {

    if (appPreferences.isOnBoardingScreenViewed()) {
      log("Onboarding has been viewed. Checking token validity.");

      final authService = ref.read(authServiceProvider);
      final bool isTokenValid = await authService.validateTokenApi();

      if (isTokenValid) {
        log("Token is valid. Navigating to Home.");

        Navigator.of(context).pushReplacementNamed(Routes.HomeRoute);
      } else {
        log("Token is invalid. Navigating to Login.");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const VehicleInfoScreen()),
        );
      }
    } else {
      log("Onboarding has NOT been viewed, navigating to Onboarding.");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnBoardingView()),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The `listen` method is the correct place to trigger navigation.
    // It only runs when the state of `sharedPreferencesProvider` changes.
    ref.listen<AsyncValue<SharedPreferences>>(sharedPreferencesProvider, (previous, next) {
      next.when(
        data: (prefs) {
          final appPreferences = AppPreferences(prefs);
          _navigate(context, ref, appPreferences); // Pass ref to the _navigate function
        },
        error: (error, stackTrace) {
          log("Error loading SharedPreferences: $error. Navigating to Onboarding as a fallback.");
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnBoardingView()),
          );
        },
        loading: () {},
      );
    });

    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image(
          image: AssetImage('assets/images/png/logo.png'),
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}