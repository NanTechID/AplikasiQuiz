import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/quiz_model.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/theme.dart';

class ManageQuizScreen extends StatefulWidget {
  final String creatorId;
  final QuizModel? quiz; // null if creating, populated if editing

  const ManageQuizScreen({
    super.key,
    required this.creatorId,
    this.quiz,
  });

  @override
  State<ManageQuizScreen> createState() => _ManageQuizScreenState();
}

class _ManageQuizScreenState extends State<ManageQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _durationController = TextEditingController();

  DateTime _startTime = DateTime.now().add(const Duration(minutes: 5));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 2));
  bool _isLoading = false;

  bool get isEditing => widget.quiz != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final q = widget.quiz!;
      _titleController.text = q.title;
      _descController.text = q.description;
      _durationController.text = q.duration.toString();
      _startTime = q.startTime;
      _endTime = q.endTime;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final DateTime initialDate = isStart ? _startTime : _endTime;
    
    // Pick Date
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    // Pick Time
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (time == null) return;

    setState(() {
      final finalDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      if (isStart) {
        _startTime = finalDateTime;
        // Keep end time at least 30 minutes after start time
        if (_endTime.isBefore(_startTime)) {
          _endTime = _startTime.add(const Duration(minutes: 30));
        }
      } else {
        _endTime = finalDateTime;
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_endTime.isBefore(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz end time must be after the start time.'),
          backgroundColor: AppTheme.accent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    try {
      if (isEditing) {
        final updatedQuiz = widget.quiz!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          duration: int.parse(_durationController.text),
          startTime: _startTime,
          endTime: _endTime,
        );
        await quizProvider.updateQuiz(updatedQuiz);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz updated successfully!'), backgroundColor: AppTheme.openColor),
        );
      } else {
        await quizProvider.createQuiz(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          creatorId: widget.creatorId,
          duration: int.parse(_durationController.text),
          startTime: _startTime,
          endTime: _endTime,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz created as Draft!'), backgroundColor: AppTheme.openColor),
        );
      }
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.accent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Quiz Info' : 'Create New Quiz'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _titleController,
                labelText: 'Quiz Title',
                hintText: 'e.g., Aljabar Linear UTS',
                prefixIcon: Icons.title_rounded,
                validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _descController,
                labelText: 'Description',
                hintText: 'Provide quiz instructions or topics covered...',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _durationController,
                labelText: 'Duration (Minutes)',
                hintText: 'e.g., 60',
                prefixIcon: Icons.timer_outlined,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Duration is required';
                  if (int.tryParse(val) == null || int.parse(val) <= 0) {
                    return 'Please enter a valid duration';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Timeline selection (Start and End)
              const Text(
                'Schedule Parameters',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              
              // Start Date Picker Card
              _buildPickerTile(
                title: 'Start Scheduling Time',
                value: dateFormat.format(_startTime),
                icon: Icons.calendar_today_rounded,
                isDark: isDark,
                onTap: () => _pickDateTime(isStart: true),
              ),
              const SizedBox(height: 12),

              // End Date Picker Card
              _buildPickerTile(
                title: 'End Scheduling Time',
                value: dateFormat.format(_endTime),
                icon: Icons.calendar_today_rounded,
                isDark: isDark,
                onTap: () => _pickDateTime(isStart: false),
              ),

              const SizedBox(height: 40),
              CustomButton(
                text: isEditing ? 'Save Changes' : 'Create Quiz (Save Draft)',
                isLoading: _isLoading,
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
