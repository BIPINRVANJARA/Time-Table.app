import 'package:flutter/material.dart';
import '../../models/subject.dart';
import '../../services/database_service.dart';

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
  late TextEditingController _facultyController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _dayOfWeek;
  String _type = 'lecture';
  String? _selectedBatch;
  int? _selectedColorValue;
  bool _isLoading = false;

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
    _facultyController = TextEditingController(text: widget.subject?.facultyName ?? '');
    _dayOfWeek = widget.subject?.dayOfWeek ?? widget.dayOfWeek ?? 1;
    _type = widget.subject?.type ?? 'lecture';
    _selectedBatch = widget.subject?.batch;
    _selectedColorValue = widget.subject?.colorValue;
    
    _startTime = widget.subject != null 
        ? TimeOfDay(hour: widget.subject!.startHour, minute: widget.subject!.startMinute)
        : const TimeOfDay(hour: 9, minute: 0);
        
    _endTime = widget.subject != null 
        ? TimeOfDay(hour: widget.subject!.endHour, minute: widget.subject!.endMinute)
        : const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _facultyController.dispose();
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
      facultyName: _facultyController.text.trim(),
      type: _type,
      dayOfWeek: _dayOfWeek,
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      colorValue: _selectedColorValue,
      batch: _type == 'lab' ? _selectedBatch : null, // Only save batch for labs
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
      body: SingleChildScrollView(
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
              TextFormField(
                controller: _facultyController,
                decoration: const InputDecoration(labelText: 'Faculty Name (Optional)', border: OutlineInputBorder()),
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
    );
  }
}
