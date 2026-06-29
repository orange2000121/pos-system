import 'package:flutter/material.dart';

class DatePickerField extends StatefulWidget {
  final Function(DateTime? date)? onChanged;
  final DateTime? initialDate;

  ///顯示挑選日期的欄位
  const DatePickerField({super.key, this.initialDate, this.onChanged});
  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  DateTime? _selectedDate;
  Future<void> _selectDate() async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
    _selectedDate = widget.initialDate;
  }

  @override
  void didUpdateWidget(covariant DatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      _selectedDate = widget.initialDate;
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
              _selectedDate == null
                  ? 'Select a date'
                  : '${_selectedDate!.toLocal()}'.split(' ')[0],
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
  bool showMonthSelector = false,
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
              startDateNotifier.value =
                  DateTime(now.year, now.month, now.day, 0, 0, 0);
              endDateNotifier.value =
                  DateTime(now.year, now.month, now.day, 23, 59, 59);
              onChanged();
            },
            child: const Text('今天')),
        ElevatedButton(
            onPressed: () {
              DateTime now = DateTime.now();
              startDateNotifier.value = DateTime(now.year, now.month, 1);
              endDateNotifier.value =
                  DateTime(now.year, now.month + 1, 0, 23, 59, 59);
              onChanged();
            },
            child: const Text('這個月')),
        ElevatedButton(
            onPressed: () {
              DateTime now = DateTime.now();
              startDateNotifier.value = DateTime(now.year, 1, 1);
              endDateNotifier.value = DateTime(now.year, 12, 31, 23, 59, 59);
              onChanged();
            },
            child: const Text('今年')),
        if (showMonthSelector)
          ValueListenableBuilder(
              valueListenable: startDateNotifier,
              builder: (context, startDate, child) {
                return ValueListenableBuilder(
                    valueListenable: endDateNotifier,
                    builder: (context, endDate, child) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            hint: const Text('月份'),
                            value: _selectedMonth(startDate, endDate),
                            items: List.generate(
                              12,
                              (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text('${index + 1}月'),
                              ),
                            ),
                            onChanged: (month) {
                              if (month == null) {
                                return;
                              }
                              DateTime now = DateTime.now();
                              startDateNotifier.value =
                                  DateTime(now.year, month, 1);
                              endDateNotifier.value =
                                  DateTime(now.year, month + 1, 0, 23, 59, 59);
                              onChanged();
                            },
                          ),
                        ),
                      );
                    });
              }),
        ValueListenableBuilder(
            valueListenable: startDateNotifier,
            builder: (context, startDate, child) {
              return DatePickerField(
                initialDate: startDate,
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
              return DatePickerField(
                initialDate: endDate,
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

int? _selectedMonth(DateTime? startDate, DateTime? endDate) {
  if (startDate == null || endDate == null) {
    return null;
  }
  DateTime now = DateTime.now();
  for (int month = 1; month <= 12; month++) {
    DateTime monthStart = DateTime(now.year, month, 1);
    DateTime monthEnd = DateTime(now.year, month + 1, 0, 23, 59, 59);
    if (_isSameSecond(startDate, monthStart) &&
        _isSameSecond(endDate, monthEnd)) {
      return month;
    }
  }
  return null;
}

bool _isSameSecond(DateTime a, DateTime b) {
  return a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute &&
      a.second == b.second;
}
