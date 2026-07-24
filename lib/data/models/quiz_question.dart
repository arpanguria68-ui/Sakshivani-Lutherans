class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
    required this.difficulty,
    this.explanation,
  });

  final String id;
  final String text;
  final List<String> options;
  final int correctOptionIndex;
  final String difficulty;
  final String? explanation;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final dynamic rawOptions = json['options'];
    final List<String> options =
        rawOptions is List ? rawOptions.map((dynamic e) => e.toString()).toList() : <String>[];

    return QuizQuestion(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      options: options,
      correctOptionIndex: (json['correctOptionIndex'] as num?)?.toInt() ?? 0,
      difficulty: json['difficulty'] as String? ?? 'easy',
      explanation: json['explanation'] as String?,
    );
  }
}
