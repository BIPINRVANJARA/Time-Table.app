import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../widgets/color_picker_dialog.dart';

class AddEditSubjectScreen extends StatefulWidget {
  final Subject? subject;
  final int? dayOfWeek;

  const AddEditSubjectScreen({
    super.key,
    this.subject,
    this.dayOfWeek,
  });

  @override
  State<AddEditSubjectScreen> createState() => _AddEditSubjectScreenState();
}

class _AddEditSubjectScreenState extends State<AddEditSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late int _selectedDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Color _selectedColor;
  late bool _reminderEnabled;
  late int _reminderMinutes;

  @override
  void initState() {
    super.initState();

    if (widget.subject != null) {
      // Editing existing subject
      _nameController.text = widget.subject!.subjectName;
      _selectedDay = widget.subject!.dayOfWeek;
      _startTime = TimeOfDay(
        hour: widget.subject!.startHour,
        minute: widget.subject!.startMinute,
      );
      _endTime = TimeOfDay(
        hour: widget.subject!.endHour,
        minute: widget.subject!.endMinute,
      );
      _selectedColor = Color(widget.subject!.colorValue);
      _reminderEnabled = widget.subject!.reminderEnabled;
      _reminderMinutes = widget.subject!.reminderMinutesBefore;
    } else {
      // Adding new subject
      _selectedDay = widget.dayOfWeek ?? DateTime.now().weekday;
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
      _selectedColor = AppColors.blue;
      _reminderEnabled = true;
      _reminderMinutes = AppConstants.defaultReminderMinutes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subject != null ? 'Edit Subject' : 'Add Subject',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Subject Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                hintText: 'e.g., Mathematics',
                prefixIcon: Icon(Icons.book),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a subject name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Day Selection
            DropdownButtonFormField<int>(
              value: _selectedDay,
              decoration: const InputDecoration(
                labelText: 'Day',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              items: List.generate(6, (index) {
                final day = index + 1; // 1-6 for Mon-Sat
                return DropdownMenuItem(
                  value: day,
                  child: Text(AppConstants.daysOfWeek[day]),
                );
              }),
              onChanged: (value) {
                setState(() {
                  _selectedDay = value!;
                });
              },
            ),
            const SizedBox(height: 24),

            // Start Time
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Start Time'),
              trailing: TextButton(
                onPressed: () => _selectTime(true),
                child: Text(
                  _startTime.format(context),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const Divider(),

            // End Time
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('End Time'),
              trailing: TextButton(
                onPressed: () => _selectTime(false),
                child: Text(
                  _endTime.format(context),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const Divider(),

            const SizedBox(height: 24),

            // Color Selection
            const Text(
              'Subject Color',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppColors.subjectColors.map((color) {
                final isSelected = color.value == _selectedColor.value;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Reminder Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Reminder'),
              subtitle: const Text('Get notified before class starts'),
              value: _reminderEnabled,
              onChanged: (value) {
                setState(() {
                  _reminderEnabled = value;
                });
              },
            ),

            // Reminder Time
            if (_reminderEnabled) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _reminderMinutes,
                decoration: const InputDecoration(
                  labelText: 'Remind me before',
                  prefixIcon: Icon(Icons.notifications),
                ),
                items: AppConstants.reminderOptions.map((minutes) {
                  return DropdownMenuItem(
                    value: minutes,
                    child: Text('$minutes minutes'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _reminderMinutes = value!;
                  });
                },
              ),
            ],

            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _saveSubject,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.subject != null ? 'Update Subject' : 'Add Subject',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(bool isStartTime) async {
    final initialTime = isStartTime ? _startTime : _endTime;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = pickedTime;
          // Ensure end time is after start time
          if (_endTime.hour < _startTime.hour ||
              (_endTime.hour == _startTime.hour &&
                  _endTime.minute <= _startTime.minute)) {
            _endTime = TimeOfDay(
              hour: _startTime.hour + 1,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  Future<void> _saveSubject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate time
    if (_endTime.hour < _startTime.hour ||
        (_endTime.hour == _startTime.hour &&
            _endTime.minute <= _startTime.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final subject = Subject(
      id: widget.subject?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      subjectName: _nameController.text.trim(),
      dayOfWeek: _selectedDay,
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      colorValue: _selectedColor.value,
      reminderEnabled: _reminderEnabled,
      reminderMinutesBefore: _reminderMinutes,
    );

    if (widget.subject != null) {
      await DatabaseService.updateSubject(subject);
    } else {
      await DatabaseService.addSubject(subject);
    }

    // Schedule notification
    if (_reminderEnabled) {
      await NotificationService().scheduleSubjectNotification(subject);
    } else {
      await NotificationService().cancelSubjectNotification(subject.id);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
