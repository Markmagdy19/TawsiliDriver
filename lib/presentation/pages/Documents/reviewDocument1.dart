// lib/presentation/pages/Documents/reviewDocument1.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/datasources/resources/color_manager.dart';
import '../../../data/datasources/resources/values_manager.dart';
import '../../../data/models/document/document_model.dart';

class ReviewDocumentScreen extends StatefulWidget {
  // The list of all fields to be processed in sequence.
  final List<RequiredField> allRequiredFields;
  // The index of the current field in the list.
  final int currentIndex;
  // A map to store the images uploaded in the flow.
  final Map<String, File> uploadedImages;

  const ReviewDocumentScreen({
    super.key,
    required this.allRequiredFields,
    required this.currentIndex,
    required this.uploadedImages,
  });

  @override
  State<ReviewDocumentScreen> createState() => _ReviewDocumentScreenState();
}

class _ReviewDocumentScreenState extends State<ReviewDocumentScreen> {
  File? _userPickedImage;
  final _formKey = GlobalKey<FormState>();

  // Helper to get the current required field.
  RequiredField get currentField => widget.allRequiredFields[widget.currentIndex];

  @override
  void initState() {
    super.initState();
    // Initialize with an existing image if it was already picked in this session.
    _userPickedImage = widget.uploadedImages[currentField.key];
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        setState(() {
          _userPickedImage = imageFile;
        });
      }
    } catch (e) {
      debugPrint("Failed to pick image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title:  Padding(
          padding: EdgeInsets.only(top: 20.0),
          child: Text(
            "Document Processing",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: ColorManager.blue,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Return the map of images collected so far when popping.
            Navigator.of(context).pop(widget.uploadedImages);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSize.s40),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: ColorManager.blue,
                      child: Text(
                        // Display the current step number dynamically.
                        "${widget.currentIndex + 1}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      // Use the current field's name.
                      currentField.name,
                      style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 24.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        // Use the current field's description.
                        currentField.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _userPickedImage != null
                        ? Image.file(
                      _userPickedImage!,
                      fit: BoxFit.cover,
                    )
                        : (currentField.exampleImageUrl != null &&
                        currentField.exampleImageUrl!.isNotEmpty)
                        ? Image.network(
                      currentField.exampleImageUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder:
                          (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                            child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.error)),
                    )
                        : const Center(
                        child: Text("No example available")),
                  ),
                ),
                if (_userPickedImage != null) ...[
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 24.0,
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        "The image has been uploaded successfully",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 220),
                _buildActionSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionSection() {
    // Check if the current screen is for the last required field.
    final bool isLastField = widget.currentIndex == widget.allRequiredFields.length - 1;

    if (_userPickedImage != null) {
      // If an image is picked, show the button to proceed.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: () async {
                // Add the picked image to our map.
                widget.uploadedImages[currentField.key] = _userPickedImage!;

                if (isLastField) {
                  // If this is the last field, pop and return the final map.
                  Navigator.of(context).pop(widget.uploadedImages);
                } else {
                  // If not the last field, navigate to the next screen and wait for its result.
                  final nextIndex = widget.currentIndex + 1;
                  final Map<String, File>? nextScreenResult = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewDocumentScreen(
                        allRequiredFields: widget.allRequiredFields,
                        currentIndex: nextIndex,
                        uploadedImages: widget.uploadedImages,
                      ),
                    ),
                  );
                  // When the next screen is popped, add its results to the current map and pop this screen.
                  if (nextScreenResult != null) {
                    widget.uploadedImages.addAll(nextScreenResult);
                  }
                  // Pop this screen and pass the combined results back to the screen that opened it.
                  if (mounted) {
                    Navigator.of(context).pop(widget.uploadedImages);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                // Change button text dynamically.
                isLastField ? "Finish" : "Upload the Next image",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // If no image is picked, show the options to select one.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
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
                backgroundColor: const Color(0xFF343A40),
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
}