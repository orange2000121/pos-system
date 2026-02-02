import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pos/logic/sell/create_product_logic.dart';
import 'package:pos/logic/sell/product_item.dart';
import 'package:pos/store/model/sell/product_providers/product.dart';
import 'package:pos/store/model/sell/product_providers/product_group.dart';
import 'package:pos/template/item_edit.dart';
import 'package:pos/tool/calculate_text_size.dart';

class CreateProduct extends StatefulWidget {
  const CreateProduct({super.key});

  @override
  State<CreateProduct> createState() => _CreateProductState();
}

class _CreateProductState extends State<CreateProduct> {
  ProductProvider productProvider = ProductProvider();
  CreateProductLogic createProductLogic = CreateProductLogic();

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
    productProvider.close();
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
    Future<List<ProductItem>> getProductItemByGroupId(int groupId) async {
      List<Product> products = await productProvider.getItemsByGroupId(groupId);
      return await ProductItems().convertProducts2ProductItems(products);
    }

    return FutureBuilder(
      initialData: const [],
      future: getProductItemByGroupId(groupId),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          List<Widget> widgets = [];
          for (ProductItem item in snapshot.data ?? []) {
            widgets.add(productTile(item));
          }
          return Column(children: widgets);
        } else {
          return const Text('no data');
        }
      },
    );
  }

  ListTile productTile(ProductItem item) {
    return ListTile(
      leading: item.image != null && item.image!.isNotEmpty
          ? Image.memory(
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              item.image!,
              errorBuilder: (context, error, stackTrace) => const FlutterLogo(size: 50),
            )
          : null,
      title: Text(item.name),
      subtitle: Text('單價: ${item.price}'),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => editProduct(item),
      ),
    );
  }

  Widget showProduct() {
    return FutureBuilder(
      future: ProductGroupProvider().getAll(),
      builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
        List<Widget> widgets = [];
        if (snapshot.hasData) {
          for (ProductGroupItem item in snapshot.data!) {
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
            Column(
              children: [
                groupBar('未分類', () => null),
                product(0),
              ],
            ),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text(title), const Icon(Icons.add)],
          ),
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
                  ProductGroupProvider().insert(ProductGroupItem(groupNameController.text, image: image));
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

  void addProduct(ProductGroupItem group) async {
    ValueNotifier<String> addProductGroupNameNotifier = ValueNotifier(group.name);
    TextEditingController addProductNameController = TextEditingController();
    TextEditingController addProductPriceController = TextEditingController();
    TextEditingController addProductUnitController = TextEditingController();
    TextEditingController addProductGroupNameController = TextEditingController(text: group.name);
    ProductGroupProvider productGroupProvider = ProductGroupProvider();
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
                            productGroupProvider.update(group.id!, group);
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
                    createProductLogic.addNewProduct(
                      group: group,
                      name: addProductNameController.text,
                      price: double.parse(addProductPriceController.text),
                      unit: addProductUnitController.text,
                      image: image,
                    );
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
                    productProvider.deleteByGroupId(group.id!);
                    ProductGroupProvider().delete(group.id!);
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

  void editProduct(ProductItem product) {
    TextEditingController nameController = TextEditingController(text: product.name);
    TextEditingController priceController = TextEditingController(text: product.price.toString());
    TextEditingController unitController = TextEditingController(text: product.unit);

    ValueNotifier showImageNotifier = ValueNotifier<Uint8List?>(product.image);
    ValueNotifier<int?> productGroupIdNotifier = ValueNotifier<int?>(product.groupId);

    ProductGroupProvider productGroupProvider = ProductGroupProvider();

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('修改 ${product.name}'),
            content: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text('類別：'),
                    FutureBuilder(
                        future: productGroupProvider.getAll(),
                        builder: (context, snapshot) {
                          return ValueListenableBuilder<int?>(
                              valueListenable: productGroupIdNotifier,
                              builder: (context, selectValue, child) {
                                if (selectValue == 0) selectValue = null;
                                List<DropdownMenuItem<int>> items = [];
                                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                  for (var vendor in snapshot.data!) {
                                    items.add(DropdownMenuItem<int>(
                                      value: vendor.id,
                                      child: Text(vendor.name),
                                    ));
                                  }
                                }
                                return DropdownButton<int>(
                                  value: selectValue,
                                  hint: snapshot.hasData && snapshot.data!.isNotEmpty ? const Text('請選擇供應商') : const Text('無供應商'),
                                  onChanged: (selectValue) {
                                    productGroupIdNotifier.value = selectValue!;
                                  },
                                  items: items,
                                );
                              });
                        }),
                  ],
                ),
                ItemEdit(
                  choseImage: ChoseImage(
                    size: 100,
                    initialImage: product.image,
                    onImageChanged: (img) {
                      product.image = img;
                      showImageNotifier.value = product.image;
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
                        product.groupId = productGroupIdNotifier.value ?? 0;
                        product.name = nameController.text;
                        product.price = double.parse(priceController.text);
                        product.unit = unitController.text;
                        createProductLogic.editProduct(productItem: product);
                        Navigator.pop(context);
                        setState(() {});
                      },
                    ),
                    ItemEditButton(
                      name: '取消銷售',
                      onPressed: () {
                        // productProvider.delete(product.goodId);
                        createProductLogic.disableProduct(productItem: product);
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
              ],
            ),
          );
        });
  }
}
