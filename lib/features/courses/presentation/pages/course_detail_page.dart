import 'package:flutter/material.dart';

/// Page placeholder — sera développée en issue #20.
class CourseDetailPage extends StatelessWidget {
  final String courseId;
  const CourseDetailPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cours')),
      body: Center(child: Text('Course: $courseId\n(à développer)', textAlign: TextAlign.center)),
    );
  }
}
