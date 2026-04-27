class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.subscriptionTier,
    required this.accountStatus,
    required this.emailVerified,
    required this.phoneVerified,
  });

  final String id;
  final String email;
  final String fullName;
  final String subscriptionTier;
  final String accountStatus;
  final bool emailVerified;
  final bool phoneVerified;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['fullName'] as String,
        subscriptionTier: json['subscriptionTier'] as String,
        accountStatus: json['accountStatus'] as String,
        emailVerified: json['emailVerified'] as bool,
        phoneVerified: json['phoneVerified'] as bool,
      );
}

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.user,
  });

  final String accessToken;
  final AuthUser user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: json['accessToken'] as String,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}