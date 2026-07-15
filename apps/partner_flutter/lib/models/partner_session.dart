class PartnerSession {
  const PartnerSession({
    required this.partnerId,
    required this.token,
    required this.mobile,
    required this.role,
    required this.name,
  });

  final String partnerId;
  final String token;
  final String mobile;
  final String role;
  final String name;

  Map<String, dynamic> toJson() => {
        'partnerId': partnerId,
        'token': token,
        'mobile': mobile,
        'role': role,
        'name': name,
      };

  factory PartnerSession.fromJson(Map<String, dynamic> json) => PartnerSession(
        partnerId: (json['partnerId'] ?? '').toString(),
        token: (json['token'] ?? '').toString(),
        mobile: (json['mobile'] ?? '').toString(),
        role: (json['role'] ?? 'PROMOTER').toString(),
        name: (json['name'] ?? 'Partner').toString(),
      );
}
