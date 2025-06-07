// ignore_for_file: file_names

import 'package:flutter/material.dart';

class NumberInputWithIncrementDecrement extends StatefulWidget {
  final Function(double number)? onChanged;
  final Function(double number)? onEditingComplete;
  final double initialNumber;
  final double minNumber; // 最小值
  final double maxNumber; // 最大值
  final double width;
  final double height;

  ///有上下箭頭的數字輸入框
  const NumberInputWithIncrementDecrement({
    super.key,
    this.initialNumber = 1,
    this.onChanged,
    this.onEditingComplete,
    this.width = 60,
    this.height = 60,
    this.minNumber = 1,
    this.maxNumber = 100,
  });

  @override
  State<NumberInputWithIncrementDecrement> createState() => _NumberInputWithIncrementDecrementState();
}

class _NumberInputWithIncrementDecrementState extends State<NumberInputWithIncrementDecrement> {
  TextEditingController quantity = TextEditingController();
  @override
  void initState() {
    super.initState();
    quantity.text = widget.initialNumber.toString();
  }

  @override
  void didUpdateWidget(NumberInputWithIncrementDecrement oldWidget) {
    super.didUpdateWidget(oldWidget);
    quantity.text = widget.initialNumber.toString();
  }

  double str2double(String str) {
    try {
      return double.parse(str);
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: widget.key,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              controller: quantity,
              onTap: () => quantity.value = TextEditingValue(
                text: quantity.text,
                selection: TextSelection(
                  baseOffset: 0,
                  extentOffset: quantity.text.length,
                ),
              ),
              decoration: const InputDecoration(border: UnderlineInputBorder()),
              onChanged: (value) {
                if (widget.onChanged != null) {
                  widget.onChanged!(str2double(value));
                }
              },
              onEditingComplete: () {
                if (widget.onEditingComplete != null) {
                  widget.onEditingComplete!(str2double(quantity.text));
                }
              },
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.all(0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  if (str2double(quantity.text) >= widget.maxNumber) {
                    return;
                  }
                  quantity.text = (str2double(quantity.text) + 1).toString();
                  if (widget.onChanged != null) {
                    widget.onChanged!(str2double(quantity.text));
                  }
                },
                child: const Icon(
                  Icons.arrow_drop_up,
                  color: Colors.grey,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.all(0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  if (str2double(quantity.text) <= widget.minNumber) {
                    return;
                  }
                  quantity.text = (str2double(quantity.text) - 1).toString();
                  if (widget.onChanged != null) {
                    widget.onChanged!(str2double(quantity.text));
                  }
                },
                child: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
