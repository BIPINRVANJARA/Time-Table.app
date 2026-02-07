import 'package:flutter/material.dart';

class TimeDebugScreen extends StatelessWidget {
  const TimeDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Time Debug')),
      body: const Center(
        child: Text('Debug features temporarily disabled'),
      ),
    );
  }
}
