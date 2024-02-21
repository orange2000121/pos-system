import 'package:flutter/material.dart';

class TextIconButton extends StatelessWidget {
  final Function() onPressed;
  final String text;
  final IconData icon;
  const TextIconButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(text),
              Icon(icon),
            ],
          )),
    );
  }
}
