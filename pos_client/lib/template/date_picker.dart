import 'package:flutter/material.dart';

class DatePickerfield extends StatefulWidget {
  final Function(DateTime? date)? onChanged;
  final DateTime? selectedDate;
  const DatePickerfield({super.key, this.selectedDate, this.onChanged});
  @override
  State<DatePickerfield> createState() => _DatePickerfieldState();
}

class _DatePickerfieldState extends State<DatePickerfield> {
  DateTime? _selectedDate;
  Future<void> _selectDate() async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (widget.onChanged != null) {
      widget.onChanged!(selected);
    }
    if (selected != null && selected != _selectedDate) {
      setState(() {
        _selectedDate = selected;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

  @override
  void didUpdateWidget(covariant DatePickerfield oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _selectedDate = widget.selectedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.calendar_today),
            Text(
              _selectedDate == null ? 'Select a date' : '${_selectedDate!.toLocal()}'.split(' ')[0],
            ),
          ],
        ),
      ),
    );
  }
}
