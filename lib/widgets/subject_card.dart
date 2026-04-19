import 'package:flutter/material.dart';
import '../models/subject.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SubjectCard({
    super.key,
    required this.subject,
    this.onTap,
    this.onDelete,
  });

  // Get deterministic color based on subject name
  Color _getSubjectColor() {
    if (subject.colorValue != null) {
      return Color(subject.colorValue!);
    }
    
    // List of nice colors for subjects
    final colors = [
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
    
    final hash = subject.subjectName.codeUnits.fold(0, (sum, char) => sum + char);
    return colors[hash % colors.length];
  }

  // Get gradient colors based on subject color
  List<Color> _getGradientColors() {
    final baseColor = _getSubjectColor();
    return [
      baseColor,
      baseColor.withOpacity(0.7),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();
    final baseColor = _getSubjectColor();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Time column on the left
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTime(subject.startHour, subject.startMinute),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(subject.endHour, subject.endMinute),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    
                    // Vertical divider
                    Container(
                      width: 2,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Subject name and details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 24.0), // Space for badge
                            child: Text(
                              subject.subjectName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Room Number
                              if (subject.roomNumber != null && subject.roomNumber!.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on, size: 10, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        subject.roomNumber!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              
                              // Batch
                              if (subject.batch != null && subject.batch!.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.group, size: 10, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        subject.batch!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Semester Badge (Top Right)
              if (subject.semester != null && subject.semester!.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _formatSemester(subject.semester!),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: baseColor, // Use subject color for text
                      ),
                    ),
                  ),
                ),
                
              // Notification icon (Bottom Right now, to avoid clash)
              if (subject.reminderEnabled)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
                
              // Delete button (Top Right, shifts left if badge exists)
              if (onDelete != null)
                Positioned(
                  top: 0,
                  right: (subject.semester != null && subject.semester!.isNotEmpty) ? 80 : 0,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.white,
                    onPressed: onDelete,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSemester(String rawSemester) {
    // rawSemester might be "Semester6" or "6" or "Sem6"
    // We want to display "Sem 6"
    
    String number = rawSemester.replaceAll(RegExp(r'[^0-9]'), '');
    if (number.isNotEmpty) {
      return 'Sem $number';
    }
    return rawSemester; // Fallback
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}
