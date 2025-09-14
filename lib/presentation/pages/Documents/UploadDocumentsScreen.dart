import 'dart:io'; // Needed to work with File objects

import 'package:driverr/presentation/pages/Documents/reviewDocument1.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // Import the package

import '../../../data/datasources/resources/color_manager.dart';

class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  // Controllers to manage the text in the input fields
  final _licenseNumberController = TextEditingController();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();

  bool _isButtonActive = false;
  String _dateErrorText = '';

  // ## NEW: State management for uploaded files ##
  final ImagePicker _picker = ImagePicker();
  File? _frontLicenseImage;
  File? _backLicenseImage;
  File? _selfieImage;

  @override
  void initState() {
    super.initState();
    _licenseNumberController.addListener(_updateButtonState);
    _dayController.addListener(_updateButtonState);
    _monthController.addListener(_updateButtonState);
    _yearController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _licenseNumberController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  // ## NEW: Getter to check if essential text fields are filled ##
  bool get _areTextFieldsFilled {
    return _licenseNumberController.text.isNotEmpty &&
        _dayController.text.isNotEmpty &&
        _monthController.text.isNotEmpty &&
        _yearController.text.isNotEmpty;
  }

  void _updateButtonState() {
    // Now, also check if all images have been uploaded.
    final allImagesUploaded = _frontLicenseImage != null &&
        _backLicenseImage != null &&
        _selfieImage != null;

    bool isDateValid = false;
    if (_areTextFieldsFilled) {
      isDateValid = _validateDate();
    } else {
      // Clear error if fields are not filled
      setState(() {
        _dateErrorText = '';
      });
    }

    // Set button state based on fields, date validity, AND image uploads
    setState(() {
      _isButtonActive =
          _areTextFieldsFilled && isDateValid && allImagesUploaded;
    });
  }


  // ## NEW: Function to handle picking an image ##
  Future<void> _pickImage(ImageSource source,
      Function(File) onImageSelected) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          onImageSelected(File(pickedFile.path));
        });
        _updateButtonState(); // Update button state after an image is selected
      }
    } catch (e) {
      // Handle any errors, e.g., permissions denied
      print("Failed to pick image: $e");
    }
  }

  // ## NEW: Function to show a dialog for choosing Camera or Gallery ##
  void _showImageSourceDialog(Function(File) onImageSelected) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text("Select Image Source"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text("Camera"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera, onImageSelected);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text("Gallery"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery, onImageSelected);
                  },
                ),
              ],
            ),
          ),
    );
  }

  // ## NEW: Function to handle the tap on an upload box ##
  void _handleUploadTap(Function(File) onImageSelected) {
    // Check the condition: text fields must be filled.
    if (_areTextFieldsFilled && _validateDate()) {
      _showImageSourceDialog(onImageSelected);
    } else {
      // Show a snackbar message if fields are not filled
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please fill in the license number and a valid expiry date first.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  bool _validateDate() {
    // This function remains largely the same, but we ensure setState is only
    // called when necessary to avoid unnecessary rebuilds.
    try {
      final day = int.parse(_dayController.text);
      final month = int.parse(_monthController.text);
      final year = int.parse(_yearController.text);
      String newError = '';

      if (month < 1 || month > 12 || day < 1 || day > 31) {
        newError = 'Invalid date';
      } else {
        final expiryDate = DateTime(year, month, day);
        final currentDate = DateTime.now();
        if (!expiryDate.isAfter(currentDate)) {
          newError = 'Date cannot be in the past';
        }
      }

      if (_dateErrorText != newError) {
        setState(() {
          _dateErrorText = newError;
        });
      }
      return newError.isEmpty;
    } catch (e) {
      if (_dateErrorText != 'Invalid date format') {
        setState(() {
          _dateErrorText = 'Invalid date format';
        });
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Upload Documents",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.blue,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 40),

              Text(
                "Valid Driving License",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ColorManager.darkGreyBlue,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),

              // ## Document Upload Section ##
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ## MODIFIED: Pass image file and onTap handler ##
                  _buildUploadBox(
                    label: 'Front of License',
                    imageFile: _frontLicenseImage,
                    onTap: () =>
                        _handleUploadTap((file) => _frontLicenseImage = file),
                  ),
                  _buildUploadBox(
                    label: 'Back of License',
                    imageFile: _backLicenseImage,
                    onTap: () =>
                        _handleUploadTap((file) => _backLicenseImage = file),
                  ),
                  _buildUploadBox(
                    label: 'Selfie with License',
                    imageFile: _selfieImage,
                    onTap: () =>
                        _handleUploadTap((file) => _selfieImage = file),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ## License Number Field ##
              _buildTextField(
                controller: _licenseNumberController,
                hintText: 'Driving license number',
                keyboardType: TextInputType.text, // License can have letters
              ),
              const SizedBox(height: 16),

              _buildExpiryDateSection(),
              if (_dateErrorText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _dateErrorText,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              // Spacer to push button to the bottom
              const SizedBox(height: 150),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isButtonActive
                      ? () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) =>
                      ReviewDocumentScreen(documentImage: _frontLicenseImage!)),


                    );
                    print("Next Step Clicked!");
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isButtonActive
                        ? ColorManager.blue
                        : ColorManager.lightBlueBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Next Step",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isButtonActive ? Colors.white : Colors.grey
                          .shade400,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ## Page Indicator ##
              _buildPageIndicator(currentPage: 3, pageCount: 5),
            ],
          ),
        ),
      ),
    );
  }

  // ## MODIFIED: Helper method to build an upload box ##
  Widget _buildUploadBox({
    required String label,
    required File? imageFile,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Column(
        children: [
          GestureDetector( // Wrap with GestureDetector to make it tappable
            onTap: onTap,
            child: Container(
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                color: ColorManager.lightBlueBackground,
                borderRadius: BorderRadius.circular(12.0),
              ),
              // ## MODIFIED: Show image if available, otherwise show icon ##
              child: imageFile != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.file(
                  imageFile,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
                  : Center(
                child: Icon(
                  Icons.add,
                  color: ColorManager.black,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: ColorManager.darkGreyBlue,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          )
        ],
      ),
    );
  }

  // Helper method to build a standard text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.left,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
            color: Colors.grey.shade600, fontFamily: 'Poppins'),
        filled: true,
        fillColor: ColorManager.lightBlueBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0, horizontal: 20.0),
      ),
    );
  }


  Widget _buildExpiryDateSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: ColorManager.lightBlueBackground,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'License expiration date',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColorManager.darkGreyBlue,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildDateInputBox(
                  controller: _dayController, hint: 'Day', maxLength: 2),
              const SizedBox(width: 12),
              _buildDateInputBox(
                  controller: _monthController, hint: 'Month', maxLength: 2),
              const SizedBox(width: 12),
              _buildDateInputBox(
                  controller: _yearController, hint: 'Year', maxLength: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateInputBox({
    required TextEditingController controller,
    required String hint,
    required int maxLength,
  }) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(maxLength),
        ],
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.grey.shade500, fontSize: 14, fontFamily: 'Poppins'),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(
      {required int currentPage, required int pageCount}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        bool isCurrent = index ==
            currentPage - 1; // Assuming currentPage is 1-based
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: isCurrent ? 24.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: isCurrent ? ColorManager.blue : ColorManager
                .lightBlueBackground,
            borderRadius: BorderRadius.circular(4.0),
          ),
        );
      }),
    );
  }
}
