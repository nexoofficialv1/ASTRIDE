class Session {
  const Session({
    required this.userId,
    required this.token,
    required this.refreshToken,
    required this.mobile,
  });

  final String userId;
  final String token;
  final String refreshToken;
  final String mobile;

  Map<String, String> get authHeaders => {
        'authorization': 'Bearer $token',
      };

  Session copyWith({String? token, String? refreshToken}) => Session(
        userId: userId,
        token: token ?? this.token,
        refreshToken: refreshToken ?? this.refreshToken,
        mobile: mobile,
      );
}
