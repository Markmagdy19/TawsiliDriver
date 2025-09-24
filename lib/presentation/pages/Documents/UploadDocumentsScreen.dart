import 'dart:io';
import 'package:driverr/data/models/document/document_model.dart';
import 'package:driverr/presentation/pages/Documents/reviewDocument1.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/datasources/resources/color_manager.dart';
import '../../../data/repositories/document_repo.dart';
import '../terms&Condition/terms&Conditions.dart';



class UploadDocumentsScreen extends ConsumerStatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  ConsumerState<UploadDocumentsScreen> createState() =>
      _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends ConsumerState<UploadDocumentsScreen> {
  // State for the entire document flow
  int _currentDocumentIndex = 0;
  List<Document> _documents = [];

  // Data collected across all documents
  final Map<int, Map<String, dynamic>> _allDocumentsData = {};

  // State for the CURRENT document being processed
  late Map<String, TextEditingController> _textControllers;
  late Map<String, File> _uploadedFiles;
  String _dateErrorText = '';
  bool _isButtonActive = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _textControllers = {};
    _uploadedFiles = {};
  }
  void _navigateToTermsAndConditions() {
    if (_currentDocumentIndex == _documents.length - 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
      );
    }
  }

  @override
  void dispose() {
    _clearControllers();
    super.dispose();
  }

  void _clearControllers() {
    for (var controller in _textControllers.values) {
      controller.removeListener(_updateButtonState);
      controller.dispose();
    }
    _textControllers.clear();
  }

  // Sets up the controllers and initial state for the document at the current index.
  void _setupStateForCurrentDocument() {
    _clearControllers();
    _uploadedFiles = {}; // Reset files for the new document
    final currentDoc = _documents[_currentDocumentIndex];

    // Create controllers for text and date fields
    for (var field in currentDoc.requiredFields) {
      if (field.mediaType == 'text') {
        _textControllers[field.key] = TextEditingController();
      } else if (field.mediaType == 'date') {
        _textControllers['${field.key}_day'] = TextEditingController();
        _textControllers['${field.key}_month'] = TextEditingController();
        _textControllers['${field.key}_year'] = TextEditingController();
      }
    }

    // Add listeners to all new controllers to check completion status
    for (var controller in _textControllers.values) {
      controller.addListener(_updateButtonState);
    }
    _updateButtonState(); // Initial check
  }

  // Checks if all required fields for the current document are filled.
  void _updateButtonState() {
    if (_documents.isEmpty) return;

    final currentDoc = _documents[_currentDocumentIndex];
    bool allFieldsFilled = true;
    bool isDateValid = true;

    for (var field in currentDoc.requiredFields) {
      if (!field.required) continue;

      switch (field.mediaType) {
        case 'image':
        case 'file':
          if (!_uploadedFiles.containsKey(field.key)) {
            allFieldsFilled = false;
          }
          break;
        case 'text':
          if (_textControllers[field.key]?.text.isEmpty ?? true) {
            allFieldsFilled = false;
          }
          break;
        case 'date':
          final day = _textControllers['${field.key}_day']?.text ?? '';
          final month = _textControllers['${field.key}_month']?.text ?? '';
          final year = _textControllers['${field.key}_year']?.text ?? '';
          if (day.isEmpty || month.isEmpty || year.isEmpty) {
            allFieldsFilled = false;
          } else {
            isDateValid = _validateDate(field.key);
          }
          break;
      }
      if (!allFieldsFilled) break;
    }

    setState(() {
      _isButtonActive = allFieldsFilled && isDateValid;
    });
  }

  // The main logic for advancing to the next document or finishing the flow.
  void _handleNextStep() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final currentDoc = _documents[_currentDocumentIndex];
    final currentData = <String, dynamic>{};

    // Save data from the current form into a map
    for (var field in currentDoc.requiredFields) {
      switch (field.mediaType) {
        case 'image':
        case 'file':
          currentData[field.key] = _uploadedFiles[field.key];
          break;
        case 'text':
          currentData[field.key] = _textControllers[field.key]!.text;
          break;
        case 'date':
          final day = _textControllers['${field.key}_day']!.text;
          final month = _textControllers['${field.key}_month']!.text;
          final year = _textControllers['${field.key}_year']!.text;
          // Storing in a standard format
          currentData[field.key] = '$year-$month-$day';
          break;
      }
    }
    _allDocumentsData[currentDoc.id] = currentData;

    try {
      // Call the new API function to upload the document
      final response = await ref.read(apiServiceProvider).uploadDocument(
        currentDoc.id,
        currentData,
      );

      if (response.status) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document "${currentDoc.name}" uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Documents are already Uploaded ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Show error message for network or other exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload document: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {

      if (_currentDocumentIndex < _documents.length - 1) {
        setState(() {
          _currentDocumentIndex++;
          _setupStateForCurrentDocument();
        });
      } else {
        _navigateToTermsAndConditions();
    print("All documents collected: $_allDocumentsData");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All documents have been processed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Navigates to the ReviewDocumentScreen for uploading one or more images.
  Future<void> _startImageUploadFlow(List<RequiredField> imageFields) async {
    final Map<String, File>? result =
    await Navigator.of(context).push<Map<String, File>>(
      MaterialPageRoute(
        builder: (context) => ReviewDocumentScreen(
          allRequiredFields: imageFields,
          currentIndex: 0,
          uploadedImages: Map.from(_uploadedFiles), // Pass existing images
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _uploadedFiles.addAll(result);
      });
      _updateButtonState();
    }
  }

  // The method to handle file picking
  void _pickFile(String fieldKey) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _uploadedFiles[fieldKey] = File(result.files.single.path!);
      });
      _updateButtonState();
    }
  }

  bool _validateDate(String key) {
    try {
      final day = int.parse(_textControllers['${key}_day']!.text);
      final month = int.parse(_textControllers['${key}_month']!.text);
      final year = int.parse(_textControllers['${key}_year']!.text);
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
        setState(() => _dateErrorText = newError);
      }
      return newError.isEmpty;
    } catch (e) {
      if (_dateErrorText != 'Invalid date format') {
        setState(() => _dateErrorText = 'Invalid date format');
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsyncValue = ref.watch(documentsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: documentsAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (documentList) {
            // This setup logic runs once when data is first loaded.
            if (_documents.isEmpty && documentList.isNotEmpty) {
              _documents = documentList;
              // We use a post-frame callback to safely set state after the build.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _setupStateForCurrentDocument();
              });
            }

            if (_documents.isEmpty) {
              return const Center(child: Text("No documents to upload."));
            }

            final currentDocument = _documents[_currentDocumentIndex];
            final isLastDocument = _currentDocumentIndex == _documents.length - 1;

            // Filter fields to dynamically build the UI
            final imageFields = currentDocument.requiredFields
                .where((f) => f.mediaType == 'image')
                .toList();
            final textFields = currentDocument.requiredFields
                .where((f) => f.mediaType == 'text')
                .toList();
            final dateFields = currentDocument.requiredFields
                .where((f) => f.mediaType == 'date')
                .toList();
            final fileFields = currentDocument.requiredFields
                .where((f) => f.mediaType == 'file')
                .toList();

            return SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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
                    currentDocument.name, // Dynamic Title
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.darkGreyBlue,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentDocument.description, // Dynamic Description
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),

                  // Dynamically build UI sections based on field types
                  if (imageFields.isNotEmpty)
                    _buildImageUploadSection(imageFields),

                  ...textFields.map((field) => Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: _buildTextField(
                        controller: _textControllers[field.key]!,
                        hintText: field.name),
                  )),

                  ...dateFields.map((field) => Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: _buildExpiryDateSection(field: field),
                  )),

                  // Add the file upload section here
                  ...fileFields.map((field) => _buildFileSelectionSection(field)),

                  if (_dateErrorText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _dateErrorText,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 150),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (_isButtonActive && !_isLoading) ? _handleNextStep : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_isButtonActive && !_isLoading)
                            ? ColorManager.blue
                            : ColorManager.lightBlueBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                          : Text(
                        isLastDocument ? "Finish" : "Next Step",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: (_isButtonActive && !_isLoading)
                              ? Colors.white
                              : Colors.grey.shade400,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPageIndicator(
                    currentPage: _currentDocumentIndex + 1,
                    pageCount: _documents.length,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

// lib/presentation/pages/Documents/UploadDocumentsScreen.dart

  Widget _buildImageUploadSection(List<RequiredField> fields) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: fields.map((field) {
        final imageFile = _uploadedFiles[field.key];
        return _buildUploadBox(
          key: ValueKey(field.key),
          label: field.name,
          imageFile: imageFile,
          onTap: () => _startImageUploadFlow(fields),
          onDelete: () {
            setState(() {
              _uploadedFiles.remove(field.key);
            });
            _updateButtonState();
          },
        );
      }).toList(),
    );
  }

  Widget _buildUploadBox({
    required String label,
    required File? imageFile,
    required VoidCallback onTap,
    required VoidCallback onDelete,
    required ValueKey<String> key,
  }) {
    return Expanded(
      child: Column(
        children: [
          GestureDetector(
            onTap: imageFile != null ? null : onTap, // Only allow tapping if no image is selected
            child: Container(
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                color: ColorManager.lightBlueBackground,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Stack(
                children: [
                  if (imageFile != null)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.file(
                          imageFile,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        Icons.add,
                        color: ColorManager.black,
                        size: 30,
                      ),
                    ),
                  if (imageFile != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
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

  Widget _buildTextField(
      {required TextEditingController controller, required String hintText}) {
    return TextFormField(
      controller: controller,
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
// lib/presentation/pages/Documents/UploadDocumentsScreen.dart

  Widget _buildFileSelectionSection(RequiredField field) {
    final file = _uploadedFiles[field.key];
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColorManager.darkGreyBlue,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _pickFile(field.key),
            icon: const Icon(Icons.upload_file),
            label: Text(file?.path.split('/').last ?? 'Select File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.lightBlueBackground,
              foregroundColor: ColorManager.darkGreyBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (file != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'File selected: ${file.path.split('/').last}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpiryDateSection({required RequiredField field}) {
    // Safely get the controllers from the map without using the '!' operator.
    final dayController = _textControllers['${field.key}_day'];
    final monthController = _textControllers['${field.key}_month'];
    final yearController = _textControllers['${field.key}_year'];


    if (dayController == null || monthController == null || yearController == null) {
      return const SizedBox.shrink();
    }

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
            field.name, // Dynamic label
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColorManager.darkGreyBlue,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDateInputBox(
                  controller: dayController, hint: 'Day', maxLength: 2),
              const SizedBox(width: 12),
              _buildDateInputBox(
                  controller: monthController, hint: 'Month', maxLength: 2),
              const SizedBox(width: 12),
              _buildDateInputBox(
                  controller: yearController, hint: 'Year', maxLength: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateInputBox(
      {required TextEditingController controller,
        required String hint,
        required int maxLength}) {
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
        bool isCurrent = index == currentPage - 1;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: isCurrent ? 24.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: isCurrent
                ? ColorManager.blue
                : ColorManager.lightBlueBackground,
            borderRadius: BorderRadius.circular(4.0),
          ),
        );
      }),
    );
  }
}