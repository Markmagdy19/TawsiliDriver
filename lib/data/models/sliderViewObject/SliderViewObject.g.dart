// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SliderViewObject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SliderViewObject _$SliderViewObjectFromJson(Map<String, dynamic> json) =>
    SliderViewObject(
      sliderObjects:
          (json['sliderObjects'] as List<dynamic>?)
              ?.map((e) => SliderObject.fromJson(e as Map<String, dynamic>))
              .toList(),
      numOfSlides: (json['numOfSlides'] as num?)?.toInt(),
      currentIndex: (json['currentIndex'] as num?)?.toInt(),
      statusMessage: json['statusMessage'] as String?,
    );

Map<String, dynamic> _$SliderViewObjectToJson(SliderViewObject instance) =>
    <String, dynamic>{
      'sliderObjects': instance.sliderObjects,
      'numOfSlides': instance.numOfSlides,
      'currentIndex': instance.currentIndex,
      'statusMessage': instance.statusMessage,
    };
