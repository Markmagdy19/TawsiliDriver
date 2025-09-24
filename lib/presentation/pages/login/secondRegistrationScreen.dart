import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../data/datasources/resources/color_manager.dart';
import '../../../data/repositories/car_repository.dart';
import '../Documents/UploadDocumentsScreen.dart';

class VehicleInfoScreen extends ConsumerStatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  ConsumerState<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends ConsumerState<VehicleInfoScreen> {
  final _plateNumberController = TextEditingController();
  final _licensePlateLetterController = TextEditingController();
  // final _vehicleNumberController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _carColorController = TextEditingController();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();

  String? _selectedBrandName;
  String? _selectedModelName;

  bool _isButtonActive = false;
  String _dateErrorText = '';

  @override
  void initState() {
    super.initState();
    _plateNumberController.addListener(_updateButtonState);
    _licensePlateLetterController.addListener(_updateButtonState);
    // _vehicleNumberController.addListener(_updateButtonState);
    _ownerNameController.addListener(_updateButtonState);
    _carColorController.addListener(_updateButtonState);
    _dayController.addListener(_updateButtonState);
    _monthController.addListener(_updateButtonState);
    _yearController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _plateNumberController.dispose();
    _licensePlateLetterController.dispose();
    // _vehicleNumberController.dispose();
    _ownerNameController.dispose();
    _carColorController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    final plateNumber = _plateNumberController.text;
    final licensePlateLetter = _licensePlateLetterController.text;
    // final vehicleNumber = _vehicleNumberController.text;
    final ownerName = _ownerNameController.text;
    final carColor = _carColorController.text;
    final day = _dayController.text;
    final month = _monthController.text;
    final year = _yearController.text;

    final allFieldsFilled = plateNumber.isNotEmpty &&
        licensePlateLetter.isNotEmpty &&
        // vehicleNumber.isNotEmpty &&
        ownerName.isNotEmpty &&
        carColor.isNotEmpty &&
        day.isNotEmpty &&
        month.isNotEmpty &&
        year.isNotEmpty &&
        _selectedBrandName != null &&
        _selectedModelName != null;

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
    } else {
      setState(() {
        _isButtonActive = false;
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

  Future<void> _submitVehicleInfo() async {
    final carBrandsAsync = ref.read(carBrandsProvider);
    final carModelsAsync = ref.read(carModelsProvider(
      carBrandsAsync.when(
        data: (brands) =>
        brands.firstWhere((b) => b.name == _selectedBrandName).id,
        loading: () => 0,
        error: (err, stack) => 0,
      ),
    ));

    int? carMakeId;
    carBrandsAsync.whenData((brands) {
      carMakeId = brands.firstWhere((b) => b.name == _selectedBrandName).id;
    });

    int? carModelId;
    await carModelsAsync.whenData((models) {
      carModelId = models.firstWhere((m) => m.name == _selectedModelName).id;
    });

    if (carMakeId == null || carModelId == null) {
      // Handle the case where IDs are not found
      print('Error: Could not retrieve car make or model IDs.');
      return;
    }

    final carRepository = ref.read(carRepositoryProvider);
    final licenseExpiryDate =
        '${_yearController.text}-${_monthController.text.padLeft(2, '0')}-${_dayController.text.padLeft(2, '0')}';

    try {
      await carRepository.postVehicleInfo(
        carMakeId: carMakeId!,
        carModelId: carModelId!,
        carColor: _carColorController.text,
        licensePlateNumber: _plateNumberController.text,
        licensePlateLetter: _licensePlateLetterController.text,
        carOwnerName: _ownerNameController.text,
        licenseExpiryDate: licenseExpiryDate,
      );
      // Navigate to the next screen on success
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const UploadDocumentsScreen()),
        );
      }
    } catch (e) {
      // Handle API submission errors
      print('Failed to submit vehicle info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save vehicle info. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final carBrandsAsync = ref.watch(carBrandsProvider);

    int? selectedBrandId;
    if (_selectedBrandName != null) {
      carBrandsAsync.whenData((brands) {
        final brand = brands.firstWhere((b) => b.name == _selectedBrandName);
        selectedBrandId = brand.id;
      });
    }

    final carModelsAsync = selectedBrandId != null
        ? ref.watch(carModelsProvider(selectedBrandId!))
        : null;

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
                  fontFamily: 'Poppins',
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
              Row(
                children: [
                  Expanded(
                    child: carBrandsAsync.when(
                      data: (brands) => _buildDropdownMenu(
                        value: _selectedBrandName,
                        hint: 'Car Brand',
                        items: brands.map((b) => b.name).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedBrandName = newValue;
                            _selectedModelName = null;
                          });
                          _updateButtonState();
                        },
                      ),
                      loading: () => _buildDropdownMenu(
                        value: null,
                        hint: 'Loading Brands...',
                        items: [],
                        onChanged: null,
                      ),
                      error: (err, stack) => _buildDropdownMenu(
                        value: null,
                        hint: 'Error fetching brands',
                        items: [],
                        onChanged: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: carModelsAsync == null
                        ? _buildDropdownMenu(
                      value: null,
                      hint: 'Select a brand first',
                      items: [],
                      onChanged: null,
                      isEnabled: false,
                    )
                        : carModelsAsync.when(
                      data: (models) => _buildDropdownMenu(
                        value: _selectedModelName,
                        hint: 'Car Model',
                        items: models.map((m) => m.name).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedModelName = newValue;
                          });
                          _updateButtonState();
                        },
                        isEnabled: true,
                      ),
                      loading: () => _buildDropdownMenu(
                        value: null,
                        hint: 'Loading Models...',
                        items: [],
                        onChanged: null,
                      ),
                      error: (err, stack) => _buildDropdownMenu(
                        value: null,
                        hint: 'Error fetching models',
                        items: [],
                        onChanged: null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Updated to include License Plate Number and Letter
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _plateNumberController,
                      hintText: 'License plate number',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: _buildTextField(
                      controller: _licensePlateLetterController,
                      hintText: 'Letter',
                    ),
                  ),

                ],
              ),
              const SizedBox(height: 16),
              // _buildTextField(
              //   controller: _vehicleNumberController,
              //   hintText: 'Vehicle no.',
              //   keyboardType: TextInputType.number,
              // ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _ownerNameController,
                      hintText: 'Vehicle owner name',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: _buildTextField(
                    controller: _carColorController,
                    hintText: 'Car color',
                  ),
                ),],),
              SizedBox(height: 20,),
              _buildExpiryDateSection(),
              if (_dateErrorText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _dateErrorText,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 100),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isButtonActive ? _submitVehicleInfo : null,
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
              _buildPageIndicator(currentPage: 3, pageCount: 5),
            ],
          ),
        ),
      ),
    );
  }

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
        hintStyle:
        TextStyle(color: Colors.grey.shade600, fontFamily: 'Poppins'),
        filled: true,
        fillColor: ColorManager.lightBlueBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      ),
    );
  }

  Widget _buildDropdownMenu({
    String? value,
    required String hint,
    required List<String> items,
    required void Function(String?)? onChanged,
    bool isEnabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isEnabled
            ? ColorManager.lightBlueBackground
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint,
              style: TextStyle(
                  color: Colors.grey.shade600, fontFamily: 'Poppins')),
          icon: Icon(Icons.keyboard_arrow_down, color: ColorManager.blue),
          onChanged: isEnabled ? onChanged : null,
          style: TextStyle(
              color: ColorManager.darkGreyBlue, fontFamily: 'Poppins'),
          dropdownColor: Colors.white,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
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
              const SizedBox(width: 8),
              _buildDateInputBox(
                  controller: _monthController, hint: 'Month', maxLength: 2),
              const SizedBox(width: 8),
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
          hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontFamily: 'Poppins'),
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
        bool isActive = index <= currentPage;
        bool isCurrent = index == currentPage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: isCurrent ? 24.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: isActive
                ? ColorManager.blue
                : ColorManager.lightBlueBackground,
            borderRadius: BorderRadius.circular(4.0),
          ),
        );
      }),
    );
  }
}