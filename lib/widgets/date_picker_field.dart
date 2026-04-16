import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatefulWidget {
  const DatePickerField({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
    this.hint = 'Select date',
  });
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTime)? onDateSelected;
  final String hint;

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime(2026, 3, 4);
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(2020),
      lastDate: widget.lastDate ?? DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5B6AF0),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5B6AF0),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onDateSelected?.call(_selectedDate!);
    }
  }

  String get _formattedDate {
    if (_selectedDate == null) return widget.hint;
    return DateFormat('MMM dd ,yyyy').format(_selectedDate!);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        height: 46.h,
        decoration: BoxDecoration(
          color: Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: Row(
          children: [
            Container(
              width: 30.w,
              height: 30.h,
              decoration: BoxDecoration(
                // color: const Color(0xFFF0F1FF),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                _formattedDate,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: _selectedDate != null
                      ? const Color(0xFF1A1D2E)
                      : Colors.black38,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_outlined,
              color: Color(0xFF5B6AF0),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}
