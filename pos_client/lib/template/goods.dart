import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/logic/cashier_logic.dart';
import 'package:pos/store/model/goods.dart';
import 'package:pos/store/model/goods_group.dart';

class GoodsTemplate {
  late CashierLogic cashierLogic = CashierLogic();
  late ValueNotifier<int> groupIdNotifier = ValueNotifier(-1); // -1: 全部
  late BuildContext context;
  GoodsTemplate({required this.context});
  Widget goodsList() {
    return FutureBuilder(
        future: GoodsProvider().getAll(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Map<int, List<Good>> groupMap = {};
            for (var i = 0; i < snapshot.data!.length; i++) {
              if (groupMap.containsKey(snapshot.data![i].groupId)) {
                groupMap[snapshot.data![i].groupId]!.add(snapshot.data![i]);
              } else {
                groupMap[snapshot.data![i].groupId] = [snapshot.data![i]];
              }
            }
            return Expanded(
                child: ValueListenableBuilder(
                    valueListenable: groupIdNotifier,
                    builder: (context, groupId, child) {
                      int goodListLength;
                      if (groupId == -1) {
                        goodListLength = snapshot.data!.length;
                      } else {
                        goodListLength = groupMap[groupId]?.length ?? 0;
                      }
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                        ),
                        itemCount: goodListLength,
                        itemBuilder: (context, index) {
                          if (groupId == -1) {
                            // groupId == -1 代表顯示全部商品
                            return cashierProduct(snapshot.data![index]);
                          } else {
                            return cashierProduct(groupMap[groupId]![index]);
                          }
                        },
                      );
                    }));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Widget abacus(Good item) {
    List<Widget> sugar = [];
    List<Widget> ice = [];
    List<String> sugarList = ['正常糖', '少糖', '半糖', '微糖', '無糖'];
    List<String> iceList = ['正常冰', '少冰', '半冰', '微冰', '去冰'];
    String chosenSugar = sugarList[0], chosenIce = iceList[0];
    TextEditingController quantity = TextEditingController(text: '1');
    for (var i = 0; i < sugarList.length; i++) {
      sugar.add(ElevatedButton(
        onPressed: () {
          chosenSugar = sugarList[i];
        },
        child: Text(sugarList[i]),
      ));
    }
    for (var i = 0; i < iceList.length; i++) {
      ice.add(ElevatedButton(
        onPressed: () {
          chosenIce = iceList[i];
        },
        child: Text(iceList[i]),
      ));
    }
    return Column(
      children: [
        const Text('糖度'),
        Row(children: sugar),
        const Text('冰塊'),
        Row(children: ice),
        const Text('數量'),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                if (int.parse(quantity.text) > 1) {
                  quantity.text = (int.parse(quantity.text) - 1).toString();
                }
              },
              child: const Text('-'),
            ),
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.all(10),
              child: TextField(
                keyboardType: TextInputType.number,
                controller: quantity,
                onTap: () => quantity.value = TextEditingValue.empty,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                quantity.text = (int.parse(quantity.text) + 1).toString();
              },
              child: const Text('+'),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () {
            cashierLogic.addItem(item.id ?? -1, item.name, item.price, chosenIce, chosenSugar, int.parse(quantity.text), item.unit);
            Navigator.pop(context);
          },
          child: const Text('確定'),
        ),
      ],
    );
  }

  Widget cashierProduct(Good item) {
    return InkWell(
      onTap: () {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text(item.name),
                  content: abacus(item),
                ));
      },
      child: Card(
          child: SizedBox(
        width: 80,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.name),
            Text(item.price.toString()),
            SizedBox(
              width: 80,
              height: 80,
              child: Image.memory(
                item.image!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const FlutterLogo(size: 50),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget groupList() {
    double size = 100;
    return SizedBox(
      height: size,
      child: FutureBuilder(
        future: GoodsGroupProvider().getAll(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Widget> groupListWidgets = [];
            for (var i = 0; i < snapshot.data!.length; i++) {
              groupListWidgets.add(cashierGroupItem(snapshot.data![i]));
            }
            return ListView(
              scrollDirection: Axis.horizontal,
              children: [
                cashierGroupItem(GoodsGroupItem('全部', id: -1, image: Uint8List(0))),
                ...groupListWidgets,
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  /// 顯示收銀員畫面左側的商品分類列表中的一個分類項目。
  ///
  /// 這個 widget 會顯示一個卡片，包含商品分類的圖片和名稱。
  /// 當用戶點擊這個項目時，會通過 [groupIdNotifier] 通知父 widget，以便更新商品列表。
  ///
  /// [item] 是一個 [GoodsGroupItem] 對象，包含了分類的名稱、ID 和圖片。
  Widget cashierGroupItem(GoodsGroupItem item) {
    double size = 100;
    return InkWell(
      onTap: () => groupIdNotifier.value = item.id!,
      child: Card(
        child: SizedBox(
          width: size,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.memory(
                width: 50,
                height: 50,
                fit: BoxFit.contain,
                item.image ?? Uint8List(0),
                errorBuilder: (context, error, stackTrace) => const FlutterLogo(size: 50),
              ),
              Text(item.name),
            ],
          ),
        ),
      ),
    );
  }
}
