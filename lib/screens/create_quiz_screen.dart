import 'package:flutter/material.dart';

// A simple model to hold our dynamic question data
class CustomQuestion {
  TextEditingController questionController = TextEditingController();
  List<TextEditingController> optionControllers = [TextEditingController(), TextEditingController()];
  int? preferredOptionIndex;

  Map<String, dynamic> toJson() {
    return {
      'question': questionController.text.trim(),
      'options': optionControllers.map((c) => c.text.trim()).where((opt) => opt.isNotEmpty).toList(),
      'preferred_option_index': preferredOptionIndex,
    };
  }
}

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final List<CustomQuestion> _questions = [CustomQuestion()];

  void _addQuestion() {
    if (_questions.length < 3) {
      setState(() => _questions.add(CustomQuestion()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum 3 questions allowed!"), backgroundColor: Colors.orange),
      );
    }
  }

  void _saveQuiz() {
    for (var q in _questions) {
      if (q.questionController.text.isEmpty || q.preferredOptionIndex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all questions and select a preferred answer."), backgroundColor: Colors.redAccent),
        );
        return;
      }
    }
    final quizData = _questions.map((q) => q.toJson()).toList();
    Navigator.pop(context, quizData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Build Your Quiz", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(onPressed: _saveQuiz, child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _questions.length + 1,
        itemBuilder: (context, index) {
          if (index == _questions.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 40.0),
              child: OutlinedButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add),
                label: const Text("Add Another Question"),
              ),
            );
          }

          final q = _questions[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Question ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 12),
                TextField(controller: q.questionController, decoration: const InputDecoration(hintText: "e.g., How often do you clean?", border: OutlineInputBorder())),
                const SizedBox(height: 16),
                const Text("Options (Tap the checkmark for your preferred answer)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                ...List.generate(q.optionControllers.length, (optIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(child: TextField(controller: q.optionControllers[optIndex], decoration: InputDecoration(hintText: "Option ${optIndex + 1}"))),
                        IconButton(
                          icon: Icon(q.preferredOptionIndex == optIndex ? Icons.check_circle : Icons.circle_outlined, color: q.preferredOptionIndex == optIndex ? Colors.green : Colors.grey),
                          onPressed: () => setState(() => q.preferredOptionIndex = optIndex),
                        )
                      ],
                    ),
                  );
                }),
                if (q.optionControllers.length < 4)
                  TextButton.icon(onPressed: () => setState(() => q.optionControllers.add(TextEditingController())), icon: const Icon(Icons.add, size: 16), label: const Text("Add Option"))
              ],
            ),
          );
        },
      ),
    );
  }
}