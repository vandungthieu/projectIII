import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_project/utils/app_themes.dart';

class DateFilterBar extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onClear;

  const DateFilterBar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickDate(context),
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(
                selectedDate == null
                    ? 'Tất cả ngày'
                    : DateFormat('dd/MM/yyyy').format(selectedDate!),
              ),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                foregroundColor: selectedDate == null
                    ? (isDark ? Colors.white70 : AppColors.ink)
                    : AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          if (selectedDate != null) ...[
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Xóa lọc ngày',
              onPressed: onClear,
              icon: const Icon(Icons.close),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Chọn ngày cần xem',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (picked != null) onDateSelected(picked);
  }
}
