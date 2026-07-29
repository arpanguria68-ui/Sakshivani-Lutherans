import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sakshi_vani/data/models/quiz_question.dart';
import 'package:sakshi_vani/features/quiz/presentation/quiz_screen.dart';

const List<QuizQuestion> _questions = <QuizQuestion>[
  QuizQuestion(
    id: 'q1',
    text: 'Who built the ark?',
    options: <String>['Noah', 'Moses'],
    correctOptionIndex: 0,
    difficulty: 'easy',
    explanation: 'Genesis 6.',
  ),
  QuizQuestion(
    id: 'q2',
    text: 'Who led the Israelites out of Egypt?',
    options: <String>['David', 'Moses'],
    correctOptionIndex: 1,
    difficulty: 'easy',
    explanation: 'Exodus.',
  ),
];

Widget _buildApp({List<QuizQuestion> questions = _questions}) {
  return ProviderScope(
    overrides: <Override>[
      quizQuestionsProvider.overrideWith((ref) async => questions),
    ],
    child: const MaterialApp(home: QuizScreen()),
  );
}

void main() {
  testWidgets('loads questions and shows the first one', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Question 1/2'), findsOneWidget);
    expect(find.text('Who built the ark?'), findsOneWidget);
  });

  testWidgets('selecting the correct answer reveals explanation and scores it', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Noah'));
    await tester.pumpAndSettle();

    expect(find.text('Explanation'), findsOneWidget);
    expect(find.text('Genesis 6.'), findsOneWidget);

    await tester.tap(find.text('Next Question'));
    await tester.pumpAndSettle();

    expect(find.text('Question 2/2'), findsOneWidget);
  });

  testWidgets('a second tap on the same revealed question does not change the score',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Noah')); // correct answer for q1
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moses')); // second tap, same question — should be ignored
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next Question'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moses')); // correct answer for q2
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text('Score: 2 / 2'), findsOneWidget);
  });

  testWidgets('completing the quiz shows the final score and Play Again resets it',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Noah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next Question'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Moses'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text('Quiz Complete'), findsOneWidget);
    expect(find.text('Score: 2 / 2'), findsOneWidget);

    await tester.tap(find.text('Play Again'));
    await tester.pumpAndSettle();

    expect(find.text('Question 1/2'), findsOneWidget);
  });

  testWidgets('shows an empty-state message when there are no questions', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(questions: const <QuizQuestion>[]));
    await tester.pumpAndSettle();

    expect(find.text('No quiz questions available.'), findsOneWidget);
  });
}
