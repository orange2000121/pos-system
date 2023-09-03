import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:pos/model/item.dart';

class AddItem extends StatefulWidget {
  final Item item;
  final ItemProvider itemProvider;
  final String title;
  const AddItem({super.key, required this.item, required this.itemProvider, required this.title});

  @override
  State<AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    widget.itemProvider.close();
  }

  List<Widget> makeInputWidget(Map<String, dynamic> item) {
    List<Widget> inputWidget = [];
    for (var i = 0; i < item.length; i++) {
      if (item.keys.elementAt(i) == 'image') {
        continue;
      }
      inputWidget.add(TextFormField(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: item.keys.elementAt(i),
        ),
        onChanged: (value) {
          item[item.keys.elementAt(i)] = value;
        },
      ));
    }
    return inputWidget;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> item = widget.item.toMap();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Form(
                    child: Column(
                      children: makeInputWidget(item),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        item['image'] = await image.readAsBytes();
                      }
                    },
                    child: const Text('pick image'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          widget.itemProvider.insert(widget.item.fromMap(item));
                          item['image'] = Uint8List(0);
                          setState(() {});
                        },
                        child: const Text('insert'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          widget.itemProvider.deleteAll();
                          setState(() {});
                        },
                        child: const Text('delete all'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: FutureBuilder(
                initialData: [
                  Item(),
                ],
                future: widget.itemProvider.getAll(),
                builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return snapshot.data![index].toWidget();
                      },
                    );
                  } else {
                    return const Text('no data');
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
