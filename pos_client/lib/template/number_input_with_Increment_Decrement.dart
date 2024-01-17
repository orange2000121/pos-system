import 'package:flutter/material.dart';

class NumberInputWithIncrementDecrement extends StatefulWidget {
  final Function(int)? onChanged;
  const NumberInputWithIncrementDecrement({
    super.key,
    this.onChanged,
  });

  @override
  State<NumberInputWithIncrementDecrement> createState() => _NumberInputWithIncrementDecrementState();
}

class _NumberInputWithIncrementDecrementState extends State<NumberInputWithIncrementDecrement> {
  TextEditingController quantity = TextEditingController(text: '1');
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 60,
          // margin: const EdgeInsets.all(10),
          child: TextField(
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            controller: quantity,
            onTap: () => quantity.value = TextEditingValue.empty,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
            onChanged: (value) {
              if (widget.onChanged != null) {
                widget.onChanged!(int.parse(value));
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
                quantity.text = (int.parse(quantity.text) + 1).toString();
                if (widget.onChanged != null) {
                  widget.onChanged!(int.parse(quantity.text));
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
                if (int.parse(quantity.text) > 1) {
                  quantity.text = (int.parse(quantity.text) - 1).toString();
                  if (widget.onChanged != null) {
                    widget.onChanged!(int.parse(quantity.text));
                  }
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
