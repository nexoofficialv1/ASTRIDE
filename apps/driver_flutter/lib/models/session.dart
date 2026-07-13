class Session {
  const Session({
    required this.userId,
    required this.token,
    required this.mobile,
    this.staffId = '',
    this.mustChangePassword = false,
    this.role = 'DRIVER',
  });

  /// Linked driver profile id (drv_...), never the staff account id.
  final String userId;
  final String staffId;
  final String token;
  final String mobile;
  final bool mustChangePassword;
  final String role;

  Map<String, String> get authHeaders => {
        'authorization': 'Bearer $token',
      };

  Session copyWith({
    String? userId,
    String? staffId,
    String? mobile,
    bool? mustChangePassword,
    String? role,
  }) =>
      Session(
        userId: userId ?? this.userId,
        staffId: staffId ?? this.staffId,
        token: token,
        mobile: mobile ?? this.mobile,
        role: role ?? this.role,
        mustChangePassword:
            mustChangePassword ?? this.mustChangePassword,
      );
}
