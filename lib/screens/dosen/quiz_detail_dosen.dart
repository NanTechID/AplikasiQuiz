import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/quiz_model.dart';
import '../../providers/quiz_provider.dart';
import '../../utils/theme.dart';
import 'manage_quiz_screen.dart';
import 'manage_questions_screen.dart';

class QuizDetailDosen extends StatefulWidget {
  final QuizModel quiz;

  const QuizDetailDosen({super.key, required this.quiz});

  @override
  State<QuizDetailDosen> createState() => _QuizDetailDosenState();
}

class _QuizDetailDosenState extends State<QuizDetailDosen> {
  @override
  void initState() {
    super.initState();
    // Load questions and submissions in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<QuizProvider>(context, listen: false);
      provider.loadQuestions(widget.quiz.id);
      provider.loadQuizSubmissions(widget.quiz.id);
    });
  }

  Future<void> _deleteQuiz(QuizProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quiz?'),
        content: Text('Are you sure you want to delete "${widget.quiz.title}" and all its questions/scores?'),
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

    if (confirm == true && mounted) {
      await provider.deleteQuiz(widget.quiz.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz deleted.'), backgroundColor: AppTheme.accent),
      );
    }
  }

  Future<void> _updateStatus(QuizProvider provider, String status) async {
    // If opening quiz, verify it has at least 1 question
    if (status == 'open' && provider.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open quiz. Please add at least one question first.'),
          backgroundColor: AppTheme.accent,
        ),
      );
      return;
    }

    await provider.changeQuizStatus(widget.quiz, status);
    
    // Refresh local widget state by popping and letting dashboard reload, or just update state
    setState(() {});
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quiz status updated to $status.'),
          backgroundColor: AppTheme.openColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final format = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Administration'),
        actions: [
          Consumer<QuizProvider>(
            builder: (context, provider, _) {
              // Find the latest instance of this quiz in provider list to show updated status
              final latestQuiz = provider.quizzes.firstWhere(
                (q) => q.id == widget.quiz.id,
                orElse: () => widget.quiz,
              );

              return PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ManageQuizScreen(
                          creatorId: latestQuiz.creatorId,
                          quiz: latestQuiz,
                        ),
                      ),
                    );
                  } else if (val == 'delete') {
                    _deleteQuiz(provider);
                  } else if (val == 'open') {
                    _updateStatus(provider, 'open');
                  } else if (val == 'close') {
                    _updateStatus(provider, 'closed');
                  } else if (val == 'draft') {
                    _updateStatus(provider, 'draft');
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined), SizedBox(width: 8), Text('Edit Quiz')])),
                  if (latestQuiz.isDraft)
                    const PopupMenuItem(value: 'open', child: Row(children: [Icon(Icons.play_arrow_outlined, color: AppTheme.openColor), SizedBox(width: 8), Text('Open Quiz')])),
                  if (latestQuiz.isOpen)
                    const PopupMenuItem(value: 'close', child: Row(children: [Icon(Icons.stop_circle_outlined, color: AppTheme.closedColor), SizedBox(width: 8), Text('Close Quiz')])),
                  if (latestQuiz.isClosed)
                    const PopupMenuItem(value: 'open', child: Row(children: [Icon(Icons.replay_outlined, color: AppTheme.openColor), SizedBox(width: 8), Text('Re-open')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: AppTheme.accent), SizedBox(width: 8), Text('Delete')])),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, provider, _) {
          final latestQuiz = provider.quizzes.firstWhere(
            (q) => q.id == widget.quiz.id,
            orElse: () => widget.quiz,
          );

          // Calculations for stats
          final totalQuestions = provider.questions.length;
          final submissions = provider.quizSubmissions;
          final double avgScore = submissions.isEmpty
              ? 0.0
              : submissions.map((s) => s.score).reduce((a, b) => a + b) / submissions.length;
          final double highest = submissions.isEmpty
              ? 0.0
              : submissions.map((s) => s.score).reduce((a, b) => a > b ? a : b);

          Color statusColor;
          switch (latestQuiz.status) {
            case 'open': statusColor = AppTheme.openColor; break;
            case 'closed': statusColor = AppTheme.closedColor; break;
            default: statusColor = AppTheme.draftColor;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            latestQuiz.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            latestQuiz.status.toUpperCase(),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      latestQuiz.description.isEmpty ? 'No description.' : latestQuiz.description,
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildMetaRow(Icons.timer_outlined, 'Duration: ${latestQuiz.duration} minutes', isDark),
                    const SizedBox(height: 6),
                    _buildMetaRow(Icons.calendar_month_outlined, 'Starts: ${format.format(latestQuiz.startTime)}', isDark),
                    const SizedBox(height: 6),
                    _buildMetaRow(Icons.calendar_month_outlined, 'Ends: ${format.format(latestQuiz.endTime)}', isDark),
                  ],
                ),
              ),

              // Statistics summary row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    _buildDetailStatCard('Questions', totalQuestions.toString(), isDark),
                    const SizedBox(width: 10),
                    _buildDetailStatCard('Submissions', submissions.length.toString(), isDark),
                    const SizedBox(width: 10),
                    _buildDetailStatCard('Avg Score', avgScore.toStringAsFixed(1), isDark),
                    const SizedBox(width: 10),
                    _buildDetailStatCard('Highest', highest.toStringAsFixed(1), isDark),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              
              // Sections Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Student Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ManageQuestionsScreen(quiz: latestQuiz),
                          ),
                        ).then((_) {
                          provider.loadQuestions(latestQuiz.id);
                        });
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: const Text('Manage Questions'),
                    ),
                  ],
                ),
              ),
              
              // Submissions list
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : submissions.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey.withOpacity(0.5)),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No student submissions yet.',
                                    style: TextStyle(color: Colors.grey, fontSize: 15),
                                  ),
                                  if (latestQuiz.isDraft) ...[
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Open the quiz to let students take it!',
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: submissions.length,
                            itemBuilder: (ctx, idx) {
                              final sub = submissions[idx];
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                                ),
                                color: isDark ? AppTheme.darkSurface : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                  child: Row(
                                    children: [
                                      // Score Badge
                                      Container(
                                        height: 48,
                                        width: 48,
                                        decoration: BoxDecoration(
                                          color: (sub.score >= 70.0 ? AppTheme.openColor : AppTheme.accent).withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          sub.score.toStringAsFixed(0),
                                          style: TextStyle(
                                            color: sub.score >= 70.0 ? AppTheme.openColor : AppTheme.accent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sub.studentName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Submitted: ${DateFormat('dd MMM, HH:mm').format(sub.submittedAt)}',
                                              style: TextStyle(
                                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${sub.correctCount} Correct',
                                            style: const TextStyle(color: AppTheme.openColor, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                          Text(
                                            '${sub.incorrectCount} Wrong',
                                            style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailStatCard(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBg : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
