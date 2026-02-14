import 'package:flutter/material.dart';
import '../../models/subject.dart';
import '../../models/faculty.dart';
import '../../services/database_service.dart';
import '../../services/faculty_service.dart';

class AdminSubjectFormScreen extends StatefulWidget {
  final String branch;
  final String semester;
  final String division;
  final int? dayOfWeek;
  final Subject? subject;

  const AdminSubjectFormScreen({
    super.key,
    required this.branch,
    required this.semester,
    required this.division,
    this.dayOfWeek,
    this.subject,
  });

  @override
  State<AdminSubjectFormScreen> createState() => _AdminSubjectFormScreenState();
}

class _AdminSubjectFormScreenState extends State<AdminSubjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _roomNumberController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _dayOfWeek;
  String _type = 'lecture';
  String? _selectedBatch;
  String? _selectedFacultyId;
  String _selectedFacultyName = '';
  int? _selectedColorValue;
  bool _isLoading = false;
  bool _reminderEnabled = false;
  int _reminderMinutesBefore = 5;
  List<Faculty> _facultyList = [];
  bool _isLoadingFaculty = true;

  final List<Color> _presetColors = [
    const Color(0xFF5D9CEC), // Blue
    const Color(0xFF4FC1E9), // Light Blue
    const Color(0xFF48CFAD), // Mint
    const Color(0xFFA0D468), // Green
    const Color(0xFFFFCE54), // Yellow
    const Color(0xFFFC6E51), // Orange
    const Color(0xFFED5565), // Red
    const Color(0xFFAC92EC), // Purple
    const Color(0xFFEC87C0), // Pink
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.subjectName ?? '');
    _roomNumberController = TextEditingController(text: widget.subject?.roomNumber ?? '');
    _dayOfWeek = widget.subject?.dayOfWeek ?? widget.dayOfWeek ?? 1;
    _type = widget.subject?.type ?? 'lecture';
    _selectedBatch = widget.subject?.batch;
    _selectedFacultyId = widget.subject?.facultyId;
    _selectedFacultyName = widget.subject?.facultyName ?? '';
    _selectedColorValue = widget.subject?.colorValue;
    _reminderEnabled = widget.subject?.reminderEnabled ?? false;
    _reminderMinutesBefore = widget.subject?.reminderMinutesBefore ?? 5;
    
    _startTime = widget.subject != null 
        ? TimeOfDay(hour: widget.subject!.startHour, minute: widget.subject!.startMinute)
        : const TimeOfDay(hour: 9, minute: 0);
        
    _endTime = widget.subject != null 
        ? TimeOfDay(hour: widget.subject!.endHour, minute: widget.subject!.endMinute)
        : const TimeOfDay(hour: 10, minute: 0);
        
    _fetchFaculty();
  }

  Future<void> _fetchFaculty() async {
    try {
      final faculty = await FacultyService.getAllFaculty();
      if (mounted) {
        setState(() {
          _facultyList = faculty;
          _isLoadingFaculty = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFaculty = false);
        debugPrint('Error fetching faculty: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          // Auto-adjust end time to +1 hour if it's before or equal to start
          if (_endTime.hour < picked.hour || (_endTime.hour == picked.hour && _endTime.minute <= picked.minute)) {
            _endTime = TimeOfDay(hour: (picked.hour + 1) % 24, minute: picked.minute);
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final subject = Subject(
      id: widget.subject?.id ?? '',
      subjectName: _nameController.text.trim(),
      facultyName: _selectedFacultyName,
      type: _type,
      dayOfWeek: _dayOfWeek,
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      colorValue: _selectedColorValue,
      batch: _type == 'lab' ? _selectedBatch : null, // Only save batch for labs
      reminderEnabled: _reminderEnabled,
      reminderMinutesBefore: _reminderMinutesBefore,
      facultyId: _selectedFacultyId,
      roomNumber: _roomNumberController.text.trim(),
    );

    try {
      if (widget.subject == null) {
        await DatabaseService.addSubject(widget.branch, widget.semester, widget.division, subject);
      } else {
        await DatabaseService.updateSubject(widget.branch, widget.semester, widget.division, subject);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject == null ? 'Add Subject' : 'Edit Subject'),
        actions: [
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Colors.white)))
          else
            IconButton(onPressed: _save, icon: const Icon(Icons.check_rounded)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Subject Name', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  _isLoadingFaculty
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<String>(
                          value: _selectedFacultyId,
                          decoration: const InputDecoration(
                            labelText: 'Faculty (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('No Faculty Assigned'),
                            ),
                            ..._facultyList.map((faculty) {
                              return DropdownMenuItem<String>(
                                value: faculty.facultyId,
                                child: Text(faculty.facultyName),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedFacultyId = value;
                              if (value != null) {
                                final faculty = _facultyList.firstWhere(
                                  (f) => f.facultyId == value,
                                  orElse: () => Faculty(
                                    id: '',
                                    facultyId: '',
                                    facultyName: '',
                                    passwordHash: '',
                                    createdAt: DateTime.now(),
                                  ),
                                );
                                _selectedFacultyName = faculty.facultyName;
                              } else {
                                _selectedFacultyName = '';
                              }
                            });
                          },
                        ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _roomNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Room Number (Optional)',
                      hintText: 'e.g., 201, Lab 3',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.room),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'lecture', child: Text('Lecture')),
                      DropdownMenuItem(value: 'lab', child: Text('Practical / Lab')),
                    ],
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                  
                  if (_type == 'lab') ...[
                    const SizedBox(height: 16),
                    const Text('Select Batch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, 
                      children: ['A1', 'A2', 'A3', 'B1', 'B2', 'B3'].map((batch) {
                        final isSelected = _selectedBatch == batch;
                        return ChoiceChip(
                          label: Text(batch),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedBatch = selected ? batch : null;
                            });
                          },
                          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  const Text('Pick Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Option for "Default/Deterministic" color
                      GestureDetector(
                        onTap: () => setState(() => _selectedColorValue = null),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            border: _selectedColorValue == null
                                ? Border.all(color: Colors.black, width: 2)
                                : null,
                          ),
                          child: const Icon(Icons.auto_awesome, size: 20, color: Colors.grey),
                        ),
                      ),
                      ..._presetColors.map((color) {
                        final isSelected = _selectedColorValue == color.value;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColorValue = color.value),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.black, width: 2)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Notification Reminder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Enable Reminder'),
                    subtitle: Text(_reminderEnabled 
                        ? 'Notify $_reminderMinutesBefore minutes before class'
                        : 'No notification for this subject'),
                    value: _reminderEnabled,
                    onChanged: (value) {
                      setState(() => _reminderEnabled = value);
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  if (_reminderEnabled) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _reminderMinutesBefore,
                      decoration: const InputDecoration(
                        labelText: 'Remind me before',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.alarm),
                      ),
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                        DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                        DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                        DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                        DropdownMenuItem(value: 60, child: Text('1 hour before')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _reminderMinutesBefore = value);
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                  const Text('Time Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectTime(true),
                          icon: const Icon(Icons.access_time),
                          label: Text('Starts: ${_startTime.format(context)}'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectTime(false),
                          icon: const Icon(Icons.access_time),
                          label: Text('Ends: ${_endTime.format(context)}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
