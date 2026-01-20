
class Request {
  final int requestId;
  final String category;
  final String description;
  final String location;
  final int severity;
  final String status;

  Request({
    required this.requestId,
    required this.category,
    required this.description,
    required this.location,
    required this.severity,
    this.status = "PENDING",
  });

  @override
  String toString() {
    return 'Request($requestId, $category, $status, Sev: $severity)';
  }
}
