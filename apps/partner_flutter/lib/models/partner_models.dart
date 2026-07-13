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
        name = '${json['name'] ?? json['fullName'] ?? 'Driver'}',
        vehicle = '${json['vehicleNumber'] ?? '-'}',
        mobile = '${json['mobile'] ?? ''}',
        status = '${json['status'] ?? 'DRAFT'}',
        approval = ((json['approval'] as Map?) ?? const {})
            .cast<String, dynamic>(),
        verification = ((json['verification'] as Map?) ?? const {})
            .cast<String, dynamic>(),
        partnerActions = ((json['partnerActions'] as Map?) ?? const {})
            .cast<String, dynamic>(),
        online = json['online'] == true,
        requests = (json['requests'] ?? 0) as int,
        completed = (json['completed'] ?? 0) as int,
        rejected = (json['rejected'] ?? 0) as int,
        cancelled = (json['cancelled'] ?? 0) as int,
        acceptance = (json['acceptanceRate'] ?? 0).toDouble(),
        cancellationRate = (json['cancellationRate'] ?? 0).toDouble(),
        rating = (json['rating'] ?? 0).toDouble(),
        onlineHours = (json['onlineHours'] ?? 0).toDouble(),
        lateArrivals = (json['lateArrivals'] ?? 0) as int,
        lastOnline = '${json['lastOnline'] ?? json['lastOnlineAt'] ?? '-'}';

  final String id;
  final String name;
  final String vehicle;
  final String mobile;
  final String status;
  final Map<String, dynamic> approval;
  final Map<String, dynamic> verification;
  final Map<String, dynamic> partnerActions;
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

  bool get canApprove => partnerActions['canApprove'] == true;
  String get reviewStage => '${partnerActions['stage'] ?? ''}';
  String get promoterStatus =>
      '${((approval['promoter'] as Map?) ?? const {})['status'] ?? 'PENDING'}';
  String get areaStatus =>
      '${((approval['areaPromoter'] as Map?) ?? const {})['status'] ?? 'PENDING'}';
  String get adminStatus =>
      '${((approval['admin'] as Map?) ?? const {})['status'] ?? 'PENDING'}';
  int get uploadedDocuments {
    final required = (verification['requiredCount'] as num?)?.toInt() ?? 5;
    final missing = (verification['missingCount'] as num?)?.toInt() ?? 5;
    return required - missing;
  }

  int get requiredDocuments =>
      (verification['requiredCount'] as num?)?.toInt() ?? 5;

  bool get needsAttention =>
      acceptance < 65 || cancellationRate > 12 || rejected >= 5;

  bool get topPerformer =>
      completed >= 10 &&
      acceptance >= 85 &&
      cancellationRate <= 5;
}
