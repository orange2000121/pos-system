// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
        orderId,
        shopItemTemp.name,
        shopItemTemp.price,
        shopItemTemp.quantity,
        createAt: createAt,
      );
      sellProvider.insert(item);
      //更新庫存
      Inventory? inventory = await inventoryProvider.getInventoryByGoodId(shopItemTemp.id);
      if (inventory != null) {
        inventory.quantity -= shopItemTemp.quantity;
        await inventoryProvider.update(inventory, mode: Inventory.COMPUTE_MODE);
      } else {
        //如果庫存不存在，則新增庫存
        inventoryProvider.insert(Inventory(goodId: shopItemTemp.id, quantity: -shopItemTemp.quantity.toDouble(), recodeMode: Inventory.CREATE_MODE, recordTime: DateTime.now()));
      }
    }
    shopItemsNotifier.value = [];
  }

  Future editOrder(int orderId, int? customerId, DateTime createAt) async {
    if (shopItemsNotifier.value.isEmpty) return;
    double total = 0;
    for (var i = 0; i < shopItemsNotifier.value.length; i++) {
      total += shopItemsNotifier.value[i].price * shopItemsNotifier.value[i].quantity;
    }
    await orderProvider.update(orderId, OrderItem(total, customerId: customerId, createAt: createAt));
    await sellProvider.deleteByOrderId(orderId);
    for (var i = 0; i < shopItemsNotifier.value.length; i++) {
      SellItem item = SellItem(
        orderId,
        shopItemsNotifier.value[i].name,
        shopItemsNotifier.value[i].price,
        shopItemsNotifier.value[i].quantity,
        createAt: createAt,
      );
      sellProvider.insert(item);
    }
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
}
