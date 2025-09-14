import 'constants.dart';

extension NonNullString on String? {
  String orEmpty() {
    if (this == null) {
      return Constants.empty;
    } else {
      return this!;
    }
  }
}

extension NonNullInteger on int? {
  int orZero() {
    if (this == null) {
      return Constants.zero;
    } else {
      return this!;
    }
  }
}



extension PhoneNumberValidation on String {
  bool isValidPhoneNumber() {
    // Simple validation - adjust according to your needs
    final phoneRegExp = RegExp(r'^[0-9]{10,15}$');
    return phoneRegExp.hasMatch(this);
  }
}