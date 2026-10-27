class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: $message ${code != null ? "($code)" : ""}';
}

class AuthException extends AppException {
  AuthException(super.message, [super.code]);
}

class PermissionDeniedException extends AppException {
  PermissionDeniedException(String message) : super(message, 'PERMISSION_DENIED');
}

class DoctorNotVerifiedException extends AppException {
  DoctorNotVerifiedException()
      : super(
          'Doctor verification required. Access is granted only to approved medical professionals.',
          'DOCTOR_UNVERIFIED',
        );
}
