class AppNotification {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final String type;
  final String status;
  final bool actionRequired;
  final String? relatedEntityId;
  final Map<String, dynamic> meta;
  final DateTime? completedAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.type,
    required this.status,
    required this.actionRequired,
    required this.relatedEntityId,
    required this.meta,
    this.completedAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['isRead'] as bool? ?? false,
      type: json['type'] as String? ?? 'general',
      status: json['status'] as String? ?? 'pending',
      actionRequired: json['actionRequired'] as bool? ?? false,
      relatedEntityId: json['relatedEntityId']?.toString(),
      meta: (json['meta'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString()) : null,
    );
  }
}
