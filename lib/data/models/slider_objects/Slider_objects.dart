import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class SliderObject {
  final String title;
  final String subTitle; // This property name is fine
  final String image;

  SliderObject({
    required this.title,
    required this.subTitle,
    required this.image,
  });

  factory SliderObject.fromJson(Map<String, dynamic> json) {
    print('SliderObject.fromJson: Raw JSON for slide: $json'); // Debug print
    final String title = json['title'] ?? '';
    final String subTitle = json['subtitle'] ?? ''; // Should be 'subtitle' (lowercase 's')
    final String image = json['image'] ?? '';

    print('SliderObject.fromJson: Parsed title: "$title", subtitle: "$subTitle", image: "$image"'); // Debug print

    return SliderObject(
      title: title,
      subTitle: subTitle,
      image: image,
    );
  }



}
