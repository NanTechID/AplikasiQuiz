import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../models/quiz_model.dart';
import '../../widgets/quiz_card.dart';
import '../../services/service_registry.dart';
import '../../utils/theme.dart';
import '../login_screen.dart';
import 'take_quiz_screen.dart';
import 'review_answers_screen.dart';

class DashboardMahasiswa extends StatefulWidget {
  const DashboardMahasiswa({super.key});

  @override
  State<DashboardMahasiswa> createState() => _DashboardMahasiswaState();
}

class _DashboardMahasiswaState extends State<DashboardMahasiswa> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load student's history on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser != null) {
        Provider.of<QuizProvider>(context, listen: false).loadStudentSubmissions(auth.currentUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _onQuizTap(QuizModel quiz, QuizProvider quizProvider, String studentId, String studentName) async {
    // Check if student already completed this quiz
    final existingSubmission = await quizProvider.getCachedOrFetchSubmission(studentId, quiz.id);

    if (!mounted) return;

    if (existingSubmission != null) {
      // Already completed: Show Results
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Quiz Already Taken'),
          content: Text('You have already completed "${quiz.title}" with a score of ${existingSubmission.score}.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Back'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReviewAnswersScreen(quiz: quiz, submission: existingSubmission),
                  ),
                );
              },
              child: const Text('Review Answers'),
            ),
          ],
        ),
      );
      return;
    }

    // Not completed yet: verify if active time is valid
    if (!quiz.isTimeValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This quiz is not available outside its scheduled window.'),
          backgroundColor: AppTheme.accent,
        ),
      );
      return;
    }

    // Show Confirmation Dialog to Start Quiz
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Start Quiz: ${quiz.title}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quiz.description.isEmpty ? 'No instructions provided.' : quiz.description),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text('Time Limit: ${quiz.duration} minutes', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Warning: Once started, the timer cannot be paused. If you exit or close the app, the quiz will auto-submit when the timer expires.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TakeQuizScreen(quiz: quiz),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            child: const Text('Start Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDemo = !ServiceRegistry().isFirebaseMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hi, ${auth.currentUser?.name ?? "Student"} 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isDemo)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'DEMO MODE',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // TabBar
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Available Quizzes'),
                  Tab(text: 'My History / Scores'),
                ],
              ),
              const SizedBox(height: 12),

              // Tabs content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAvailableQuizzes(quizProvider, auth.currentUser?.uid ?? '', auth.currentUser?.name ?? ''),
                    _buildHistoryList(quizProvider, isDark),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvailableQuizzes(QuizProvider provider, String studentId, String studentName) {
    final active = provider.openQuizzes;

    if (active.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text(
              'No active quizzes at the moment.',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: active.length,
      itemBuilder: (context, index) {
        final quiz = active[index];
        return QuizCard(
          quiz: quiz,
          onTap: () => _onQuizTap(quiz, provider, studentId, studentName),
        );
      },
    );
  }

  Widget _buildHistoryList(QuizProvider provider, bool isDark) {
    final history = provider.studentSubmissions;

    if (provider.isLoading && history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 48, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text(
              'You haven\'t completed any quizzes yet.',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final submission = history[index];
        
        // Find corresponding quiz title
        final quiz = provider.quizzes.firstWhere(
          (q) => q.id == submission.quizId,
          orElse: () => QuizModel(
            id: submission.quizId,
            title: 'Quiz Session',
            description: '',
            creatorId: '',
            startTime: DateTime.now(),
            endTime: DateTime.now(),
            duration: 0,
            status: 'closed',
            createdAt: DateTime.now(),
          ),
        );

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
          color: isDark ? AppTheme.darkSurface : Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              height: 44,
              width: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (submission.score >= 70 ? AppTheme.openColor : AppTheme.accent).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Text(
                submission.score.toStringAsFixed(0),
                style: TextStyle(
                  color: submission.score >= 70 ? AppTheme.openColor : AppTheme.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            title: Text(
              quiz.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Correct: ${submission.correctCount} | Wrong: ${submission.incorrectCount}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReviewAnswersScreen(quiz: quiz, submission: submission),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
