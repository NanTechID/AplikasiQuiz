import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/question_model.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/theme.dart';

class AddQuestionScreen extends StatefulWidget {
  final String quizId;
  final QuestionModel? question; // null if adding new, populated if editing

  const AddQuestionScreen({
    super.key,
    required this.quizId,
    this.question,
  });

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  int _correctOptionIndex = 0;
  bool _isLoading = false;

  bool get isEditing => widget.question != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final q = widget.question!;
      _questionController.text = q.text;
      _correctOptionIndex = q.correctOptionIndex;
      for (int i = 0; i < 4; i++) {
        if (i < q.options.length) {
          _optionControllers[i].text = q.options[i];
        }
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    final List<String> options = _optionControllers.map((c) => c.text.trim()).toList();

    try {
      if (isEditing) {
        final updatedQuestion = widget.question!.copyWith(
          text: _questionController.text.trim(),
          options: options,
          correctOptionIndex: _correctOptionIndex,
        );
        await quizProvider.updateQuestion(updatedQuestion);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question updated successfully!'), backgroundColor: AppTheme.openColor),
        );
      } else {
        await quizProvider.addQuestion(
          quizId: widget.quizId,
          text: _questionController.text.trim(),
          options: options,
          correctOptionIndex: _correctOptionIndex,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question added successfully!'), backgroundColor: AppTheme.openColor),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Question' : 'Add Question'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _questionController,
                labelText: 'Question Text',
                hintText: 'Enter the quiz question...',
                prefixIcon: Icons.help_outline_rounded,
                maxLines: 3,
                validator: (val) => val == null || val.isEmpty ? 'Question text is required' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Options & Correct Answer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Fill in the 4 options and select the correct answer by checking the radio button next to it.',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              
              // 4 Options form cards
              Column(
                children: List.generate(4, (index) {
                  final optionLabel = String.fromCharCode(65 + index); // A, B, C, D
                  final isSelected = _correctOptionIndex == index;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.openColor.withOpacity(0.04) 
                          : (isDark ? AppTheme.darkSurface : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                            ? AppTheme.openColor 
                            : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: isSelected ? AppTheme.openColor : Colors.grey[400],
                          child: Text(
                            optionLabel,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _optionControllers[index],
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Enter Option $optionLabel...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Option $optionLabel is required' : null,
                          ),
                        ),
                        Radio<int>(
                          value: index,
                          groupValue: _correctOptionIndex,
                          activeColor: AppTheme.openColor,
                          onChanged: (val) {
                            if (val != null) setState(() => _correctOptionIndex = val);
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 32),
              CustomButton(
                text: isEditing ? 'Save Question' : 'Add to Quiz',
                isLoading: _isLoading,
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
