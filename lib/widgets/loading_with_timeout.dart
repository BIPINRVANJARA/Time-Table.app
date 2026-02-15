
import 'dart:async';
import 'package:flutter/material.dart';

class _LoadingWithTimeout extends StatefulWidget {
  const _LoadingWithTimeout();

  @override
  State<_LoadingWithTimeout> createState() => _LoadingWithTimeoutState();
}

class _LoadingWithTimeoutState extends State<_LoadingWithTimeout> {
  bool _showTimeout = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _showTimeout = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showTimeout) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.signal_wifi_off, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Loading is taking longer than expected.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Please check your internet connection.\nIf this persists, the Database Rules might need deployment.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Trigger a re-build of parent to retry? 
                // Currently just resets the timer visually
                setState(() => _showTimeout = false);
                _timer = Timer(const Duration(seconds: 10), () {
                  if (mounted) setState(() => _showTimeout = true);
                });
              },
              child: const Text('Wait Longer'),
            ),
          ],
        ),
      );
    }
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading timetable...'),
        ],
      ),
    );
  }
}
