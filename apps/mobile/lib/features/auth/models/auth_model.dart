class AuthUser {
  final String id;
  final String? email;
  final String? phone;
  final String fullName;
  final String language;
  final String currency;

  const AuthUser({
    required this.id,
    this.email,
    this.phone,
    required this.fullName,
    required this.language,
    required this.currency,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        fullName: json['full_name'] as String,
        language: json['language'] as String? ?? 'en',
        currency: json['currency'] as String? ?? 'USD',
      );
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
}
