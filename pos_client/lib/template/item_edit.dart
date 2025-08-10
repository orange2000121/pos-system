import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ItemEditTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String labelText;
  final TextInputType? keyboardType;
  const ItemEditTextField({
    super.key,
    this.controller,
    required this.labelText,
    this.keyboardType,
  });

  @override
  State<ItemEditTextField> createState() => _ItemEditTextFieldState();
}

class _ItemEditTextFieldState extends State<ItemEditTextField> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: widget.labelText,
        ),
      ),
    );
  }
}

class ItemEditButton extends StatefulWidget {
  final String name;
  final Function()? onPressed;
  final Color? foregroundColor;
  const ItemEditButton({
    super.key,
    required this.name,
    this.onPressed,
    this.foregroundColor,
  });

  @override
  State<ItemEditButton> createState() => _ItemEditButtonState();
}

class _ItemEditButtonState extends State<ItemEditButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(3),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: widget.foregroundColor,
        ),
        onPressed: widget.onPressed,
        child: Text(widget.name),
      ),
    );
  }
}

class ChoseImage extends StatefulWidget {
  final double size;
  final Uint8List? initialImage;
  final Function(Uint8List image)? onImageChanged;

  const ChoseImage({
    super.key,
    required this.size,
    this.initialImage,
    this.onImageChanged,
  });

  @override
  State<ChoseImage> createState() => _ChoseImageState();
}

class _ChoseImageState extends State<ChoseImage> {
  late ValueNotifier<Uint8List> showImageNotifier;
  @override
  void initState() {
    super.initState();
    showImageNotifier = ValueNotifier(widget.initialImage ?? Uint8List(0));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (image != null) {
          Uint8List imageTemp = await image.readAsBytes();
          widget.onImageChanged?.call(imageTemp);
          showImageNotifier.value = imageTemp;
        }
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: ValueListenableBuilder(
            valueListenable: showImageNotifier,
            builder: (BuildContext context, showImage, Widget? child) {
              return Image.memory(
                showImage,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image,
                  size: 80,
                ),
              );
            }),
      ),
    );
  }
}

class ItemEdit extends StatefulWidget {
  final ChoseImage? choseImage;
  final List<ItemEditTextField> textFields;
  final List<ItemEditButton> buttons;
  const ItemEdit({
    super.key,
    this.choseImage,
    required this.textFields,
    required this.buttons,
  });

  @override
  State<ItemEdit> createState() => _ItemEditState();
}

class _ItemEditState extends State<ItemEdit> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.choseImage != null) widget.choseImage!,
        ...widget.textFields,
        const SizedBox(height: 10),
        ...widget.buttons,
      ],
    );
  }
}
