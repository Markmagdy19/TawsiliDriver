import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/resources/color_manager.dart';
import '../../data/repositories/Ride_History_repo.dart';
import '../utils/routes_manager.dart';
import 'dart:developer' as developer;

import 'ride_details.dart';

class RideLogsHistoryScreen extends ConsumerStatefulWidget {
  const RideLogsHistoryScreen({super.key});

  @override
  ConsumerState<RideLogsHistoryScreen> createState() => _RideLogsHistoryScreenState();
}

class _RideLogsHistoryScreenState extends ConsumerState<RideLogsHistoryScreen> {
  late Future<List<RideLog>> _rideLogsFuture;

  DateTime? _filterFromDate;
  DateTime? _filterToDate;
  String? _filterPeriod;
  String? _filterServiceType;

  @override
  void initState() {
    super.initState();

    _fetchRideLogs();
  }

  void _fetchRideLogs() {
    final rideLogsApi = ref.read(rideLogsApiProvider);
    setState(() {
      _rideLogsFuture = rideLogsApi.getRideLogs(
        dateFrom: _filterFromDate,
        dateTo: _filterToDate,
        period: _filterPeriod,
        serviceType: _filterServiceType,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Ride_Logs_History'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/images/png/Filter_big.png',
              width: 24,
              height: 24,
            ),
            onPressed: () async {
              final Map<String, dynamic>? filterResult =
              await Navigator.pushNamed(context, Routes.filterRoute) as Map<String, dynamic>?;

              if (filterResult != null) {
                developer.log('Filter Result: $filterResult', name: 'RideLogsHistoryScreen');

                setState(() {
                  _filterFromDate = filterResult['fromDate'] != null
                      ? DateTime.parse(filterResult['fromDate'])
                      : null;
                  _filterToDate = filterResult['toDate'] != null
                      ? DateTime.parse(filterResult['toDate'])
                      : null;
                  _filterPeriod = filterResult['period'];
                  _filterServiceType = filterResult['serviceType'];
                });
                _fetchRideLogs();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<RideLog>>(
        future: _rideLogsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            developer.log('Error fetching ride logs: ${snapshot.error}', error: snapshot.error, name: 'RideLogsHistoryScreen');
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return  Center(child: Text('No_ride_logs_found_with_current_filters'.tr()));
          } else {
            final List<RideLog> rideLogs = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 30.0, bottom: 24.0),
                  ),
                  const SizedBox(height: 24.0, width: 30),
                  Padding(
                    padding: const EdgeInsets.only(left: 15.0),
                    child: Text(
                      'All_Ride_Logs_History'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ...rideLogs.map((log) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      children: [
                        _buildRideLogItem(
                          context,
                          log: log,
                        ),
                        const SizedBox(height: 8.0),
                      ],
                    ),
                  )),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildRideLogItem(
      BuildContext context, {
        required RideLog log,
      }) {
    Color statusColor = log.isCompleted ? ColorManager.blue : ColorManager.red;
    IconData statusIcon = log.isCompleted ? Icons.check_circle : Icons.cancel;
    Color containerColor = log.isCompleted
        ? ColorManager.BlueNotification
        : ColorManager.redNotification;

    String formattedDateTime = _getFormattedDateTime(log.rawDate);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RideDetailsScreen(rideLog: log),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        height: 153,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  log.planId,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 18),
                    const SizedBox(width: 4.0),
                    Text(
                      log.status,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    const Icon(Icons.arrow_forward_ios, size: 16.0,
                        color: Colors.black),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Date_Time'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formattedDateTime,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Poppins',
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pick_Up_Location'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        log.pickupLocation,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Poppins',
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getFormattedDateTime(String dateTimeString) {
    if (dateTimeString.isEmpty) {
      return 'N/A';
    }
    try {
      DateFormat inputFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      DateTime dateTime = inputFormat.parse(dateTimeString);
      DateFormat outputFormat = DateFormat('dd/MM/yyyy hh:mm a');
      return outputFormat.format(dateTime);
    } catch (e) {
      developer.log('Error parsing date string: $dateTimeString, Error: $e',
          name: 'RideLogsHistoryScreen');
      return 'Invalid Date';
    }
  }
}