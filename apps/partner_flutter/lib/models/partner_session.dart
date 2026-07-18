class PartnerSession {
  const PartnerSession({
    required this.partnerId,
    required this.token,
    required this.refreshToken,
    required this.mobile,
    required this.role,
    required this.name,
  });

  final String partnerId;
  final String token;
  final String refreshToken;
  final String mobile;
  final String role;
  final String name;

  PartnerSession copyWith({String? token, String? refreshToken}) =>
      PartnerSession(
        partnerId: partnerId,
        token: token ?? this.token,
        refreshToken: refreshToken ?? this.refreshToken,
        mobile: mobile,
        role: role,
        name: name,
      );

  Map<String, dynamic> toJson() => {
        'partnerId': partnerId,
        'token': token,
        'refreshToken': refreshToken,
        'mobile': mobile,
        'role': role,
        'name': name,
      };

  factory PartnerSession.fromJson(Map<String, dynamic> json) => PartnerSession(
        partnerId: (json['partnerId'] ?? '').toString(),
        token: (json['token'] ?? '').toString(),
        refreshToken: (json['refreshToken'] ?? '').toString(),
        mobile: (json['mobile'] ?? '').toString(),
        role: (json['role'] ?? 'PROMOTER').toString(),
        name: (json['name'] ?? 'Partner').toString(),
      );
}
