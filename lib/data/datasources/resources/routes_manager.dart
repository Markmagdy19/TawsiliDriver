import 'package:driverr/data/datasources/resources/strings_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../presentation/pages/HomePage/HomeScreen.dart';
import '../../../presentation/pages/login/login_page.dart';
import '../../../presentation/pages/login/secondRegistrationScreen.dart';
import '../../../presentation/pages/onBoarding/onBoarding_view.dart';
import '../../app/splash_screen.dart';
// import 'package:tawsilii/presentation/resources/strings_manager.dart';
// import '../Authentication/OTP/otp_page.dart';
// import '../Authentication/Login/login_page.dart';
// import '../Authentication/newPassword/reset_password_screen.dart';
// import '../FAQS/FAQS.dart';
// import '../Historical Data & Reports/filter_screen.dart';
// import '../Home/Home_screen.dart';
// import '../Notifications/Notification_screen.dart';
// import '../School_bus/school-bus-tracking.dart';
// import '../School_bus/subscription_code_entry.dart';
// import '../Terms-privacy-policy/terms-privacy-policy.dart';
// import '../chat/chat_driver/chat_driver_screen.dart';
// import '../complaint/complaint.dart';
// import '../complaint/support/support_screen.dart';
// import '../knoweldge-base/knoweldge_base.dart';
// import '../live_tracking/live-tracking-page-uni-bus.dart';
// import '../live_tracking/live_tracking_page-priv-car.dart';
// import '../onBoarding/onBoarding_view.dart';
// import '../privateCar/PrivateCar_subscription/private_car.dart';
// import '../privateCar/Subscription_private_car_package/subscription_details.dart';
// import '../privateCar/ride-details-screen/ride-details-screen.dart';
// import '../profile_setup/manage-active-sessions.dart';
// import '../profile_setup/profile_setup/profile_setup_page.dart';
// import '../profile_setup/profile_setup/profile_side_menu.dart';
// import '../profile_setup/welcome_profile/welcome_profile_screen.dart';
// import '../settings/settings_page.dart';
// import '../university_bus/university_bus_subscription_screen.dart';



class Routes {
  static const String loginRoute = "/login";
  static const String notificationRoute = "/notification";
  static const String registerRoute = "/register";
  static const String forgotPasswordRoute = "/forgotPassword";
  static const String onBoardingRoute = "/onBoarding";
  static const String splashRoute = "/splash";

  static const String OTP = "/OTP";
  static const String ProfileSetup = "/ProfileSetup";
  static const String HomeRoute = '/Home';
  static const String profileSideMenuRoute = '/profileSideMenu';
  static const String WelcomeRoute = '/Welcome';
  static const String settingsRoute = '/settings';
  static const String CancelRoute = '/Cancel';
  static const String CancelRoute2 = '/Cancel2';
  static const String supportRoute = '/support';
  static const String filterRoute = '/filter';
  static const String PrivCardetailsRoute = '/PrivCardetails';
  // static const String UniBusdetailsRoute = '/UniBusdetails';
  static const String complaintRoute = '/complaint';
  static const String verifySchoolBusTrackingService  ='/verifySchoolBusTrackingService';
  static const String KnoweledgeBaseRoute = '/KnoweledgeBase';
  static const String KnoweledgeBaseDetailsRoute = '/KnoweledgeBaseDetails';
  static const String TrackRoute = '/Track';
  static const String CustomizedRouteTimeConfirmationRoute = '/CustomizedRouteTimeConfirmation';
  static const String FAQSRoute = '/FAQS';
  static const String FAQSDetailsRoute = '/FAQSDetails';
  static const String SchoolBusTrackRoute = '/SchoolBusTrack';
  static const String PrivacyPolicyRoute = '/PrivacyPolicy';
  static const String  resetPasswordRoute = '/resetPassword';
  static const String   chatDriverRoute = '/Driverchat';
  static const String   AddPrivCarRoute = '/addprivCar';
  static const String RideDetailsprivRoute = '/rideDetailpriv';
  static const String TrackRouteUniBus = 'trackUniBus';
  static const String   AddUniBusRoute = '/addunibus';

  static const String ActiveSessionsRoute = '/ActiveSession';


}


class RouteGenerator {
  static Route<dynamic>? getRoute(RouteSettings settings) {
    switch (settings.name) {





      case Routes.splashRoute:
        return MaterialPageRoute(builder: (_) => SplashScreen());
    //////////////////////////////////////////////////////////

      case Routes.HomeRoute:
        return MaterialPageRoute(builder: (_) => HomeScreen());
    //////////////////////////////////////////////////////////

      case Routes.loginRoute:
        return MaterialPageRoute(builder: (_) => VehicleInfoScreen());
    //////////////////////////////////////////////////////////


      case Routes.onBoardingRoute:
        return MaterialPageRoute(builder: (_) => OnBoardingView());
    //////////////////////////////////////////////////////////


      default:
        return unDefinedRoute();
    }}

  static Route<dynamic> unDefinedRoute() {
    return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.noRouteFound.tr()),
          ),
          body: Center(child: Text(AppStrings.noRouteFound.tr())),
        ));
  }
}