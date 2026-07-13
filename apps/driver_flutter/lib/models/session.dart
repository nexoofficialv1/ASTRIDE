class Session {
  const Session({
    required this.userId,
    required this.token,
    required this.mobile,
    this.mustChangePassword = false,
    this.role = 'DRIVER',
  });

  final String userId;
  final String token;
  final String mobile;
  final bool mustChangePassword;
  final String role;

  Map<String, String> get authHeaders => {'authorization': 'Bearer $token'};

  Session copyWith({bool? mustChangePassword}) => Session(
        userId: userId,
        token: token,
        mobile: mobile,
        role: role,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      );
}
