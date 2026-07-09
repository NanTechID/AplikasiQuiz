import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quiz_model.dart';
import '../../models/answer_model.dart';
import '../../models/question_model.dart';
import '../../providers/quiz_provider.dart';
import '../../utils/theme.dart';

class ReviewAnswersScreen extends StatefulWidget {
  final QuizModel quiz;
  final AnswerModel submission;

  const ReviewAnswersScreen({
    super.key,
    required this.quiz,
    required this.submission,
  });

  @override
  State<ReviewAnswersScreen> createState() => _ReviewAnswersScreenState();
}

class _ReviewAnswersScreenState extends State<ReviewAnswersScreen> {
  List<QuestionModel> _questions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    // Load question definitions for this quiz
    try {
      final fetched = provider.activeQuestions.isNotEmpty && provider.activeQuiz?.id == widget.quiz.id
          ? provider.activeQuestions
          : await provider.loadQuestions(widget.quiz.id).then((_) => provider.questions);
      
      setState(() {
        _questions = fetched;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Answers'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? const Center(child: Text('Questions could not be loaded for review.'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top summary widget
                    Container(
                      color: isDark ? AppTheme.darkSurface : Colors.grey[200],
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.quiz.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your Score: ${widget.submission.score} | Correct Answers: ${widget.submission.correctCount} of ${_questions.length}',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Question list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _questions.length,
                        itemBuilder: (context, idx) {
                          final q = _questions[idx];
                          final selectedIdx = widget.submission.selectedAnswers[q.id];
                          final isCorrect = selectedIdx != null && selectedIdx == q.correctOptionIndex;

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isCorrect
                                    ? AppTheme.openColor.withOpacity(0.3)
                                    : AppTheme.accent.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            color: isDark ? AppTheme.darkSurface : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Question Header
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (isCorrect ? AppTheme.openColor : AppTheme.accent).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Q${idx + 1}',
                                          style: TextStyle(
                                            color: isCorrect ? AppTheme.openColor : AppTheme.accent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          q.text,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  
                                  // Question Options
                                  Column(
                                    children: List.generate(q.options.length, (optIdx) {
                                      final optionLabel = String.fromCharCode(65 + optIdx);
                                      final bool isStudentSelection = selectedIdx == optIdx;
                                      final bool isCorrectOption = q.correctOptionIndex == optIdx;
                                      
                                      Color optionBorderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
                                      Color optionBgColor = Colors.transparent;

                                      if (isCorrectOption) {
                                        optionBorderColor = AppTheme.openColor;
                                        optionBgColor = AppTheme.openColor.withOpacity(0.06);
                                      } else if (isStudentSelection) {
                                        optionBorderColor = AppTheme.accent;
                                        optionBgColor = AppTheme.accent.withOpacity(0.06);
                                      }

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: optionBgColor,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: optionBorderColor),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: isCorrectOption 
                                                  ? AppTheme.openColor 
                                                  : (isStudentSelection ? AppTheme.accent : Colors.grey[400]),
                                              child: Text(
                                                optionLabel,
                                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                q.options[optIdx],
                                                style: TextStyle(
                                                  color: isCorrectOption 
                                                      ? AppTheme.openColor 
                                                      : (isStudentSelection ? AppTheme.accent : null),
                                                  fontWeight: (isCorrectOption || isStudentSelection) ? FontWeight.bold : null,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            if (isCorrectOption)
                                              const Icon(Icons.check_circle_rounded, color: AppTheme.openColor, size: 18),
                                            if (isStudentSelection && !isCorrectOption)
                                              const Icon(Icons.cancel_rounded, color: AppTheme.accent, size: 18),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                  
                                  // Unanswered Tag Warning
                                  if (selectedIdx == null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accent.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.warning_amber_rounded, color: AppTheme.accent, size: 14),
                                          SizedBox(width: 6),
                                          Text(
                                            'You did not answer this question.',
                                            style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
