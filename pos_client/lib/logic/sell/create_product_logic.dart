import 'dart:typed_data';

import 'package:pos/logic/sell/product_item.dart';
import 'package:pos/store/model/good/good.dart';
import 'package:pos/store/model/sell/product_providers/product.dart';
import 'package:pos/store/model/sell/product_providers/product_group.dart';

class CreateProductLogic {
  ProductProvider productProvider = ProductProvider();
  GoodProvider goodProvider = GoodProvider();
  Future<void> addNewProduct({
    required ProductGroupItem group,
    required String name,
    required double price,
    required String unit,
    Uint8List? image,
  }) async {
    // Logic to add a new product
    Good good = Good(
      id: 0, // Assuming 0 for new good
      name: name,
      unit: unit,
      image: image,
    );
    int goodId = await goodProvider.insert(good);
    Product product = Product(
      groupId: group.id!,
      goodId: goodId,
      price: price,
      amount: 0,
    );
    productProvider.insert(product);
  }

  void editProduct({
    required ProductItem productItem,
  }) {
    Good good = Good(
      id: productItem.goodId,
      name: productItem.name,
      unit: productItem.unit,
      image: productItem.image,
    );
    Product product = Product(
      groupId: productItem.groupId,
      goodId: productItem.goodId,
      price: productItem.price,
      amount: 0,
    );
    goodProvider.update(good);
    productProvider.update(product);
  }
}
