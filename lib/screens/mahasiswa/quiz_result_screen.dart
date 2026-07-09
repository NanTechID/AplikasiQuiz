import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../../models/answer_model.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import 'review_answers_screen.dart';

class QuizResultScreen extends StatelessWidget {
  final QuizModel quiz;
  final AnswerModel submission;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.submission,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double score = submission.score;
    final isPassed = score >= 70.0;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: isDark ? AppTheme.surfaceGradient : null,
            color: isDark ? null : AppTheme.lightBg,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Animated style check mark
              Icon(
                isPassed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                color: isPassed ? AppTheme.openColor : AppTheme.accent,
                size: 80,
              ),
              const SizedBox(height: 16),
              
              Text(
                isPassed ? 'Congratulations!' : 'Keep Practicing!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                isPassed ? 'You have successfully completed the quiz.' : 'Try to review your answers to improve.',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),

              // Circular Score Gauge
              Center(
                child: Container(
                  height: 160,
                  width: 160,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.premiumShadow,
                    border: Border.all(
                      color: (isPassed ? AppTheme.openColor : AppTheme.accent).withOpacity(0.3),
                      width: 8,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        score.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: isPassed ? AppTheme.openColor : AppTheme.accent,
                        ),
                      ),
                      Text(
                        'SCORE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Stats summary row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildResultChip(
                    label: 'Correct',
                    value: submission.correctCount.toString(),
                    color: AppTheme.openColor,
                    icon: Icons.check_circle_outline_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 16),
                  _buildResultChip(
                    label: 'Incorrect',
                    value: submission.incorrectCount.toString(),
                    color: AppTheme.accent,
                    icon: Icons.highlight_off_rounded,
                    isDark: isDark,
                  ),
                ],
              ),

              const Spacer(flex: 2),

              // Buttons
              CustomButton(
                text: 'Review Answers',
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReviewAnswersScreen(
                        quiz: quiz,
                        submission: submission,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Back to Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            '$value $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
