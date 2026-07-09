import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quiz_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../utils/theme.dart';
import 'quiz_result_screen.dart';

class TakeQuizScreen extends StatefulWidget {
  final QuizModel quiz;

  const TakeQuizScreen({super.key, required this.quiz});

  @override
  State<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen> {
  int _currentQuestionIndex = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<QuizProvider>(context, listen: false).startQuiz(widget.quiz, auth.currentUser?.uid ?? '');
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _onSubmitTap(QuizProvider quizProvider, AuthProvider authProvider) async {
    final unansweredCount = quizProvider.activeQuestions.length - quizProvider.selectedAnswers.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Quiz?'),
        content: Text(
          unansweredCount > 0
              ? 'You have $unansweredCount unanswered questions. Are you sure you want to submit?'
              : 'Are you sure you want to finish and submit your answers?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.openColor),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _executeSubmit(quizProvider, authProvider);
    }
  }

  Future<void> _executeSubmit(QuizProvider quizProvider, AuthProvider authProvider) async {
    setState(() => _submitting = true);
    
    final submission = await quizProvider.submitQuiz(
      authProvider.currentUser?.uid ?? '',
      authProvider.currentUser?.name ?? 'Mahasiswa',
    );

    if (!mounted) return;

    if (submission != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            quiz: widget.quiz,
            submission: submission,
          ),
        ),
      );
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit. Please try again.'), backgroundColor: AppTheme.accent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return WillPopScope(
      onWillPop: () async {
        // Prevent leaving active quiz by accident
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit Quiz?'),
            content: const Text('If you exit, your active progress is not saved, but the quiz timer will keep running. Are you sure you want to exit?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No, Stay')),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (leave == true) {
          if (!mounted) return true;
          Provider.of<QuizProvider>(context, listen: false).exitQuiz();
          return true;
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.quiz.title),
          automaticallyImplyLeading: false, // Force them to use exit confirmation
          actions: [
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Exit Quiz?'),
                    content: const Text('Leave quiz session? Timer will not pause.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Provider.of<QuizProvider>(context, listen: false).exitQuiz();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                        child: const Text('Exit'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.exit_to_app_rounded, color: AppTheme.accent, size: 20),
              label: const Text('Exit', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: Consumer<QuizProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final questions = provider.activeQuestions;
            if (questions.isEmpty) {
              return const Center(child: Text('No questions found for this quiz.'));
            }

            final currentQuestion = questions[_currentQuestionIndex];
            final selectedOption = provider.selectedAnswers[currentQuestion.id];
            final timeRemaining = provider.remainingTimeSeconds;
            final isTimeLow = timeRemaining < 60; // Less than 1 minute

            // If quiz was auto-submitted because time reached 0, the timer stops and redirects in provider,
            // but in case it hasn't, we show a loading indicator if submitting.
            if (_submitting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Submitting answers, please wait...', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timer and Progress top bar
                Container(
                  color: isDark ? AppTheme.darkSurface : Colors.grey[200],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Progress Indicators
                      Text(
                        'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      
                      // Timer Indicator
                      Row(
                        children: [
                          Icon(
                            Icons.alarm,
                            color: isTimeLow ? AppTheme.accent : AppTheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(timeRemaining),
                            style: TextStyle(
                              color: isTimeLow ? AppTheme.accent : (isDark ? Colors.white : Colors.black),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Progress indicator bar
                LinearProgressIndicator(
                  value: (provider.selectedAnswers.length) / questions.length,
                  backgroundColor: isDark ? AppTheme.darkBorder : Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),

                // Question Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question Card
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                          ),
                          color: isDark ? AppTheme.darkSurface : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              currentQuestion.text,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Options
                        ...List.generate(currentQuestion.options.length, (optIdx) {
                          final label = String.fromCharCode(65 + optIdx); // A, B, C, D
                          final isCurrentSelected = selectedOption == optIdx;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: InkWell(
                              onTap: () {
                                provider.selectAnswer(currentQuestion.id, optIdx);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: isCurrentSelected 
                                      ? AppTheme.primary.withOpacity(0.08) 
                                      : (isDark ? AppTheme.darkSurface : Colors.white),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isCurrentSelected 
                                        ? AppTheme.primary 
                                        : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                                    width: isCurrentSelected ? 2.0 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: isCurrentSelected ? AppTheme.primary : Colors.grey[400],
                                      child: Text(
                                        label,
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        currentQuestion.options[optIdx],
                                        style: TextStyle(
                                          fontWeight: isCurrentSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (isCurrentSelected)
                                      const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // Navigation Controls Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      TextButton(
                        onPressed: _currentQuestionIndex > 0
                            ? () => setState(() => _currentQuestionIndex--)
                            : null,
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back_rounded),
                            SizedBox(width: 4),
                            Text('Previous'),
                          ],
                        ),
                      ),
                      
                      // Next / Submit Button
                      _currentQuestionIndex < questions.length - 1
                          ? ElevatedButton(
                              onPressed: () => setState(() => _currentQuestionIndex++),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Row(
                                children: [
                                  Text('Next'),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () => _onSubmitTap(provider, authProvider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.openColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Row(
                                children: [
                                  Text('Submit Quiz'),
                                  SizedBox(width: 4),
                                  Icon(Icons.check_rounded),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
