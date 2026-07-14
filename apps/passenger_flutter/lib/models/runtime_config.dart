class RuntimeConfig {
  const RuntimeConfig({
    required this.serviceEnabled,
    required this.newBookingsEnabled,
    required this.maintenanceMode,
    required this.minimumVersion,
    required this.latestVersion,
    required this.paymentMethods,
    required this.upiPreDispatchRequired,
    required this.sosEnabled,
    required this.emergencyNumber,
  });

  final bool serviceEnabled;
  final bool newBookingsEnabled;
  final bool maintenanceMode;
  final String minimumVersion;
  final String latestVersion;
  final List<String> paymentMethods;
  final bool upiPreDispatchRequired;
  final bool sosEnabled;
  final String emergencyNumber;

  factory RuntimeConfig.fromJson(Map<String, dynamic> json) {
    final operations = json['operations'] is Map
        ? (json['operations'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final mobile = json['mobile'] is Map
        ? (json['mobile'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final payments = json['payments'] is Map
        ? (json['payments'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final safety = json['safety'] is Map
        ? (json['safety'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final rawMethods = json['paymentMethods'];

    return RuntimeConfig(
      serviceEnabled:
          operations['serviceEnabled'] != false && json['serviceEnabled'] != false,
      newBookingsEnabled: operations['newBookingsEnabled'] != false,
      maintenanceMode: json['maintenanceMode'] == true,
      minimumVersion:
          '${mobile['minimumVersion'] ?? json['minimumVersion'] ?? '1.0.0'}',
      latestVersion:
          '${mobile['latestVersion'] ?? json['latestVersion'] ?? '1.0.0'}',
      paymentMethods: rawMethods is List
          ? rawMethods.map((item) => '$item'.toUpperCase()).toList()
          : const ['CASH', 'UPI', 'BOTH'],
      upiPreDispatchRequired: payments['upiPreDispatchRequired'] != false,
      sosEnabled: safety['sosEnabled'] != false,
      emergencyNumber: '${safety['emergencyNumber'] ?? '112'}',
    );
  }

  static const fallback = RuntimeConfig(
    serviceEnabled: true,
    newBookingsEnabled: true,
    maintenanceMode: false,
    minimumVersion: '1.0.0',
    latestVersion: '1.0.0',
    paymentMethods: ['CASH', 'UPI', 'BOTH'],
    upiPreDispatchRequired: true,
    sosEnabled: true,
    emergencyNumber: '112',
  );
}
