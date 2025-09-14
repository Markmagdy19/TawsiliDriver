import 'package:json_annotation/json_annotation.dart';

import '../slider_objects/Slider_objects.dart';

part 'SliderViewObject.g.dart';
@JsonSerializable()
class SliderViewObject {
 final List<SliderObject>? sliderObjects;
 final int? numOfSlides;
 final int? currentIndex;
 final String? error;
 final bool isLoading;
 final String? statusMessage;

 SliderViewObject({
  required this.sliderObjects,
  required this.numOfSlides,
  required this.currentIndex,
  this.statusMessage,
 })  : error = null,
      isLoading = false;

 SliderViewObject.loading()
     : sliderObjects = null,
      numOfSlides = null,
      currentIndex = null,
      error = null,
      statusMessage = null,
      isLoading = true;

 SliderViewObject.error(this.error)
     : sliderObjects = null,
      numOfSlides = null,
      currentIndex = null,
      statusMessage = null,
      isLoading = false;

 bool get hasError => error != null;

 factory SliderViewObject.fromJson(Map<String, dynamic> json) =>
     _$SliderViewObjectFromJson(json);

 Map<String, dynamic> toJson() => _$SliderViewObjectToJson(this);
}