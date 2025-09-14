import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/datasources/resources/color_manager.dart';
import '../../../data/datasources/resources/values_manager.dart';

class ReviewDocumentScreen extends StatefulWidget {
  final File documentImage;

  const ReviewDocumentScreen({super.key, required this.documentImage});

  @override
  State<ReviewDocumentScreen> createState() => _ReviewDocumentScreenState();
}

class _ReviewDocumentScreenState extends State<ReviewDocumentScreen> {
  late File _currentImage;
  bool _isImageClear = false; // This will be determined by your processing logic
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _currentImage = widget.documentImage;
    // In a real app, you would process the image here and set _isImageClear
    // For demonstration, we'll use a switch to toggle the state.
  }

  // --- Image Picking Logic ---
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _currentImage = File(pickedFile.path);
          _isImageClear = false; // Reset clarity check for the new image
        });
        // TODO: Re-run your image processing logic on the new _currentImage
      }
    } catch (e) {
      // Handle any errors, e.g., permissions denied
      print("Failed to pick image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

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
    // const SizedBox(height: AppSize.s20),
    Text(
    "Document Processing",
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
                "1. Front of License",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.blue // Dark Blue
                ),
              ),




              const SizedBox(height: 24),

              // --- Checklist ---
              _buildChecklistItem(
                  "All four corners of the document are visible."),
              _buildChecklistItem("The image is clear and not blurry."),
              _buildChecklistItem("Text is sharp, readable, with no glare."),
      const SizedBox(height: 24),

      Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _currentImage,
            fit: BoxFit.cover,
          ),
        ),
      ),

              const SizedBox(height: 40),

              // --- Conditional Action Buttons ---
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    )) );
  }

  /// Builds the action buttons based on whether the image is clear or not.
  Widget _buildActionButtons() {
    if (_isImageClear) {
      // --- STATE 1: Image is clear, show NEXT button ---
      return SizedBox(
        height: 55,
        child: ElevatedButton(
          onPressed: () {
            // Navigate to the next screen (e.g., back of license)
            print("Navigating to the next step...");
            // Navigator.of(context).push(...);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007BFF), // Bright Blue
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Next",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF), // Bright Blue
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Take a new photo",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF343A40), // Dark Grey
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Choose from gallery",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Colors.black, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }


}