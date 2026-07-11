class PartnerSession {
  PartnerSession({required this.token, required this.name, required this.role});
  final String token, name, role;
  factory PartnerSession.fromJson(Map<String, dynamic> j) => PartnerSession(
        token: j['token'] as String,
        name: (j['partner']?['name'] ?? 'Partner').toString(),
        role: (j['partner']?['role'] ?? 'PROMOTER').toString(),
      );
}

class DriverPerformance {
  DriverPerformance.fromJson(Map<String, dynamic> j)
      : id = (j['driverId'] ?? j['id'] ?? '').toString(),
        name = (j['name'] ?? 'Driver').toString(),
        vehicle = (j['vehicleNumber'] ?? '-').toString(),
        mobile = (j['mobile'] ?? '').toString(),
        online = j['online'] == true,
        requests = (j['requests'] ?? 0) as int,
        completed = (j['completed'] ?? 0) as int,
        rejected = (j['rejected'] ?? 0) as int,
        cancelled = (j['cancelled'] ?? 0) as int,
        acceptance = (j['acceptanceRate'] ?? 0).toDouble(),
        cancellationRate = (j['cancellationRate'] ?? 0).toDouble(),
        rating = (j['rating'] ?? 0).toDouble(),
        onlineHours = (j['onlineHours'] ?? 0).toDouble(),
        lateArrivals = (j['lateArrivals'] ?? 0) as int,
        lastOnline = (j['lastOnline'] ?? '-').toString();

  final String id, name, vehicle, mobile, lastOnline;
  final bool online;
  final int requests, completed, rejected, cancelled, lateArrivals;
  final double acceptance, cancellationRate, rating, onlineHours;

  bool get needsAttention => acceptance < 65 || cancellationRate > 12 || rejected >= 5;
  bool get topPerformer => completed >= 10 && acceptance >= 85 && cancellationRate <= 5;
}
