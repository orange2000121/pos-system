import 'package:flutter/material.dart';

class NumberInputWithIncrementDecrement extends StatefulWidget {
  final Function(double number)? onChanged;
  final Function? onEditingComplete;
  final double initialNumber;

  ///有上下箭頭的數字輸入框
  const NumberInputWithIncrementDecrement({
    super.key,
    this.initialNumber = 1,
    this.onChanged,
    this.onEditingComplete,
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

  double str2double(String str) {
    try {
      return double.parse(str);
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          height: 60,
          // margin: const EdgeInsets.all(10),
          child: TextField(
            key: widget.key,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            controller: quantity,
            onTap: () => quantity.value = TextEditingValue.empty,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
            onChanged: (value) {
              if (widget.onChanged != null) {
                widget.onChanged!(str2double(value));
              }
            },
            onEditingComplete: () {
              print('onEditingComplete');
              if (widget.onEditingComplete != null) {
                widget.onEditingComplete!();
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
                quantity.text = (str2double(quantity.text) + 1).toString();
                if (widget.onChanged != null) {
                  widget.onChanged!(str2double(quantity.text));
                }
                // if (widget.onEditingComplete != null) {
                //   widget.onEditingComplete!();
                // }
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
                if (str2double(quantity.text) > 1) {
                  quantity.text = (str2double(quantity.text) - 1).toString();
                  if (widget.onChanged != null) {
                    widget.onChanged!(str2double(quantity.text));
                  }
                  // if (widget.onEditingComplete != null) {
                  //   widget.onEditingComplete!();
                  // }
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
    );
  }
}
