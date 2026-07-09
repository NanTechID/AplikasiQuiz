import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../models/quiz_model.dart';
import '../../widgets/quiz_card.dart';
import '../../services/service_registry.dart';
import '../../utils/theme.dart';
import '../login_screen.dart';
import 'manage_quiz_screen.dart';
import 'quiz_detail_dosen.dart';

class DashboardDosen extends StatefulWidget {
  const DashboardDosen({super.key});

  @override
  State<DashboardDosen> createState() => _DashboardDosenState();
}

class _DashboardDosenState extends State<DashboardDosen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDemo = !ServiceRegistry().isFirebaseMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturer Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ManageQuizScreen(creatorId: auth.currentUser?.uid ?? ''),
            ),
          );
        },
        label: const Text('Create Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Stats Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Welcome, ${auth.currentUser?.name ?? "Lecturer"} 👋',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Demo mode chip
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
                    const SizedBox(height: 16),
                    // Visual Stats
                    _buildStatsRow(quizProvider),
                  ],
                ),
              ),

              // TabBar for status filtering
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Drafts'),
                  Tab(text: 'Open Sessions'),
                  Tab(text: 'Closed'),
                ],
              ),
              const SizedBox(height: 12),

              // TabBar View of Quiz Lists
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQuizList(quizProvider.draftQuizzes, 'No draft quizzes found.'),
                    _buildQuizList(quizProvider.openQuizzes, 'No open quiz sessions active.'),
                    _buildQuizList(quizProvider.closedQuizzes, 'No closed quizzes yet.'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(QuizProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = provider.quizzes.length;
    final active = provider.openQuizzes.length;
    final closed = provider.closedQuizzes.length;

    return Row(
      children: [
        _buildStatCard('Total Quizzes', total.toString(), Icons.folder_open_outlined, isDark),
        const SizedBox(width: 12),
        _buildStatCard('Active', active.toString(), Icons.play_circle_outline, isDark),
        const SizedBox(width: 12),
        _buildStatCard('Closed', closed.toString(), Icons.check_circle_outline, isDark),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                Icon(icon, color: AppTheme.primary, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizList(List<QuizModel> quizzes, String emptyMsg) {
    if (quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes_rounded, size: 48, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              emptyMsg,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final quiz = quizzes[index];
        return QuizCard(
          quiz: quiz,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => QuizDetailDosen(quiz: quiz)),
            );
          },
        );
      },
    );
  }
}
