import 'package:flutter/material.dart';

enum TripStatus { scheduled, inProgress, completed }

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  TripStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
        return TripStatus.inProgress;
      case 'completed':
        return TripStatus.completed;
      default:
        return TripStatus.scheduled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsedStatus = _parseStatus(status);
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;
    String label;

    switch (parsedStatus) {
      case TripStatus.scheduled:
        backgroundColor = Colors.blueGrey.withValues(alpha: 0.2);
        textColor = theme.brightness == Brightness.dark
            ? Colors.blueGrey.shade100
            : Colors.blueGrey.shade800;
        label = 'Scheduled';
        break;
      case TripStatus.inProgress:
        backgroundColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange.shade700;
        label = 'In Progress';
        break;
      case TripStatus.completed:
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green.shade700;
        label = 'Completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
