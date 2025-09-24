import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/datasources/resources/color_manager.dart';
import '../../../data/models/card/card-model.dart';
import '../../../data/models/user/user.dart' as user_model;
import '../../../data/repositories/Home_Api_service.dart';
import '../../providers/Authentication/login/auth_service-login.dart';
import '../../utils/routes_manager.dart';
import '../../widgets/Navigation_Bottom/navigation_bottom.dart';
import '../../widgets/dotted-line.dart';
import '../Notifications/Notification_screen.dart';
import '../ProfileSideMenu/profile_side_menu.dart';
import '../chat/chat_Response/chat_Screen_History.dart';
import '../complaint/support/support_screen.dart';
import '../requestsScreen/requestsScreen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = <Widget>[
      RefreshIndicator(
        onRefresh: _refreshData,
        child: const _HomeScreenContent(),
      ),
      // This is the RequestsScreen
      const RequestsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    if (index < _pages.length) {
      setState(() {
        _selectedIndex = index;
      });
    }

    switch (index) {
      case 0:
        // This is the current screen, so no navigation is needed.
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ProfileSideMenu()),
        );
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const RequestsScreen()),
        );
        break;
      case 3:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SupportPage()),
          );
        break;

      case 4:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const NotificationScreen()),
        );
        break;
    }
  }

  Future<void> _refreshData() async {
    ref.invalidate(upcomingRidesProvider);
    ref.invalidate(userProfileProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.white,
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: const ProfileSideMenu(),
      ),

      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBottom(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      extendBody: true,
    );
  }
}

enum PickDropOption { allNotAttending, pickUpNotAttending, dropOffNotAttending }

class _HomeScreenContent extends ConsumerStatefulWidget {
  const _HomeScreenContent();

  @override
  ConsumerState<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends ConsumerState<_HomeScreenContent> {
  final ApiService _apiService = ApiService();
  final Map<int, bool> _isStartingRide = {};

  final Map<String, bool> _expandedRideStates = {};

  final String _driverPhoneNumber = '01207169677';
  String? _selectedRescheduleTimeSlot;
  bool _showRescheduleSuccessMessage = false;

  @override
  void initState() {
    super.initState();
  }

  String _formatTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid Time';
    }
  }

  void _showRescheduleBottomSheet(BuildContext context, String rideId) {
    setState(() {
      _showRescheduleSuccessMessage = false;
      _selectedRescheduleTimeSlot = null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25.0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 16.0),
                                  Text(
                                    'Reschedule_Your_Upcoming_Ride'.tr(),
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Center(
                                // Your button code was commented out, leaving it as is.
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCancelRideBottomSheetConfirmation(
    BuildContext context, {
    required bool isSchoolBus,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 0.6,
              expand: false,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25.0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Container(
                          width: 60,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  const SizedBox(height: 35),
                                  Image.asset(
                                    'assets/images/png/cancel.png',
                                    width: 35,
                                    height: 24,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    isSchoolBus
                                        ? 'child Upcoming Pick-up is now \n Cancelled!'
                                        : 'Your Upcoming Ride is now \n Cancelled!',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 30),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Center(
                                        child: SizedBox(
                                          width: 132,
                                          height: 50,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              debugPrint(
                                                'User confirmed cancellation.',
                                              );
                                              if (isSchoolBus) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Ride cancellation confirmed.',
                                                    ),
                                                  ),
                                                );
                                              }
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.black87,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text(
                                              'Done',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCancelRideBottomSheet(
    BuildContext context, {
    bool isSchoolBus = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 0.6,
              expand: false,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25.0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Container(
                          width: 60,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  const SizedBox(height: 35),
                                  Image.asset(
                                    'assets/images/png/cancel.png',
                                    width: 35,
                                    height: 24,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Are you sure you wish to cancel your',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    isSchoolBus
                                        ? 'child Upcoming pick-up'
                                        : 'Upcoming Ride?',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 30),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          debugPrint(
                                            'User confirmed cancellation.',
                                          );
                                          _showCancelRideBottomSheetConfirmation(
                                            context,
                                            isSchoolBus: isSchoolBus,
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black87,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(100, 50),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Yes',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      OutlinedButton(
                                        onPressed: () {
                                          debugPrint(
                                            'User cancelled cancellation.',
                                          );
                                          Navigator.pop(context);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Colors.black,
                                          ),
                                          foregroundColor: Colors.black,
                                          minimumSize: const Size(100, 50),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'No',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showPickDropBottomSheet(BuildContext context) {
    PickDropOption? _selectedOption = PickDropOption.allNotAttending;
    bool _isSubmitted = false;
    const String _dummyChildId = 'child123';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  RadioListTile<PickDropOption>(
                    title: Text(
                      "Child not attending Today's Pick-Up",
                      style: TextStyle(
                        color:
                            _selectedOption == PickDropOption.pickUpNotAttending
                                ? Colors.blue
                                : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: PickDropOption.pickUpNotAttending,
                    groupValue: _selectedOption,
                    onChanged:
                        _isSubmitted
                            ? null
                            : (PickDropOption? value) {
                              setModalState(() {
                                _selectedOption = value;
                              });
                            },
                    activeColor: Colors.blue,
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                  RadioListTile<PickDropOption>(
                    title: Text(
                      "Child not attending Today's Drop-Off",
                      style: TextStyle(
                        color:
                            _selectedOption ==
                                    PickDropOption.dropOffNotAttending
                                ? Colors.blue
                                : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: PickDropOption.dropOffNotAttending,
                    groupValue: _selectedOption,
                    onChanged:
                        _isSubmitted
                            ? null
                            : (PickDropOption? value) {
                              setModalState(() {
                                _selectedOption = value;
                              });
                            },
                    activeColor: Colors.blue,
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: 157,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            _isSubmitted
                                ? null
                                : () async {
                                  setModalState(() {
                                    _isSubmitted = true;
                                  });
                                  print('Submitted option: $_selectedOption');

                                  String absenceType = '';
                                  switch (_selectedOption) {
                                    case PickDropOption.allNotAttending:
                                      absenceType = 'all';
                                      break;
                                    case PickDropOption.pickUpNotAttending:
                                      absenceType = 'pickup';
                                      break;
                                    case PickDropOption.dropOffNotAttending:
                                      absenceType = 'dropoff';
                                      break;
                                    default:
                                      break;
                                  }

                                  // if (absenceType.isNotEmpty) {
                                  //   try {
                                  //     final response =
                                  //     await _apiService.recordChildAbsence(
                                  //       absenceType,
                                  //       _dummyChildId,
                                  //     );
                                  //     if (!mounted) return;
                                  //     ScaffoldMessenger.of(context).showSnackBar(
                                  //       SnackBar(
                                  //         content: Text(response['message'] ??
                                  //             (response['status'] == true
                                  //                 ? 'Absence recorded successfully!'
                                  //                 : 'Failed to record absence.')),
                                  //       ),
                                  //     );
                                  //   } catch (e) {
                                  //     if (!mounted) return;
                                  //     ScaffoldMessenger.of(context).showSnackBar(
                                  //       SnackBar(
                                  //         content:
                                  //         Text('Error recording absence: $e'),
                                  //       ),
                                  //     );
                                  //   }
                                  // }

                                  await Future.delayed(
                                    const Duration(seconds: 2),
                                  );
                                  if (mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isSubmitted
                                  ? Colors.grey
                                  : ColorManager.darkGray,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Visibility(
                    visible: _isSubmitted,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Your child\'s attendance has been submitted.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: _isSubmitted ? 10 : 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final upcomingRidesAsync = ref.watch(upcomingRidesProvider);
    final userProfileAsyncValue = ref.watch(userProfileProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.02),
            _buildHeader(userProfileAsyncValue),
            SizedBox(height: screenHeight * 0.1),

            // FIXED: Use ListView.builder instead of List.generate to prevent memory issues
            upcomingRidesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (err, stack) =>
                      Center(child: Text('Failed to load rides: $err')),
              data: (rides) {
                if (rides.isEmpty) {
                  return Center(
                    child: Text(
                      'No_Upcoming_Rides'.tr(),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Use ListView.builder for efficient memory usage
                return SizedBox(
                  height: screenHeight * 0.5, // Set a fixed height
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rides.length,
                    itemBuilder: (context, index) {
                      final ride = rides[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.01),
                        child: _buildRideCard(ride),
                      );
                    },
                  ),
                );
              },
            ),

            SizedBox(height: screenHeight * 0.1),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    switch (ride.status) {
      case 'upcoming':
      case 'on_the_way':
      case 'pending':
      case 'pending_reschedule':
        return _buildUpcomingRideSectionNew(ride);
      case 'started':
        return _buildRideStartedSection(ride);
      default:
        return Card(
          child: ListTile(
            title: Text('Ride for ${ride.serviceType}'),
            subtitle: Text('Status: ${ride.status}'),
          ),
        );
    }
  }

  Widget _buildHeader(AsyncValue<user_model.User> userProfileAsyncValue) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Row(
            children: [
              userProfileAsyncValue.when(
                data:
                    (user) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2.0),
                      ),
                      child: CircleAvatar(
                        radius: screenWidth * 0.08,
                        backgroundImage:
                            user.profilePictureUrl != null &&
                                    user.profilePictureUrl!.isNotEmpty
                                ? NetworkImage(user.profilePictureUrl!)
                                : const AssetImage(
                                      'assets/images/png/profile_pic.png',
                                    )
                                    as ImageProvider,
                      ),
                    ),
                loading:
                    () => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2.0),
                      ),
                      child: CircleAvatar(
                        radius: screenWidth * 0.08,
                        child: const CircularProgressIndicator(),
                      ),
                    ),
                error:
                    (err, stack) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2.0),
                      ),
                      child: CircleAvatar(
                        radius: screenWidth * 0.08,
                        backgroundImage: const AssetImage(
                          'assets/images/png/profile_pic.png',
                        ),
                      ),
                    ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello'.tr(),
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      color: Colors.black,
                    ),
                  ),
                  userProfileAsyncValue.when(
                    data:
                        (user) => Text(
                          user.name ?? 'User',
                          style: TextStyle(
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    loading:
                        () => Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    error:
                        (err, stack) => Text(
                          'User Name',
                          style: TextStyle(
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                  Text(
                    'online'.tr(),
                    style: const TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideStartedSection(Ride ride) {
    bool isPrivRideStartedExpanded =
        _expandedRideStates[ride.id.toString()] ?? false;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedRideStates[ride.id.toString()] = !isPrivRideStartedExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your_Ride_has_started'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estimated_distance_till_drop_off'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorManager.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '25_KM'.tr(),
                  // This might need a value from the API if available
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.blue,
                  ),
                ),
                Icon(
                  isPrivRideStartedExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.black,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Timeline progress bar (simplified)
            Row(
              children: [
                Icon(Icons.check_circle, color: ColorManager.blue, size: 20),
                Expanded(
                  child: DottedLine(
                    dashColor: ColorManager.blue,
                    lineThickness: 2.0,
                    direction: Axis.vertical,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ColorManager.blue, width: 2),
                  ),
                  child: Image.asset(
                    ride.serviceType == 'car'
                        ? 'assets/images/png/car.png'
                        : 'assets/images/png/smallBus.png',
                    width: 30,
                    height: 30,
                  ),
                ),
                Expanded(
                  child: DottedLine(
                    dashColor: Colors.grey.shade400,
                    lineThickness: 2.0,
                    direction: Axis.vertical,
                  ),
                ),
                const Icon(Icons.circle_outlined, color: Colors.grey, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Started'.tr(),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    'Drop_Off'.tr(),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.client?.name ?? 'Driver Name'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ride.car?.fullName ?? 'Car Details'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: ColorManager.darkGray,
                      ),
                    ),
                  ],
                ),
                Text(
                  ride.car?.plate ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    debugPrint('Track Vehicle tapped');
                    Navigator.pushNamed(context, Routes.TrackRoute);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: ColorManager.blue,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Track_Vehicle'.tr(),
                        style: TextStyle(
                          color: ColorManager.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: ColorManager.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Image.asset(
                        'assets/images/png/chat.png',
                        width: 42,
                        height: 42,
                        color: ColorManager.blue,
                      ),
                      onPressed: () {
                        debugPrint('Chat tapped');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatScreen(chatId: ''),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: Image.asset(
                        'assets/images/png/dial.png',
                        width: 42,
                        height: 42,
                      ),
                      onPressed: () async {
                        final Uri launchUri = Uri(
                          scheme: 'tel',
                          path: ride.client?.phoneNumber ?? _driverPhoneNumber,
                        );
                        if (await canLaunchUrl(launchUri)) {
                          await launchUrl(launchUri);
                        } else {
                          debugPrint('Could not launch phone dialer.');
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            if (isPrivRideStartedExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Column(
                  children: [
                    const Divider(
                      height: 20,
                      thickness: 1,
                      indent: 20,
                      endIndent: 20,
                      color: ColorManager.divider,
                    ),
                    Text(
                      'Wish_to_reschedule_or_Cancel_this_upcoming_ride'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _showRescheduleBottomSheet(
                              context,
                              ride.id.toString(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(126, 45),
                            backgroundColor: ColorManager.darkGray,
                            foregroundColor: ColorManager.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            'Reschedule'.tr(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            _showCancelRideBottomSheet(context);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(126, 45),
                            side: const BorderSide(color: Color(0xFF9E9E9E)),
                            foregroundColor: const Color(0xFF2C3E50),
                            backgroundColor: ColorManager.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            'Cancel'.tr(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData iconData,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: ColorManager.blue,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(iconData, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildUpcomingRideSectionNew(Ride ride) {
    final isExpanded = _expandedRideStates[ride.id.toString()] ?? false;
    final isCar = ride.serviceType == 'car';
    final isSchoolBus = ride.serviceType == 'school_bus';
    final ui.TextDirection currentDirection = Directionality.of(context);

    List<Widget> rtlFriendlyRow(List<Widget> children) {
      return currentDirection == ui.TextDirection.rtl
          ? children.reversed.toList()
          : children;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedRideStates[ride.id.toString()] = !isExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: rtlFriendlyRow([
                      Image.asset(
                        'assets/images/png/Requests.png',

                        color: Colors.black87,
                        width: 30,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your_Upcoming_Ride'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (ride.client?.name != null)
                              Text(
                                "Driver: ${ride.client!.name}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
                Row(
                  children: rtlFriendlyRow([
                    Text(
                      _formatTime(ride.pickUpTime),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.black,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.black,
                    ),
                  ]),
                ),
              ],
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check,
                                  color: ColorManager.blue,
                                  size: 20,
                                ),
                                Expanded(
                                  child: DottedLine(
                                    dashColor: ColorManager.blue,
                                    lineThickness: 2.0,
                                    direction: Axis.horizontal,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: ColorManager.blue,
                                      width: 2,
                                    ),
                                  ),
                                  child: Image.asset(
                                    ride.serviceType == 'car'
                                        ? 'assets/images/png/car.png'
                                        : 'assets/images/png/smallBus.png',
                                    width: 30,
                                    height: 30,
                                  ),
                                ),
                                Expanded(
                                  child: DottedLine(
                                    dashColor: Colors.grey.shade400,
                                    lineThickness: 2.0,
                                    direction: Axis.horizontal,
                                  ),
                                ),
                                Icon(
                                  Icons.circle,
                                  color: ColorManager.blue,
                                  size: 12,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Started'.tr(),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Drop_Off'.tr(),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '58 KM | 1 hour'.tr(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                'Obour Buildings, Salah Salem St.'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 25),
                              Text(
                                'American University in Cairo'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, Routes.TrackRoute);
                          },
                          icon: Icon(
                            Icons.location_on_outlined,
                            color: ColorManager.blue,
                          ),
                          label: Text(
                            'Track_Vehicle'.tr(),
                            style: TextStyle(
                              color: ColorManager.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: ColorManager.blue,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            IconButton(
                              icon: Image.asset(
                                'assets/images/png/chat.png',
                                width: 42,
                                height: 42,
                                color: ColorManager.blue,
                              ),
                              onPressed: () {
                                debugPrint('Chat tapped');
                              },
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: Image.asset(
                                'assets/images/png/dial.png',
                                width: 42,
                                height: 42,
                              ),
                              onPressed: () async {
                                final Uri launchUri = Uri(
                                  scheme: 'tel',
                                  path:
                                      _driverPhoneNumber, // This should come from API if available
                                );
                                if (await canLaunchUrl(launchUri)) {
                                  await launchUrl(launchUri);
                                } else {
                                  debugPrint('Could not launch phone dialer.');
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(
                      height: 20,
                      thickness: 1,
                      indent: 20,
                      endIndent: 20,
                      color: ColorManager.divider,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: SizedBox(
                              height: 45,
                              width: 126,

                              child: ElevatedButton(

                                onPressed: _isStartingRide[ride.id] == true
                                    ? null
                                    : () async {
                                  setState(() {
                                    _isStartingRide[ride.id] = true;
                                  });
                                  try {
                                    await _apiService.startRide(ride.id);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Ride started successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    // Refresh the rides list to reflect the change
                                    ref.invalidate(
                                        upcomingRidesProvider);
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to start ride: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _isStartingRide[ride.id] = false;
                                      });
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorManager.buttonDark,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),

                                child: _isStartingRide[ride.id] == true
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                                    : Text('Start_Ride'.tr()),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
