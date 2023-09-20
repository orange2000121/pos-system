import 'package:flutter/material.dart';

/// This is the stateful widget that the main application instantiates.
class SmallItemCard extends StatefulWidget {
  final Widget title;
  final List<Widget>? subtitle;
  final List<Widget>? simpleInfo;
  final List<Widget>? detailedInfo;
  final Function()? dialogAction;
  const SmallItemCard({super.key, required this.title, this.subtitle, this.simpleInfo, this.detailedInfo, this.dialogAction});

  @override
  State<SmallItemCard> createState() => _SmallItemCardState();
}

class _SmallItemCardState extends State<SmallItemCard> {
  /* -------------------------------------------------------------------------- */
  /*                                   Widgets                                  */
  /* -------------------------------------------------------------------------- */
  Widget dialog(BuildContext context) {
    return AlertDialog(
      title: widget.title,
      content: Column(
        children: [
          SizedBox(
            height: widget.subtitle != null ? MediaQuery.of(context).size.height * 0.1 : 0,
            child: Column(
              children: widget.subtitle ?? [],
            ),
          ),
          Expanded(
            child: SizedBox(
              width: MediaQuery.of(context).size.height * 0.8,
              child: ListView(children: widget.detailedInfo ?? widget.simpleInfo ?? []),
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            widget.dialogAction?.call();
            Navigator.of(context).pop();
          },
          child: const Text('確認'),
        ),
        ElevatedButton(onPressed: Navigator.of(context).pop, child: const Text('取消')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return dialog(context);
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey)),
          // borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: widget.title,
          title: Column(children: widget.subtitle ?? []),
          subtitle: Column(children: widget.simpleInfo ?? []),
          trailing: const Icon(Icons.keyboard_arrow_right),
        ),
      ),
    );
  }
}
