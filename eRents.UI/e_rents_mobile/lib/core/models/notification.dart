class Notification {
  final int id;
  final String title;
  final String message;
  final DateTime date;
  final bool isRead;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.isRead,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      date: DateTime.parse(json['date']),
      isRead: json['isRead'],
    );
  }
}
