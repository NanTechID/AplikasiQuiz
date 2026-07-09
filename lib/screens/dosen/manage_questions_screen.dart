import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quiz_model.dart';
import '../../providers/quiz_provider.dart';
import '../../utils/theme.dart';
import 'add_question_screen.dart';

class ManageQuestionsScreen extends StatefulWidget {
  final QuizModel quiz;

  const ManageQuestionsScreen({super.key, required this.quiz});

  @override
  State<ManageQuestionsScreen> createState() => _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends State<ManageQuestionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuizProvider>(context, listen: false).loadQuestions(widget.quiz.id);
    });
  }

  Future<void> _deleteQuestion(QuizProvider provider, String questionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question?'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.deleteQuestion(widget.quiz.id, questionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question deleted.'), backgroundColor: AppTheme.accent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Questions'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddQuestionScreen(quizId: widget.quiz.id),
            ),
          ).then((_) {
            if (!mounted) return;
            Provider.of<QuizProvider>(context, listen: false).loadQuestions(widget.quiz.id);
          });
        },
        label: const Text('Add Question', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_circle_outline_rounded),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<QuizProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = provider.questions;

          if (questions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.help_outline_rounded, size: 54, color: Colors.grey.withOpacity(0.5)),
                    const SizedBox(height: 14),
                    const Text(
                      'No questions added to this quiz yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Quizzes must have at least one question before they can be opened for students.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
            itemCount: questions.length,
            itemBuilder: (context, idx) {
              final q = questions[idx];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                color: isDark ? AppTheme.darkSurface : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 28,
                            width: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              q.text,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      // Options list
                      Column(
                        children: List.generate(q.options.length, (optIdx) {
                          final isCorrect = optIdx == q.correctOptionIndex;
                          final optionLabel = String.fromCharCode(65 + optIdx); // A, B, C, D

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? AppTheme.openColor.withOpacity(0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCorrect
                                    ? AppTheme.openColor.withOpacity(0.4)
                                    : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: isCorrect ? AppTheme.openColor : Colors.grey[400],
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
                                      color: isCorrect ? AppTheme.openColor : null,
                                      fontWeight: isCorrect ? FontWeight.bold : null,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (isCorrect)
                                  const Icon(Icons.check_circle_rounded, color: AppTheme.openColor, size: 18),
                              ],
                            ),
                          );
                        }),
                      ),
                      const Divider(height: 24),
                      // Actions row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddQuestionScreen(
                                    quizId: widget.quiz.id,
                                    question: q,
                                  ),
                                ),
                              ).then((_) {
                                provider.loadQuestions(widget.quiz.id);
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accent, size: 20),
                            onPressed: () => _deleteQuestion(provider, q.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
