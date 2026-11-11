class PhonePasswordLoginRequest {
  final String phoneNumber;
  final String password;

  PhonePasswordLoginRequest({
    required this.phoneNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      // Phone (any format, no country code = India) or email.
      'identifier': phoneNumber,
      'password': password,
    };
  }
}
