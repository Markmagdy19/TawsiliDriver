import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/datasources/resources/color_manager.dart';
import '../Documents/UploadDocumentsScreen.dart';

class VehicleInfoScreen extends StatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  // Controllers to manage the text in the input fields
  final _plateNumberController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();

  bool _isButtonActive = false;
  String _dateErrorText = '';

  @override
  void initState() {
    super.initState();
    _plateNumberController.addListener(_updateButtonState);
    _vehicleNumberController.addListener(_updateButtonState);
    _ownerNameController.addListener(_updateButtonState);
    _dayController.addListener(_updateButtonState);
    _monthController.addListener(_updateButtonState);
    _yearController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _plateNumberController.dispose();
    _vehicleNumberController.dispose();
    _ownerNameController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    final plateNumber = _plateNumberController.text;
    final vehicleNumber = _vehicleNumberController.text;
    final ownerName = _ownerNameController.text;
    final day = _dayController.text;
    final month = _monthController.text;
    final year = _yearController.text;

    final allFieldsFilled = plateNumber.isNotEmpty &&
        vehicleNumber.isNotEmpty &&
        ownerName.isNotEmpty &&
        day.isNotEmpty &&
        month.isNotEmpty &&
        year.isNotEmpty;

    bool isDateValid = false;
    if (allFieldsFilled) {
      isDateValid = _validateDate();
    } else {
      setState(() {
        _dateErrorText = '';
        _isButtonActive = false;
      });
    }

    if (allFieldsFilled && isDateValid) {
      setState(() {
        _isButtonActive = true;
      });
    }
  }

  bool _validateDate() {
    try {
      final day = int.parse(_dayController.text);
      final month = int.parse(_monthController.text);
      final year = int.parse(_yearController.text);

      final expiryDate = DateTime(year, month, day);
      final currentDate = DateTime.now();

      if (expiryDate.isAfter(currentDate)) {
        setState(() {
          _dateErrorText = '';
        });
        return true;
      } else {
        setState(() {
          _dateErrorText = 'Date cannot be in the past';
        });
        return false;
      }
    } catch (e) {
      setState(() {
        _dateErrorText = 'Invalid date';
      });
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
                "Create Account",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.blue,
                  fontFamily: 'Poppins', // Example custom font
                ),
              ),
              const SizedBox(height: 40),

              Text(
                "Vehicle Info",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.darkGreyBlue,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),

              // ## Plate & Vehicle Number Row ##
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _plateNumberController,
                      hintText: 'Vehicle plate no .',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _vehicleNumberController,
                      hintText: 'vehicle no.',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ## Owner Name Field ##
              _buildTextField(
                controller: _ownerNameController,
                hintText: 'Vehicle owner name',
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
              const SizedBox(height: 250),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isButtonActive
                      ? () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const UploadDocumentsScreen()),
                    );                  }
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
                  child: const Text(
                    "Next Step",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
        hintStyle: TextStyle(color: Colors.grey.shade600, fontFamily: 'Poppins'),
        filled: true,
        fillColor: ColorManager.lightBlueBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      ),
    );
  }

  // Helper method to build the license expiry date section
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
              _buildDateInputBox(controller: _dayController, hint: 'Day', maxLength: 2),
              const SizedBox(width: 8),
              _buildDateInputBox(controller: _monthController, hint: 'Month', maxLength: 2),
              const SizedBox(width: 8),
              _buildDateInputBox(controller: _yearController, hint: 'Year', maxLength: 4),
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
    return SizedBox(
      width: 70,
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
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontFamily: 'Poppins'),
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

  Widget _buildPageIndicator({required int currentPage, required int pageCount}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        bool isActive = index <= currentPage;
        bool isCurrent = index == currentPage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: isCurrent ? 24.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: isActive ? ColorManager.blue : ColorManager.lightBlueBackground,
            borderRadius: BorderRadius.circular(4.0),
          ),
        );
      }),
    );
  }
}