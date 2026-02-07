import 'package:flutter/material.dart';
import '../models/subject.dart';

class AddEditSubjectScreen extends StatelessWidget {
  final int? dayOfWeek;
  final Subject? subject;

  const AddEditSubjectScreen({super.key, this.dayOfWeek, this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Subject')),
      body: const Center(
        child: Text('Admin Only - Coming Soon'),
      ),
    );
  }
}
