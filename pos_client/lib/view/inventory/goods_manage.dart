import 'package:flutter/material.dart';
import 'package:pos/logic/inventory/good_manage_logic.dart';
import 'package:pos/store/model/good/good.dart';
import 'package:pos/template/item_edit.dart';

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
        future: goodManageLogic.getAllGoods(),
        builder: (context, goodsSnapshot) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('貨物管理'),
              ),
              body: GridView(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                ),
                children: [
                  goodCard(
                    onTap: () => null,
                    title: '新增貨物',
                    icon: const Icon(Icons.add),
                  ),
                  if (goodsSnapshot.hasData)
                    ...goodsSnapshot.data!.map((e) {
                      return goodCard(
                        title: e.name,
                        onTap: () => showGoodDetailDialog(context, e),
                        image: e.image != null && e.image!.isNotEmpty
                            ? Image.memory(
                                e.image!,
                                fit: BoxFit.cover,
                              )
                            : null,
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

  void showGoodDetailDialog(BuildContext context, Good good) {
    GoodDetailLogic goodDetailLogic = GoodDetailLogic(mainGood: good);

    showDialog(
      context: context,
      builder: (context) {
        Widget leftColumn = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChoseImage(
              size: 100,
              initialImage: good.image,
            ),
            Text(good.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('單位：${good.unit}'),
            const SizedBox(width: 100, child: Divider()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text('銷售'),
                    Switch(value: false, onChanged: (value) {}),
                  ],
                ),
                const SizedBox(height: 50, child: VerticalDivider()),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text('進貨'),
                    Switch(value: false, onChanged: (value) {}),
                  ],
                ),
              ],
            )
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
                  future: goodDetailLogic.getBomsByGoodId(good.id),
                  builder: (context, bomsSnapshot) {
                    return ValueListenableBuilder(
                      valueListenable: goodDetailLogic.bomAndMaterialsNotifier,
                      builder: (BuildContext context, List<BomAndMaterial> bomAndMaterials, Widget? child) {
                        return ListView.builder(
                          shrinkWrap: true,
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
                                    onSelected: (value) => bomDetailLogic.setMaterialSelector(value: value ?? 0, allGoodsMap: goodManageLogic.allGoodsMap, bomAndMaterial: bomAndMaterial),
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
                                    child: TextFormField(
                                      key: ValueKey(bomAndMaterial.bom.id),
                                      initialValue: bomAndMaterial.bom.quantity.toString(),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) => bomDetailLogic.setBomQuantity(value: double.parse(value), bomAndMaterial: bomAndMaterial),
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
            width: MediaQuery.of(context).size.width * 0.45,
            height: MediaQuery.of(context).size.height * 0.4,
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
  }
}
