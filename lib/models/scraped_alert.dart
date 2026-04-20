class ScrapedAlert {
  final int? id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String line;
  final String? postUrl;

  ScrapedAlert({
    this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.line,
    this.postUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'line': line,
      // Note: postUrl might need to be added to DB schema if persistence is needed for it
    };
  }

  factory ScrapedAlert.fromMap(Map<String, dynamic> map) {
    return ScrapedAlert(
      id: map['id'],
      title: map['title'] ?? 'Alert',
      message: map['message'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      line: map['line'] ?? 'Unknown',
    );
  }

  // Legacy support for JSON sync
  Map<String, dynamic> toJson() => toMap();
  factory ScrapedAlert.fromJson(Map<String, dynamic> json) => ScrapedAlert.fromMap(json);
}
