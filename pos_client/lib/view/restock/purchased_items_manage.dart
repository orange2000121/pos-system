import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pos/store/model/restock/purchased_items.dart';
import 'package:pos/store/model/restock/purchased_items_tag.dart';
import 'package:pos/store/model/restock/tag_purchased_item_relationship.dart';
import 'package:pos/store/model/restock/vendor.dart';
import 'package:pos/template/item_edit.dart';
import 'package:pos/template/tags_grid_view.dart';

class PurchasedItemsManage extends StatefulWidget {
  const PurchasedItemsManage({super.key});

  @override
  State<PurchasedItemsManage> createState() => _PurchasedItemsManageState();
}

class _PurchasedItemsManageState extends State<PurchasedItemsManage> {
  PurchasedItemProvider purchasedItemProvider = PurchasedItemProvider();
  VendorProvider vendorProvider = VendorProvider();
  TagPurchasedItemRelationshipProvider tagPurchasedItemRelationshipProvider = TagPurchasedItemRelationshipProvider();
  PurchasedItemsTagProvider purchasedItemsTagProvider = PurchasedItemsTagProvider();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('貨物管理'),
      ),
      body: FutureBuilder(
          future: purchasedItemProvider.queryAll(),
          builder: (context, snapshot) {
            return GridView(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
              ),
              children: [
                Card(
                  child: SizedBox(
                    child: InkWell(
                      onTap: () async {
                        PurchasedItem? result = await showDialog(
                          context: context,
                          builder: (context) {
                            return purchasedDetail(context);
                          },
                        );
                        if (result != null && result.name != '') {
                          purchasedItemProvider.insert(result);
                          setState(() {});
                        }
                      },
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add),
                          Text('新增品項'),
                        ],
                      ),
                    ),
                  ),
                ),
                if (snapshot.hasData)
                  ...snapshot.data!.map((e) {
                    return Card(
                      child: SizedBox(
                        child: InkWell(
                          onTap: () {
                            showDialog(context: context, builder: (context) => purchasedDetail(context, purchasedItem: e)).then((value) {
                              if (value != null) {
                                purchasedItemProvider.update(e.id!, value);
                                setState(() {});
                              }
                            });
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('貨物名稱：${e.name}'),
                              Text('進貨單位：${e.unit}'),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
              ],
            );
          }),
    );
  }

  AlertDialog purchasedDetail(BuildContext context, {PurchasedItem? purchasedItem}) {
    ValueNotifier<int> vendorIdNotifier = ValueNotifier(0);
    ValueNotifier<TagsGridViewTag> tagNotifier = ValueNotifier(const TagsGridViewTag(id: 0, name: '', color: Color(-1)));
    List<TagsGridViewTag> tagGridViewTags = [];
    String name = '';
    String unit = '';
    if (purchasedItem != null) {
      vendorIdNotifier.value = purchasedItem.vendorId;
      name = purchasedItem.name;
      unit = purchasedItem.unit;
    }
    return AlertDialog(
      title: purchasedItem != null ? const Text('品項設定') : const Text('新增品項'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text('供應商：'),
                FutureBuilder(
                    future: vendorProvider.getAll(),
                    initialData: [Vendor.initial()],
                    builder: (context, snapshot) {
                      // if (purchasedItem == null && snapshot.data!.isNotEmpty) {
                      //   vendorIdNotifier.value = snapshot.data!.first.id!;
                      //   print('vendor id: ${vendorIdNotifier.value}');
                      // }
                      return ValueListenableBuilder<int>(
                          valueListenable: vendorIdNotifier,
                          builder: (context, value, child) {
                            return DropdownButton(
                              value: vendorIdNotifier.value,
                              onChanged: (value) {
                                // setState(() {
                                //   vendorIdNotifier.value = value!;
                                // });
                                vendorIdNotifier.value = value!;
                                // vendorIdNotifier.notifyListeners();
                              },
                              items: [
                                DropdownMenuItem<int>(
                                  value: Vendor.initial().id,
                                  child: const Text('請選擇供應商'),
                                ),
                                ...snapshot.data!.map((e) {
                                  return DropdownMenuItem<int>(
                                    value: e.id,
                                    child: Text(e.name),
                                  );
                                }).toList(),
                                if (snapshot.data!.isEmpty)
                                  DropdownMenuItem<int>(
                                    value: Vendor.initial().id,
                                    child: const Text('無供應商'),
                                  ),
                                // DropdownMenuItem<int>(
                                //   value: Vendor.initial().id,
                                //   child: TextButton(
                                //       onPressed: () {
                                //         Navigator.push(context, MaterialPageRoute(builder: (context) => VendorDetail(vendor: Vendor.initial(), isCreate: true))).then((value) {
                                //           if (value != null) {
                                //             setState(() {});
                                //           }
                                //         });
                                //       },
                                //       child: Text('新增供應商')),
                                // ),
                              ],
                            );
                          });
                    }),
              ],
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '品項名稱',
              ),
              initialValue: name,
              onChanged: (value) => name = value,
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '單位',
              ),
              initialValue: unit,
              onChanged: (value) => unit = value,
            ),
            FutureBuilder(future: () async {
              //標籤取得
              List<PurchasedItemsTag> tags = [];
              var tagPurchasedRelates = await tagPurchasedItemRelationshipProvider.getItemsByPurchasedItemId(purchasedItem!.id!);
              for (var relate in tagPurchasedRelates) {
                var tag = await purchasedItemsTagProvider.getItem(relate.tagId);
                tags.add(tag);
              }
              return tags;
            }(), builder: (context, tagsSnapshot) {
              for (PurchasedItemsTag tag in tagsSnapshot.data ?? []) {
                tagGridViewTags.add(TagsGridViewTag(
                    id: tag.id!,
                    name: tag.name,
                    color: Color(tag.color),
                    onDeleted: () async {
                      var tagPurchasedRelates = await tagPurchasedItemRelationshipProvider.getItemsByPurchasedItemId(purchasedItem!.id!);
                      for (var relate in tagPurchasedRelates) {
                        if (relate.tagId == tag.id) {
                          tagPurchasedItemRelationshipProvider.delete(relate.id!);
                          break;
                        }
                      }
                    }));
              }
              return ValueListenableBuilder(
                  valueListenable: tagNotifier,
                  builder: (context, value, child) {
                    if (value.color.value != 4294967295) {
                      tagGridViewTags.add(value);
                    }
                    return TagsGridView(
                      tags: tagGridViewTags,
                      onChanged: (t) {
                        tagGridViewTags = t;
                      },
                    );
                  });
            }),
          ],
        ),
      ),
      actions: [
        if (purchasedItem != null) addTag(context, purchasedItem, tagNotifier, tagGridViewTags),
        if (purchasedItem != null)
          TextButton(
            onPressed: () {
              setState(() {
                purchasedItemProvider.delete(purchasedItem.id!);
                Navigator.of(context).pop();
              });
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ValueListenableBuilder(
            valueListenable: vendorIdNotifier,
            builder: (context, value, child) {
              return TextButton(
                onPressed: vendorIdNotifier.value != Vendor.initial().id
                    ? () {
                        Navigator.of(context).pop(
                          PurchasedItem(vendorId: vendorIdNotifier.value, name: name, unit: unit),
                        );
                      }
                    : null,
                child: purchasedItem == null ? const Text('新增') : const Text('修改'),
              );
            }),
      ],
    );
  }

  TextButton addTag(
    BuildContext context,
    PurchasedItem purchasedItem,
    ValueNotifier<TagsGridViewTag> tagNotifier,
    List tagsData,
  ) {
    return TextButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            TextEditingController tagNameController = TextEditingController();
            return AlertDialog(
                title: const Text('新增標籤'),
                content: SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      ItemEdit(
                        textFields: [
                          ItemEditTextField(
                            labelText: '標籤名稱',
                            controller: tagNameController,
                          ),
                        ],
                        buttons: [
                          ItemEditButton(
                            name: '新增標籤',
                            onPressed: () {
                              PurchasedItemsTag purchasedItemsTag = PurchasedItemsTag(name: tagNameController.text, color: Random().nextInt(0xFF051B2B)); //製作一個隨機顏色的標籤，用於存入資料庫
                              purchasedItemsTagProvider.insert(purchasedItemsTag).then((tagId) async {
                                tagPurchasedItemRelationshipProvider
                                    .insert(
                                      TagPurchasedItemRelationship(tagId: tagId, purchasedItemId: purchasedItem.id!), // 新增貨物和標籤的關係
                                    )
                                    .then(
                                      (relationshipId) => setState(() {
                                        // 這邊的value是插入關係生成的id
                                        //新增一個顯示的標籤到顯示的標籤列表
                                        tagNotifier.value = TagsGridViewTag(
                                          id: tagId,
                                          name: purchasedItemsTag.name,
                                          color: Color(purchasedItemsTag.color),
                                          onDeleted: () async {
                                            var tagPurchasedRelates = await tagPurchasedItemRelationshipProvider.getItemsByPurchasedItemId(purchasedItem.id!); //找出所有和這個貨物有關的標籤
                                            for (var relate in tagPurchasedRelates) {
                                              if (relate.tagId == relationshipId) {
                                                //在這些標籤中有和要刪掉的標籤一樣的id，將其刪除
                                                tagPurchasedItemRelationshipProvider.delete(relate.id!);
                                                break;
                                              }
                                            }
                                          },
                                        );
                                        Navigator.pop(context);
                                      }),
                                    );
                              });
                            },
                          ),
                        ],
                      ),
                      //顯示所有貨物的標籤
                      FutureBuilder(
                        future: () async {
                          //標籤取得
                          List<PurchasedItemsTag> tags = [];
                          tags = await purchasedItemsTagProvider.getAll();
                          return tags;
                        }(),
                        builder: (context, tagsSnapshot) {
                          List<TagsGridViewTag> tagGridViewTags = [];
                          for (PurchasedItemsTag tag in tagsSnapshot.data ?? []) {
                            if (tagsData.any((element) {
                              return element.id == tag.id;
                            })) {
                              continue;
                            }
                            //轉換成顯示用的標籤
                            tagGridViewTags.add(
                              TagsGridViewTag(
                                  id: tag.id!,
                                  name: tag.name,
                                  color: Color(tag.color),
                                  showDeleteIcon: false,
                                  onTap: () {
                                    tagPurchasedItemRelationshipProvider.insert(
                                      TagPurchasedItemRelationship(tagId: tag.id!, purchasedItemId: purchasedItem.id!),
                                    );
                                    //點擊標籤時，將標籤加入到顯示的標籤列表
                                    tagNotifier.value = TagsGridViewTag(
                                      id: tag.id!,
                                      name: tag.name,
                                      color: Color(tag.color),
                                      onDeleted: () async {
                                        //刪除標籤時，將標籤從顯示的標籤列表中刪除
                                        var tagPurchasedRelates = await tagPurchasedItemRelationshipProvider.getItemsByPurchasedItemId(purchasedItem.id!);
                                        for (var relate in tagPurchasedRelates) {
                                          if (relate.tagId == tag.id) {
                                            tagPurchasedItemRelationshipProvider.delete(relate.id!);
                                            break;
                                          }
                                        }
                                      },
                                    );
                                    Navigator.pop(context);
                                  }),
                            );
                          }
                          return TagsGridView(
                            tags: tagGridViewTags,
                          );
                        },
                      ),
                    ],
                  ),
                ));
          },
        );
      },
      child: const Text('新增標籤', textAlign: TextAlign.center),
    );
  }

  // Future<dynamic> newTag(
  //     BuildContext context, PurchasedItemsTagProvider purchasedItemsTagProvider, TagPurchasedItemRelationshipProvider tagPurchasedItemRelationshipProvider, PurchasedItem? purchasedItem) {
  //   return showDialog(
  //     context: context,
  //     builder: (context) {
  //       String tagName = '';
  //       return AlertDialog(
  //           title: const Text('新增標籤'),
  //           content: ItemEdit(
  //             textFields: [
  //               ItemEditTextField(
  //                 labelText: '標籤名稱',
  //                 controller: TextEditingController(text: tagName),
  //               ),
  //             ],
  //             buttons: [
  //               ItemEditButton(
  //                 name: '新增',
  //                 onPressed: () {
  //                   purchasedItemsTagProvider.insert(PurchasedItemsTag(name: tagName, color:Random().nextInt(0xFF051B2B))).then((value) {
  //                     tagPurchasedItemRelationshipProvider.insert(TagPurchasedItemRelationship(tagId: value, purchasedItemId: purchasedItem!.id!));
  //                     setState(() {});
  //                   });
  //                 },
  //               ),
  //             ],
  //           ));
  //     },
  //   );
  // }
}
