import 'dart:typed_data';

import 'package:pos/store/model/good/good.dart';
import 'package:pos/store/model/restock/purchased_items.dart';

class PurchasedLogic {
  PurchasedItemProvider purchasedItemProvider = PurchasedItemProvider();
  GoodProvider goodProvider = GoodProvider();
  Future<void> addNewPurchasedItem(PurchasedItemAndGood purchasedItemAndGood) async {
    Good good = Good(
      id: 0,
      name: purchasedItemAndGood.name,
      unit: purchasedItemAndGood.unit,
      image: purchasedItemAndGood.image,
    );
    int goodId = await goodProvider.insert(good);
    PurchasedItem purchasedItem = PurchasedItem(
      goodId: goodId,
      vendorId: purchasedItemAndGood.vendorId,
      amount: 0,
    );
    purchasedItemProvider.insert(purchasedItem);
  }

  Future<void> updatePurchasedItemAndGood(PurchasedItemAndGood purchasedItemAndGood) async {
    Good good = Good(
      id: purchasedItemAndGood.goodId,
      name: purchasedItemAndGood.name,
      unit: purchasedItemAndGood.unit,
      image: purchasedItemAndGood.image,
    );
    PurchasedItem purchasedItem = PurchasedItem(
      goodId: purchasedItemAndGood.goodId,
      vendorId: purchasedItemAndGood.vendorId,
      amount: 0,
    );
    await goodProvider.update(good);
    await purchasedItemProvider.update(purchasedItem);
  }

  Future<List<PurchasedItemAndGood>> convertPurchasedItems2PurchasedItemAndGoods(List<PurchasedItem> purchasedItems) async {
    List<PurchasedItemAndGood> purchasedItemAndGoods = [];
    for (var item in purchasedItems) {
      Good? good = await goodProvider.getItem(item.goodId);
      if (good == null) continue;
      PurchasedItemAndGood purchasedItemAndGood = PurchasedItemAndGood.combinePurchasedItemAndGood(item, good);
      purchasedItemAndGoods.add(purchasedItemAndGood);
    }
    return purchasedItemAndGoods;
  }
}

class PurchasedItemAndGood {
  final int goodId;
  final int vendorId;
  final String name;
  final String unit;
  Uint8List? image;

  PurchasedItemAndGood({
    required this.goodId,
    required this.vendorId,
    required this.name,
    required this.unit,
    this.image,
  });

  factory PurchasedItemAndGood.combinePurchasedItemAndGood(
    PurchasedItem purchasedItem,
    Good good,
  ) {
    return PurchasedItemAndGood(
      goodId: purchasedItem.goodId,
      vendorId: purchasedItem.vendorId,
      name: good.name,
      unit: good.unit,
      image: good.image,
    );
  }

  PurchasedItem toPurchasedItem() {
    return PurchasedItem(
      goodId: goodId,
      vendorId: vendorId,
      amount: 0,
    );
  }

  Good toGood() {
    return Good(
      id: goodId,
      name: name,
      unit: unit,
      image: image,
    );
  }
}
