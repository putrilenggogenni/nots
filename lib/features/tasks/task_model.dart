class Task {
  Task({
    required this.id,
    required this.title,
    this.notes,
    this.dueAt,
    required this.status,
    this.courseName,
    this.rawText,
    this.createdAt,
  });

  final String id;
  final String title;
  final String? notes;
  final DateTime? dueAt;
  final String status;
  final String? courseName;
  final String? rawText;
  final DateTime? createdAt;

  bool get isDone => status == 'done';

  factory Task.fromMap(Map<String, dynamic> m) {
    final course = m['courses'] as Map<String, dynamic>?;
    return Task(
      id: m['id'] as String,
      title: m['title'] as String,
      notes: m['notes'] as String?,
      dueAt: m['due_at'] == null
          ? null
          : DateTime.parse(m['due_at'] as String).toLocal(),
      status: (m['status'] as String?) ?? 'todo',
      courseName: course?['name'] as String?,
      rawText: m['raw_text'] as String?,
      createdAt: m['created_at'] == null
          ? null
          : DateTime.parse(m['created_at'] as String).toLocal(),
    );
  }
}
