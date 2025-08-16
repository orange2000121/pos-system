import 'dart:typed_data';

import 'package:pos/store/model/good/good.dart';
import 'package:pos/store/model/sell/product_providers/product.dart';

class ProductItem {
  int goodId;
  int groupId;
  String name;
  double price;
  String unit;
  Uint8List? image;
  bool autoCreate;
  int status;
  ProductItem({
    required this.goodId,
    required this.groupId,
    required this.name,
    required this.price,
    required this.unit,
    required this.autoCreate,
    required this.status,
    this.image,
  });
}

class ProductItems {
  List<ProductItem> items = [];

  Future<List<ProductItem>> convertProducts2ProductItems(List<Product> products) async {
    GoodProvider goodProvider = GoodProvider();
    for (var i = 0; i < products.length; i++) {
      Good? good = await goodProvider.getItem(products[i].goodId);
      if (good != null) {
        items.add(ProductItem(
          goodId: products[i].goodId,
          groupId: products[i].groupId,
          name: good.name,
          price: products[i].price,
          unit: good.unit,
          image: good.image,
          autoCreate: products[i].autoCreate,
          status: products[i].status,
        ));
      }
    }
    return items;
  }
}
