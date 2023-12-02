import 'package:flutter/foundation.dart';
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

Widget filterBar({
  required ValueNotifier<DateTime?> startDateNotifier,
  required ValueNotifier<DateTime?> endDateNotifier,
  required Function onChanged,
}) {
  /// 選擇日期範圍
  return Container(
    margin: const EdgeInsets.all(10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
            onPressed: () {
              DateTime now = DateTime.now();
              startDateNotifier.value = DateTime(now.year, now.month, now.day, 0, 0, 0);
              endDateNotifier.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
              onChanged();
            },
            child: const Text('今天')),
        ElevatedButton(
            onPressed: () {
              DateTime now = DateTime.now();
              startDateNotifier.value = DateTime(now.year, now.month, 1);
              endDateNotifier.value = DateTime(now.year, now.month + 1, 0);
              onChanged();
            },
            child: const Text('這個月')),
        ElevatedButton(
            onPressed: () {
              DateTime now = DateTime.now();
              startDateNotifier.value = DateTime(now.year, 1, 1);
              endDateNotifier.value = DateTime(now.year, 12, 31);
              onChanged();
            },
            child: const Text('今年')),
        ValueListenableBuilder(
            valueListenable: startDateNotifier,
            builder: (context, startDate, child) {
              return DatePickerfield(
                selectedDate: startDate,
                onChanged: (date) {
                  startDateNotifier.value = date;
                },
              );
            }),
        const SizedBox(
          width: 10,
          child: Text('~'),
        ),
        ValueListenableBuilder(
            valueListenable: endDateNotifier,
            builder: (context, endDate, child) {
              return DatePickerfield(
                selectedDate: endDate,
                onChanged: (date) {
                  endDateNotifier.value = date;
                },
              );
            }),
        IconButton(
          onPressed: () {
            onChanged();
          },
          icon: const Icon(Icons.search),
        ),
      ],
    ),
  );
}
