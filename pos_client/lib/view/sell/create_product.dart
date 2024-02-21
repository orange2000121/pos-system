import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pos/store/model/sell/good_providers/goods.dart';
import 'package:pos/store/model/sell/good_providers/goods_group.dart';
import 'package:pos/template/item_edit.dart';
import 'package:pos/tool/calculate_text_size.dart';

class CreateProduct extends StatefulWidget {
  const CreateProduct({super.key});

  @override
  State<CreateProduct> createState() => _CreateProductState();
}

class _CreateProductState extends State<CreateProduct> {
  GoodsProvider goodsProvider = GoodsProvider();
  // TextEditingController nameController = TextEditingController();
  // TextEditingController priceController = TextEditingController();
  // TextEditingController unitController = TextEditingController();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    goodsProvider.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增產品'),
      ),
      body: Center(
        child: Row(
          children: [
            Expanded(flex: 2, child: showProduct()),
          ],
        ),
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                   Widget                                   */
  /* -------------------------------------------------------------------------- */

  Widget product(int groupId) {
    return FutureBuilder(
      initialData: const [],
      future: goodsProvider.getItemsByGroupId(groupId),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          List<Widget> widgets = [];
          for (Good item in snapshot.data ?? []) {
            widgets.add(item.toWidget(
              onTap: () => editProduct(item),
            ));
          }
          return Column(children: widgets);
        } else {
          return const Text('no data');
        }
      },
    );
  }

  Widget showProduct() {
    return FutureBuilder(
      future: GoodsGroupProvider().getAll(),
      builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
        List<Widget> widgets = [];
        if (snapshot.hasData) {
          for (GoodsGroupItem item in snapshot.data!) {
            widgets.add(Column(
              children: [
                groupBar(item.name, () => addProduct(item)),
                product(item.id!),
              ],
            ));
          }
        }
        return ListView(
          children: [
            ...widgets,
            groupBar('新增群組', addGroup),
          ],
        );
      },
    );
  }

  Widget groupBar(String title, Function? onTap) {
    return Card(
      child: InkWell(
        onTap: onTap as void Function()?,
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(10),
          child: Text(title),
        ),
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                  Function                                  */
  /* -------------------------------------------------------------------------- */
  void addGroup() {
    Uint8List? image;
    TextEditingController groupNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('新增群組'),
          content: ItemEdit(
            choseImage: ChoseImage(
              size: 100,
              initialImage: image,
              onImageChanged: (Uint8List? newImage) {
                image = newImage;
              },
            ),
            textFields: [
              ItemEditTextField(
                labelText: '群組名稱',
                controller: groupNameController,
              )
            ],
            buttons: [
              ItemEditButton(
                name: '確定',
                onPressed: () {
                  GoodsGroupProvider().insert(GoodsGroupItem(groupNameController.text, image: image));
                  setState(() {});
                  Navigator.pop(context);
                },
              ),
              ItemEditButton(
                name: '取消',
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void addProduct(GoodsGroupItem group) async {
    ValueNotifier<String> addProductGroupNameNotifier = ValueNotifier(group.name);
    TextEditingController addProductNameController = TextEditingController();
    TextEditingController addProductPriceController = TextEditingController();
    TextEditingController addProductUnitController = TextEditingController();
    TextEditingController addProductGroupNameController = TextEditingController(text: group.name);
    GoodsGroupProvider goodsGroupProvider = GoodsGroupProvider();
    Uint8List? image;
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Text('新增商品至 『'),
                ValueListenableBuilder(
                    valueListenable: addProductGroupNameNotifier,
                    builder: (context, groupName, child) {
                      return SizedBox(
                        width: calculateTextSize(context, groupName).width + 10,
                        child: TextField(
                          key: const Key('addProductGroupName'),
                          controller: addProductGroupNameController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            addProductGroupNameNotifier.value = value;
                            group.name = value;
                            goodsGroupProvider.update(group.id!, group);
                          },
                        ),
                      );
                    }),
                const Text('』'),
              ],
            ),
            content: ItemEdit(
              choseImage: ChoseImage(
                size: 100,
                onImageChanged: (img) => image = img,
              ),
              textFields: [
                ItemEditTextField(
                  labelText: '產品名稱',
                  controller: addProductNameController,
                ),
                ItemEditTextField(
                  labelText: '產品單位',
                  controller: addProductUnitController,
                ),
                ItemEditTextField(
                  labelText: '產品價格',
                  controller: addProductPriceController,
                  keyboardType: TextInputType.number,
                ),
              ],
              buttons: [
                ItemEditButton(
                  name: '確定',
                  onPressed: () {
                    Good good = Good(group.id!, addProductNameController.text, double.parse(addProductPriceController.text), addProductUnitController.text, image: image);
                    goodsProvider.insert(good);
                    Navigator.pop(context);
                    setState(() {});
                  },
                ),
                ItemEditButton(
                  name: '取消',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                ItemEditButton(
                  name: '刪除群組',
                  onPressed: () {
                    goodsProvider.deleteByGroupId(group.id!);
                    GoodsGroupProvider().delete(group.id!);
                    Navigator.pop(context);
                    setState(() {});
                  },
                  foregroundColor: Colors.red,
                ),
              ],
            ),
          );
        });
    setState(() {});
  }

  void editProduct(Good good) {
    TextEditingController nameController = TextEditingController(text: good.name);
    TextEditingController priceController = TextEditingController(text: good.price.toString());
    TextEditingController unitController = TextEditingController(text: good.unit);
    ValueNotifier showImageNotifier = ValueNotifier<Uint8List?>(good.image);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('修改 ${good.name}'),
            content: ItemEdit(
              choseImage: ChoseImage(
                size: 100,
                initialImage: good.image,
                onImageChanged: (img) {
                  good.image = img;
                  showImageNotifier.value = good.image;
                },
              ),
              textFields: [
                ItemEditTextField(
                  labelText: '產品名稱',
                  controller: nameController,
                ),
                ItemEditTextField(
                  labelText: '產品單位',
                  controller: unitController,
                ),
                ItemEditTextField(
                  labelText: '產品單價',
                  controller: priceController,
                  keyboardType: TextInputType.number,
                ),
              ],
              buttons: [
                ItemEditButton(
                  name: '修改產品',
                  onPressed: () {
                    good.name = nameController.text;
                    good.price = double.parse(priceController.text);
                    good.unit = unitController.text;
                    goodsProvider.update(good);
                    Navigator.pop(context);
                    setState(() {});
                  },
                ),
                ItemEditButton(
                  name: '刪除產品',
                  onPressed: () {
                    goodsProvider.delete(good.id!);
                    setState(() {});
                    Navigator.pop(context);
                  },
                  foregroundColor: Colors.red,
                ),
                ItemEditButton(
                  name: '取消',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        });
  }
}
