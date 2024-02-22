import 'package:flutter/material.dart';

class SimplAndDetailInfoCard extends StatefulWidget {
  final Widget title;
  final List<Widget>? subtitle;
  final List<Widget>? simpleInfo;
  final List<Widget>? detailedInfo;
  final List<Widget>? dialogAction;
  final Function(dynamic popValue)? onPop;

  ///用於歷史紀錄的展示，可自定義標題、副標題、簡易資訊、詳細資訊、彈出視窗按鈕、彈出視窗關閉後的動作
  const SimplAndDetailInfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.simpleInfo,
    this.detailedInfo,
    this.dialogAction,
    this.onPop,
  });

  @override
  State<SimplAndDetailInfoCard> createState() => _SimplAndDetailInfoCardState();
}

class _SimplAndDetailInfoCardState extends State<SimplAndDetailInfoCard> {
  /* -------------------------------------------------------------------------- */
  /*                                   Widgets                                  */
  /* -------------------------------------------------------------------------- */
  Widget detailInfoDialog(BuildContext context) {
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
        actions: widget.dialogAction ??
            [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('關閉'),
              ),
            ]);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        var popValue = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return detailInfoDialog(context);
          },
        );
        if (widget.onPop != null) {
          widget.onPop!(popValue);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey)),
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
