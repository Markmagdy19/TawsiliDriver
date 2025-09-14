import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../data/models/sliderViewObject/SliderViewObject.dart';
import '../../../data/models/slider_objects/Slider_objects.dart';
import 'onBoarding_API_service.dart';


final onBoardingApiServiceProvider = Provider<OnBoardingApiService>((ref) {
  return OnBoardingApiServiceImpl();
});



class OnBoardingViewModel extends StateNotifier<SliderViewObject> {
  final OnBoardingApiService _apiService;

  List<SliderObject> _list = [];
  int _currentIndex = 0;
  String? _statusMessage;

  OnBoardingViewModel(this._apiService) : super(SliderViewObject.loading()) {
    _initialize(); // Load data on creation
  }

  // Initial fetch from API
  Future<void> _initialize() async {
    try {
      debugPrint('Fetching onboarding data...');
      final response = await _apiService.fetchOnBoardingData();

      _list = response.data;
      _statusMessage = response.message;

      if (_list.isEmpty) {
        state = SliderViewObject.error("No onboarding data available");
        return;
      }

      // Set initial valid state
      state = SliderViewObject(
        sliderObjects: _list,
        numOfSlides: _list.length,
        currentIndex: _currentIndex,
        statusMessage: _statusMessage,
      );
    } catch (e) {
      debugPrint('Error fetching onboarding data: $e');
      state = SliderViewObject.error("Failed to load data: ${e.toString()}");
    }
  }

  // Move to next slide
  int goNext() {
    if (_list.isEmpty) return _currentIndex;
    _currentIndex = (_currentIndex + 1) % _list.length;
    _updateState();
    return _currentIndex;
  }


  int goPrevious() {
    if (_list.isEmpty) return _currentIndex;
    _currentIndex = (_currentIndex - 1 + _list.length) % _list.length;
    _updateState();
    return _currentIndex;
  }


  void onPageChanged(int index) {
    if (_list.isEmpty) return;
    _currentIndex = index;
    _updateState();
  }


  void _updateState() {
    state = SliderViewObject(
      sliderObjects: _list,
      numOfSlides: _list.length,
      currentIndex: _currentIndex,
      statusMessage: _statusMessage,
    );
  }
}

// ViewModel provider for use in the UI
final onBoardingViewModelProvider =
StateNotifierProvider<OnBoardingViewModel, SliderViewObject>((ref) {
  final apiService = ref.read(onBoardingApiServiceProvider);
  return OnBoardingViewModel(apiService);
});
