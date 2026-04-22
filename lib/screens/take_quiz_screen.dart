import 'package:flutter/material.dart';

class TakeQuizScreen extends StatefulWidget {
  final String targetName;
  final String? targetAvatarUrl;
  final List<dynamic> quizData;

  const TakeQuizScreen({
    super.key,
    required this.targetName,
    this.targetAvatarUrl,
    required this.quizData,
  });

  @override
  State<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen> {
  // Map to store which option index the user selected for each question
  final Map<int, int> _selectedAnswers = {};
  bool _isScoring = false;

  void _submitQuiz() {
    // Ensure they answered everything
    if (_selectedAnswers.length < widget.quizData.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Answer all questions to prove your vibe!"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isScoring = true);

    // Calculate their score
    int correctAnswers = 0;
    for (int i = 0; i < widget.quizData.length; i++) {
      final question = widget.quizData[i];
      if (_selectedAnswers[i] == question['preferred_option_index']) {
        correctAnswers++;
      }
    }

    // Small delay for dramatic effect
    Future.delayed(const Duration(milliseconds: 800), () {
      _showResultsDialog(correctAnswers, widget.quizData.length);
    });
  }

  void _showResultsDialog(int score, int total) {
    final double percentage = score / total;
    String title = "Vibe Check Failed 🚩";
    String subtitle = "You only got $score out of $total right. Yikes.";
    Color resultColor = Colors.redAccent;
    bool passed = false;

    // They pass if they get at least 50% right (you can adjust this strictness!)
    if (percentage >= 0.5) {
      title = "Vibe Match! ✨";
      subtitle = "You scored $score out of $total! You are officially compatible.";
      resultColor = Colors.green;
      passed = true;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(color: resultColor, fontWeight: FontWeight.bold, fontSize: 24), textAlign: TextAlign.center),
        content: Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: resultColor, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, passed); // Close screen and return true/false
            },
            child: Text(passed ? "Send Match Request" : "Back to Swiping", style: const TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text("Quiz: ${widget.targetName}", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.indigo),
      ),
      body: _isScoring
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.pinkAccent),
            SizedBox(height: 20),
            Text("Calculating Vibe Compatibility...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: widget.quizData.length + 1,
        itemBuilder: (context, index) {
          // The last item is the submit button
          if (index == widget.quizData.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Submit & See Compatibility", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }

          final questionData = widget.quizData[index];
          final options = questionData['options'] as List<dynamic>;

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Q${index + 1}: ${questionData['question']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 16),
                ...List.generate(options.length, (optIndex) {
                  final isSelected = _selectedAnswers[index] == optIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAnswers[index] = optIndex),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.pinkAccent.withOpacity(0.1) : Colors.grey[50],
                        border: Border.all(color: isSelected ? Colors.pinkAccent : Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? Colors.pinkAccent : Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(child: Text(options[optIndex], style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}