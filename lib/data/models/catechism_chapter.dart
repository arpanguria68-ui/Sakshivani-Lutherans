class CatechismChapter {
  const CatechismChapter({
    required this.id,
    required this.title,
    required this.content,
  });

  final String id;
  final String title;
  final String content;

  factory CatechismChapter.fromJson(Map<String, dynamic> json) {
    return CatechismChapter(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}
