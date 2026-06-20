import 'package:flutter/material.dart';

/// Page placeholder — sera développée en issue #21.
class LessonPlayerPage extends StatelessWidget {
  final String lessonId;
  final String courseId;
  const LessonPlayerPage({super.key, required this.lessonId, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leçon')),
      body: Center(child: Text('Lesson: $lessonId\n(à développer)', textAlign: TextAlign.center)),
    );
  }
}
