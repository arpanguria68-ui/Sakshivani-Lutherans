import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/models/quiz_question.dart';
import '../../../shared/widgets/app_backdrop.dart';
import '../../../shared/widgets/glass_card.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _revealed = false;

  void _answer(QuizQuestion q, int selected) {
    if (_revealed) {
      return;
    }
    setState(() {
      _selected = selected;
      _revealed = true;
      if (selected == q.correctOptionIndex) {
        _score += 1;
      }
    });
  }

  void _next(List<QuizQuestion> questions) {
    if (_index >= questions.length - 1) {
      setState(() {
        _index = questions.length;
      });
      ref.read(analyticsServiceProvider).logQuizCompleted(score: _score, total: questions.length);
      ref.read(adServiceProvider).showInterstitialIfReady();
      return;
    }
    setState(() {
      _index += 1;
      _selected = null;
      _revealed = false;
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _score = 0;
      _selected = null;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<QuizQuestion>> quiz = ref.watch(quizQuestionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bible Quiz')),
      body: AppBackdrop(
        child: SafeArea(
          child: quiz.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object e, StackTrace _) => Center(child: Text('Could not load quiz: $e')),
            data: (List<QuizQuestion> questions) {
              if (questions.isEmpty) {
                return const Center(child: Text('No quiz questions available.'));
              }

              if (_index >= questions.length) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GlassCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text('Quiz Complete', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 10),
                          Text('Score: $_score / ${questions.length}'),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _restart, child: const Text('Play Again')),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final QuizQuestion current = questions[_index];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: <Widget>[
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Question ${_index + 1}/${questions.length}'),
                        const SizedBox(height: 8),
                        Text(current.text, style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List<Widget>.generate(current.options.length, (int idx) {
                    final bool isCorrect = idx == current.correctOptionIndex;
                    final bool isSelected = idx == _selected;
                    Color? bg;
                    if (_revealed && isCorrect) {
                      bg = const Color.fromRGBO(76, 175, 80, 0.2);
                    } else if (_revealed && isSelected && !isCorrect) {
                      bg = const Color.fromRGBO(244, 67, 54, 0.2);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        onTap: () => _answer(current, idx),
                        child: Container(
                          color: bg,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(current.options[idx]),
                        ),
                      ),
                    );
                  }),
                  if (_revealed)
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Explanation', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(current.explanation ?? ''),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => _next(questions),
                            child: Text(_index == questions.length - 1 ? 'Finish' : 'Next Question'),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

final FutureProvider<List<QuizQuestion>> quizQuestionsProvider =
    FutureProvider<List<QuizQuestion>>((FutureProviderRef<List<QuizQuestion>> ref) async {
  return ref.read(contentRepositoryProvider).getQuizQuestions();
});
