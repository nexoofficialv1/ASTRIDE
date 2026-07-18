class Session {
  const Session({
    required this.userId,
    required this.token,
    required this.refreshToken,
    required this.mobile,
    this.staffId = '',
    this.mustChangePassword = false,
    this.role = 'DRIVER',
  });

  final String userId;
  final String staffId;
  final String token;
  final String refreshToken;
  final String mobile;
  final bool mustChangePassword;
  final String role;

  Map<String, String> get authHeaders => {
        'authorization': 'Bearer $token',
      };

  Session copyWith({
    String? userId,
    String? staffId,
    String? token,
    String? refreshToken,
    String? mobile,
    bool? mustChangePassword,
    String? role,
  }) =>
      Session(
        userId: userId ?? this.userId,
        staffId: staffId ?? this.staffId,
        token: token ?? this.token,
        refreshToken: refreshToken ?? this.refreshToken,
        mobile: mobile ?? this.mobile,
        role: role ?? this.role,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      );
}
