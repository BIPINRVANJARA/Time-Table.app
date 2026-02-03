import 'package:flutter/material.dart';
import '../utils/theme.dart';

class ColorPickerDialog extends StatelessWidget {
  final Color selectedColor;

  const ColorPickerDialog({
    super.key,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Color'),
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: AppColors.subjectColors.map((color) {
          final isSelected = color.value == selectedColor.value;
          return GestureDetector(
            onTap: () {
              Navigator.of(context).pop(color);
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
    );
  }
}
