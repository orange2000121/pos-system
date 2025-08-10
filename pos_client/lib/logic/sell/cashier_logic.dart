// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pos/logic/inventory/good_manage_logic.dart';
import 'package:pos/store/model/good/good.dart';
import 'package:pos/store/model/good/inventory.dart';
import 'package:pos/store/model/sell/order.dart';
import 'package:pos/store/model/sell/sell.dart';

class CashierLogic {
  SellProvider sellProvider = SellProvider();
  OrderProvider orderProvider = OrderProvider();
  InventoryProvider inventoryProvider = InventoryProvider();
  ValueNotifier<List<ShopItem>> shopItemsNotifier = ValueNotifier<List<ShopItem>>([]);
  ValueNotifier<double> totalPriceNotifier = ValueNotifier<double>(0);

  CashierLogic() {
    shopItemsNotifier.addListener(() {
      totalPriceNotifier.value = totalPrice;
    });
  }

  get shopItems => shopItemsNotifier.value;
  get totalPrice {
    double total = 0;
    for (var i = 0; i < shopItemsNotifier.value.length; i++) {
      total += shopItemsNotifier.value[i].price * shopItemsNotifier.value[i].quantity;
    }
    return total;
  }

  void addItem(int id, String name, double price, int quantity, String unit, {String? note}) {
    shopItemsNotifier.value.add(ShopItem(id, name, price, quantity, unit, note: note));
    shopItemsNotifier.notifyListeners();
  }

  void editItem(ShopItem item, {int? quantity}) {
    item.quantity = quantity ?? item.quantity;
    shopItemsNotifier.notifyListeners();
  }

  Future settleAccount(int? customerId, {DateTime? createAt}) async {
    if (shopItemsNotifier.value.isEmpty) return;
    double total = 0;
    for (var i = 0; i < shopItemsNotifier.value.length; i++) {
      total += shopItemsNotifier.value[i].price * shopItemsNotifier.value[i].quantity;
    }
    int orderId = await orderProvider.insert(
      OrderItem(total, customerId: customerId, createAt: createAt),
    );
    for (var i = 0; i < shopItemsNotifier.value.length; i++) {
      ShopItem shopItemTemp = shopItemsNotifier.value[i];
      //將每一個商品加入到銷售記錄中
      SellItem item = SellItem(
        goodId: shopItemTemp.id,
        orderId: orderId,
        name: shopItemTemp.name,
        price: shopItemTemp.price,
        quantity: shopItemTemp.quantity,
        createAt: createAt,
      );
      sellProvider.insert(item);
      //更新庫存
      Inventory? inventory = await inventoryProvider.getInventoryByGoodId(shopItemTemp.id);
      if (inventory != null) {
        GoodDetailLogic goodDetailLogic = GoodDetailLogic(
          mainGoodInventory: inventory,
          mainGood: Good(id: shopItemTemp.id, name: shopItemTemp.name, unit: shopItemTemp.unit),
        );
        //檢查需不需要自動扣除原物料
        if (await goodDetailLogic.isAutoCreate()) {
          goodDetailLogic.manufactureQuantityNotifier.value = 0;
          if (inventory.quantity < shopItemTemp.quantity) {
            goodDetailLogic.manufactureQuantityNotifier.value = shopItemTemp.quantity - inventory.quantity; //計算需要製作的數量
            goodDetailLogic.getBomsByGoodId(shopItemTemp.id).then((bomAndMaterials) {
              //如果有bom和材料，則製作商品
              if (bomAndMaterials.isNotEmpty) {
                goodDetailLogic.manufactureProduct();
              }
            });
          }
        }
        inventory.quantity -= shopItemTemp.quantity;
        await inventoryProvider.update(inventory, mode: Inventory.COMPUTE_MODE);
      } else {
        //如果庫存不存在，則新增庫存
        await inventoryProvider.insert(Inventory(goodId: shopItemTemp.id, quantity: -shopItemTemp.quantity.toDouble(), recodeMode: Inventory.CREATE_MODE, recordTime: DateTime.now()));
      }
    }
    shopItemsNotifier.value = [];
  }

  Future editOrder({
    required int orderId,
    required List<ShopItem> originShopItems,
    int? customerId,
    required DateTime createAt,
  }) async {
    if (shopItemsNotifier.value.isEmpty) return;
    double total = 0;
    for (var i = 0; i < shopItemsNotifier.value.length; i++) {
      total += shopItemsNotifier.value[i].price * shopItemsNotifier.value[i].quantity;
    }
    await orderProvider.update(orderId, OrderItem(total, customerId: customerId, createAt: createAt));
    await sellProvider.deleteByOrderId(orderId);
    for (var i = 0; i < shopItemsNotifier.value.length; i++) {
      SellItem item = SellItem(
        goodId: shopItemsNotifier.value[i].id,
        orderId: orderId,
        name: shopItemsNotifier.value[i].name,
        price: shopItemsNotifier.value[i].price,
        quantity: shopItemsNotifier.value[i].quantity,
        createAt: createAt,
      );
      await sellProvider.insert(item);
    }
    /* ---------------------------------- 更新庫存 ---------------------------------- */
    //合併同id商品數量
    Map<int, double> originItemsMerge = {};
    Map<int, double> shopItemsMerge = {};
    for (var item in originShopItems) {
      if (originItemsMerge.containsKey(item.id)) {
        originItemsMerge[item.id] = (originItemsMerge[item.id] ?? 0.0) + item.quantity;
      } else {
        originItemsMerge[item.id] = item.quantity.toDouble();
      }
    }
    for (var item in shopItemsNotifier.value) {
      if (shopItemsMerge.containsKey(item.id)) {
        shopItemsMerge[item.id] = (shopItemsMerge[item.id] ?? 0.0) + item.quantity;
      } else {
        shopItemsMerge[item.id] = item.quantity.toDouble();
      }
    }
    inventoryProvider.updateWithNewOldOrder(
      originalGoods: originItemsMerge,
      newGoods: shopItemsMerge,
    );

    shopItemsNotifier.value = [];
  }

  void clear() {
    shopItemsNotifier.value = [];
  }
}

class ShopItem {
  int id;
  String name;
  double price;
  String unit;
  String? note;
  int quantity = 1;
  ShopItem(
    this.id,
    this.name,
    this.price,
    this.quantity,
    this.unit, {
    this.note,
  });

  ShopItem copyWith({
    int? id,
    String? name,
    double? price,
    int? quantity,
    String? unit,
    String? note,
  }) {
    return ShopItem(
      id ?? this.id,
      name ?? this.name,
      price ?? this.price,
      quantity ?? this.quantity,
      unit ?? this.unit,
      note: note ?? this.note,
    );
  }
}
