class ActivityFeedback {
  final String activityId;
  final bool attended;
  final bool? enjoyed;
  final int? rating;
  final DateTime feedbackAt;

  ActivityFeedback({
    required this.activityId,
    required this.attended,
    this.enjoyed,
    this.rating,
    required this.feedbackAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'activityId': activityId,
      'attended': attended,
      'enjoyed': enjoyed,
      'rating': rating,
      'feedbackAt': feedbackAt.toIso8601String(),
    };
  }
}
