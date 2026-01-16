import 'package:flutter/material.dart';
import '../models/activity_feedback.dart';

class FeedbackDialog extends StatefulWidget {
  final String activityId;
  const FeedbackDialog({super.key, required this.activityId});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  bool _attended = true;
  bool? _enjoyed;
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Activity Feedback'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Did you attend the activity?'),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _attended = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _attended ? Colors.green : Colors.grey[200],
                    ),
                    child: const Text('Yes'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _attended = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_attended ? Colors.red : Colors.grey[200],
                    ),
                    child: const Text('No'),
                  ),
                ),
              ],
            ),
            if (_attended) ...[
              const SizedBox(height: 16),
              const Text('Did you enjoy it?'),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _enjoyed = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _enjoyed == true ? Colors.green : Colors.grey[200],
                      ),
                      child: const Text('Yes'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _enjoyed = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _enjoyed == false ? Colors.red : Colors.grey[200],
                      ),
                      child: const Text('No'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Rating (1-5):'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setState(() => _rating = index + 1),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final feedback = ActivityFeedback(
              activityId: widget.activityId,
              attended: _attended,
              enjoyed: _attended ? _enjoyed : null,
              rating: _attended ? _rating : null,
              feedbackAt: DateTime.now(),
            );
            Navigator.pop(context, feedback);
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
