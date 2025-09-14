import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/app/constants.dart';
import '../../../data/models/slider_objects/Slider_objects.dart';


class OnBoardingApiResponse {
  final List<SliderObject> data;
  final String? message;

  OnBoardingApiResponse({required this.data, this.message});
}

abstract class OnBoardingApiService {
  Future<OnBoardingApiResponse> fetchOnBoardingData();
}

class OnBoardingApiServiceImpl implements OnBoardingApiService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  @override
  Future<OnBoardingApiResponse> fetchOnBoardingData() async {
    try {
      final response = await _dio.get(
        '${Constants.baseUrl1}/driver/onboarding',
        options: Options(
          headers: {
            'Accept-Language': 'en',
          },
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data as Map<String, dynamic>;

        // Logging structure for debug
        print('Raw onboarding response (from service): $responseBody');

        // The actual list of slider objects is nested under 'data' -> 'onboarding'
        final dynamic rawDataField = responseBody['data'];
        List<SliderObject> sliders = [];

        if (rawDataField is Map<String, dynamic> && rawDataField.containsKey('onboarding')) {
          final dynamic rawOnboardingList = rawDataField['onboarding'];

          if (rawOnboardingList is List) {
            // Correctly map the list of items
            sliders = rawOnboardingList
                .map((item) => SliderObject.fromJson(item as Map<String, dynamic>))
                .toList();
          } else {
            throw Exception("Unexpected 'onboarding' type: ${rawOnboardingList.runtimeType}. Expected a List.");
          }
        } else {
          throw Exception("Unexpected 'data' structure in API response. Expected a Map with 'onboarding' key. Received: ${rawDataField.runtimeType}");
        }

        return OnBoardingApiResponse(
          data: sliders,
          message: responseBody['message'] as String?,
        );
      } else {
        throw Exception('Failed to load onboarding data: ${response.statusCode}');
      }
    } on DioException catch (e, st) {
      print(st.toString());
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}

final onBoardingApiServiceProvider = Provider<OnBoardingApiService>((ref) {
  return OnBoardingApiServiceImpl();
});