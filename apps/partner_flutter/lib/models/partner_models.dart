class PartnerSession {
  PartnerSession({
    required this.token,
    required this.name,
    required this.role,
    required this.id,
    required this.mobile,
    this.staffId = '',
    this.mustChangePassword = false,
  });

  /// Linked promoter/area-promoter id, not the staff account id.
  final String id;
  final String staffId;
  final String token;
  final String name;
  final String role;
  final String mobile;
  final bool mustChangePassword;

  factory PartnerSession.fromJson(Map<String, dynamic> json) {
    final staff =
        ((json['partner'] ?? json['staff'] ?? json['user']) as Map? ??
                const {})
            .cast<String, dynamic>();

    return PartnerSession(
      token: '${json['accessToken'] ?? json['token'] ?? ''}',
      id: '${staff['linkedEntityId'] ?? staff['id'] ?? json['userId'] ?? ''}',
      staffId: '${staff['id'] ?? ''}',
      name: '${staff['name'] ?? 'Partner'}',
      role: '${staff['role'] ?? 'PROMOTER'}',
      mobile: '${staff['mobile'] ?? ''}',
      mustChangePassword:
          json['mustChangePassword'] == true ||
          staff['mustChangePassword'] == true,
    );
  }

  PartnerSession copyWith({
    String? id,
    String? staffId,
    String? name,
    String? role,
    String? mobile,
    bool? mustChangePassword,
  }) =>
      PartnerSession(
        token: token,
        id: id ?? this.id,
        staffId: staffId ?? this.staffId,
        name: name ?? this.name,
        role: role ?? this.role,
        mobile: mobile ?? this.mobile,
        mustChangePassword:
            mustChangePassword ?? this.mustChangePassword,
      );
}

class DriverPerformance {
  DriverPerformance.fromJson(Map<String, dynamic> json)
      : id = '${json['driverId'] ?? json['id'] ?? ''}',
        name = '${json['name'] ?? 'Driver'}',
        vehicle = '${json['vehicleNumber'] ?? '-'}',
        mobile = '${json['mobile'] ?? ''}',
        online = json['online'] == true,
        requests = (json['requests'] ?? 0) as int,
        completed = (json['completed'] ?? 0) as int,
        rejected = (json['rejected'] ?? 0) as int,
        cancelled = (json['cancelled'] ?? 0) as int,
        acceptance = (json['acceptanceRate'] ?? 0).toDouble(),
        cancellationRate =
            (json['cancellationRate'] ?? 0).toDouble(),
        rating = (json['rating'] ?? 0).toDouble(),
        onlineHours = (json['onlineHours'] ?? 0).toDouble(),
        lateArrivals = (json['lateArrivals'] ?? 0) as int,
        lastOnline = '${json['lastOnline'] ?? '-'}';

  final String id;
  final String name;
  final String vehicle;
  final String mobile;
  final String lastOnline;
  final bool online;
  final int requests;
  final int completed;
  final int rejected;
  final int cancelled;
  final int lateArrivals;
  final double acceptance;
  final double cancellationRate;
  final double rating;
  final double onlineHours;

  bool get needsAttention =>
      acceptance < 65 || cancellationRate > 12 || rejected >= 5;

  bool get topPerformer =>
      completed >= 10 &&
      acceptance >= 85 &&
      cancellationRate <= 5;
}
