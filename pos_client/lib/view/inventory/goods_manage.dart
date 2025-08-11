import 'package:flutter/material.dart';
import 'package:pos/logic/inventory/good_manage_logic.dart';
import 'package:pos/store/model/good/good.dart';
import 'package:pos/store/model/good/inventory.dart';
import 'package:pos/template/item_edit.dart';
import 'package:pos/template/number_input_with_Increment_Decrement.dart';

class GoodsManage extends StatefulWidget {
  const GoodsManage({super.key});

  @override
  State<GoodsManage> createState() => _GoodsManageState();
}

class _GoodsManageState extends State<GoodsManage> {
  GoodManageLogic goodManageLogic = GoodManageLogic();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: goodManageLogic.getAllGoodsInfo(),
        builder: (context, goodsInfoSnapshot) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('貨物管理'),
              ),
              body: GridView(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                ),
                children: [
                  //todo 新增貨物
                  // goodCard(
                  //   onTap: () => null,
                  //   title: '新增貨物',
                  //   icon: const Icon(Icons.add),
                  // ),
                  if (goodsInfoSnapshot.hasData)
                    ...goodsInfoSnapshot.data!.values.map((goodInfo) {
                      return goodCard(
                        title: goodInfo['good'].name,
                        onTap: () => showGoodDetailDialog(context, goodInfo),
                        image: goodInfo['good'].image != null && goodInfo['good'].image!.isNotEmpty
                            ? Image.memory(
                                goodInfo['good'].image!,
                                fit: BoxFit.cover,
                              )
                            : null,
                        subtitle: '庫存：${goodInfo['inventory'].quantity}',
                      );
                    }),
                ],
              ));
        });
  }

  /* -------------------------------------------------------------------------- */
  /*                                   Widget                                   */
  /* -------------------------------------------------------------------------- */

  InkWell goodCard({
    Function()? onTap,
    required String title,
    Icon icon = const Icon(Icons.cases),
    Image? image,
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            image != null
                ? SizedBox(
                    width: 70,
                    height: 70,
                    child: image,
                  )
                : icon,
            Text(title),
            subtitle != null
                ? Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12),
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }

  void showGoodDetailDialog(BuildContext context, Map<String, dynamic> goodInfo) async {
    GoodDetailLogic goodDetailLogic = GoodDetailLogic(mainGood: goodInfo['good'], mainGoodInventory: goodInfo['inventory']);
    Good good = goodDetailLogic.mainGood;
    Inventory inventory = goodDetailLogic.mainGoodInventory;
    Future<List<BomAndMaterial>> bomsFuture = goodDetailLogic.getBomsByGoodId(good.id);

    await showDialog(
      context: context,
      builder: (context) {
        Widget leftColumn = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ChoseImage(
              size: 100,
              initialImage: good.image,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text(good.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text('單位：${good.unit}')],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('庫存：'),
                NumberInputWithIncrementDecrement(
                  focusNode: goodDetailLogic.inventoryQuantityFocusNode,
                  initialNumber: inventory.quantity,
                  minNumber: 0,
                  width: 100,
                  height: 50,
                  controller: goodDetailLogic.inventoryQuantityController,
                  onEditingComplete: (number) async {
                    await goodDetailLogic.makeInventory(number);
                    goodDetailLogic.inventoryQuantityFocusNode.unfocus();
                  },
                ),
              ],
            ),
            const SizedBox(width: 100, child: Divider()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text('銷售'),
                    FutureBuilder(
                        future: goodDetailLogic.isProduct(good),
                        builder: (context, asyncSnapshot) {
                          return Switch(value: asyncSnapshot.data ?? false, onChanged: (value) {});
                        }),
                  ],
                ),
                const SizedBox(height: 50, child: VerticalDivider()),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text('進貨'),
                    FutureBuilder(
                        //todo 無法顯示是否為進貨商品
                        future: goodDetailLogic.isPurchasedItem(good),
                        builder: (context, asyncSnapshot) {
                          return Switch(value: asyncSnapshot.data ?? false, onChanged: (value) {});
                        }),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 100, child: Divider()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('製造'),
                ValueListenableBuilder(
                    valueListenable: goodDetailLogic.manufactureQuantityNotifier,
                    builder: (context, manufactureQuantity, child) {
                      return NumberInputWithIncrementDecrement(
                        initialNumber: manufactureQuantity,
                        minNumber: 0,
                        width: 100,
                        controller: goodDetailLogic.manufactureQuantityController,
                        onChanged: (number) => goodDetailLogic.manufactureQuantityNotifier.value = number,
                      );
                    }),
                Text(good.unit),
              ],
            ),
            FutureBuilder(
                future: bomsFuture,
                builder: (context, asyncSnapshot) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(8),
                    child: ValueListenableBuilder(
                        valueListenable: goodDetailLogic.manufactureQuantityNotifier,
                        builder: (context, manufactureQuantity, child) {
                          return ValueListenableBuilder(
                              valueListenable: goodDetailLogic.bomAndMaterialsNotifier,
                              builder: (context, bomAndMaterials, child) {
                                return ElevatedButton(
                                  onPressed: bomAndMaterials.isNotEmpty && manufactureQuantity > 0 ? () => goodDetailLogic.manufactureProduct() : null,
                                  child: const Text('製造'),
                                );
                              });
                        }),
                  );
                }),
            FutureBuilder(
                future: goodDetailLogic.isProduct(good),
                builder: (context, isProductSnapshot) {
                  if (isProductSnapshot.connectionState == ConnectionState.waiting || isProductSnapshot.data == false) {
                    return const SizedBox();
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7 / 3 * 0.7 - (MediaQuery.of(context).size.width * 0.7 / 3 * 0.3 < 100 ? 100 : 0),
                        child: Text('庫存不足自動扣物料'),
                      ),
                      FutureBuilder(
                          future: goodDetailLogic.isAutoCreate(),
                          builder: (context, isAutoCreateSnapshot) {
                            goodDetailLogic.isAutoCreateNotifier.value = isAutoCreateSnapshot.data ?? false;
                            return ValueListenableBuilder(
                                valueListenable: goodDetailLogic.isAutoCreateNotifier,
                                builder: (context, isAutoCreate, child) {
                                  //todo 沒有bom時不要顯示
                                  return Switch(
                                      value: isAutoCreate,
                                      onChanged: (value) {
                                        goodDetailLogic.setAutoCreate(value: value);
                                        goodDetailLogic.isAutoCreateNotifier.value = value;
                                      });
                                });
                          }),
                    ],
                  );
                })
          ],
        );
        Widget rightColumn = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    '物料清單',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(onPressed: () => goodDetailLogic.addBomSetting(productId: good.id), icon: const Icon(Icons.add)),
              ],
            ),
            /* -------------------------------- 列出物料清單選項 -------------------------------- */
            Flexible(
              child: FutureBuilder(
                  future: bomsFuture,
                  builder: (context, bomsSnapshot) {
                    return ValueListenableBuilder(
                      valueListenable: goodDetailLogic.bomAndMaterialsNotifier,
                      builder: (BuildContext context, List<BomAndMaterial> bomAndMaterials, Widget? child) {
                        return ListView.builder(
                          itemCount: bomAndMaterials.length,
                          itemBuilder: (context, index) {
                            BomDetailLogic bomDetailLogic = BomDetailLogic(mainBomAndMaterial: bomAndMaterials[index]);
                            /* -------------------------------- 個別物料清單選項 -------------------------------- */
                            BomAndMaterial bomAndMaterial = bomAndMaterials[index];
                            return ListTile(
                              title: Row(
                                children: [
                                  DropdownMenu<int>(
                                    initialSelection: bomAndMaterial.material.id,
                                    dropdownMenuEntries: goodDetailLogic.getAvailableMaterials(allGoods: goodManageLogic.allGoods).map((e) {
                                      return DropdownMenuEntry(
                                        value: e.id,
                                        label: e.name,
                                      );
                                    }).toList(),
                                    onSelected: (value) {
                                      Map<int, Good> allGoodMapOnlyGoods = {};
                                      for (var good in goodManageLogic.allGoodInfo.values) {
                                        allGoodMapOnlyGoods[good['good'].id] = good['good'];
                                      }
                                      bomDetailLogic.setMaterialSelector(value: value ?? 0, allGoodsMap: allGoodMapOnlyGoods, bomAndMaterial: bomAndMaterial);
                                    },
                                  ),
                                  ValueListenableBuilder(
                                    valueListenable: bomDetailLogic.materialSelectorNotifier,
                                    builder: (BuildContext context, int materialId, Widget? child) {
                                      return Text(
                                        '(${bomAndMaterial.material.unit})',
                                      );
                                    },
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  const Text('數量：'),
                                  Expanded(
                                    child: NumberInputWithIncrementDecrement(
                                      key: ValueKey(bomAndMaterial.bom.id),
                                      initialNumber: bomAndMaterial.bom.quantity,
                                      minNumber: 0,
                                      onChanged: (value) => bomDetailLogic.setBomQuantity(value: value, bomAndMaterial: bomAndMaterial),
                                    ),
                                  )
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => bomDetailLogic.deleteBom(bom: bomAndMaterial.bom, bomAndMaterialsNotifier: goodDetailLogic.bomAndMaterialsNotifier),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }),
            ),
          ],
        );
        return AlertDialog(
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左側貨物資訊
                Expanded(
                  flex: 1,
                  child: leftColumn,
                ),
                const VerticalDivider(),
                // 右側物料清單
                Expanded(
                  flex: 2,
                  child: rightColumn,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('關閉'),
            ),
          ],
        );
      },
    );
    setState(() {});
  }
}
