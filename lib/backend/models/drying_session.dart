

class DryingSession {
  final String id;
  final String crop;
  final DateTime startTime;
  final String deviceId;
  String status;

  DryingSession({
    required this.id,
    required this.crop,
    required this.startTime,
    required this.deviceId,
    this.status = "active",
  });
}
