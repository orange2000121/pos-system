import 'package:flutter/widgets.dart';
import 'package:pos/store/model/good/bom.dart';
import 'package:pos/store/model/good/good.dart';
import 'package:pos/store/model/good/inventory.dart';

class GoodManageLogic {
  GoodProvider goodProvider = GoodProvider();
  InventoryProvider inventoryProvider = InventoryProvider();

  List<Good> allGoods = [];
  List<Inventory> allInventories = [];
  Map<int, Map<String, dynamic>> allGoodInfo = {};
  Future<Map<int, Map<String, dynamic>>> getAllGoodsInfo() async {
    allGoods = await goodProvider.getAll();
    allInventories = await inventoryProvider.getAll();
    for (var good in allGoods) {
      var inventory = allInventories.firstWhere(
        (inventory) => inventory.goodId == good.id,
        orElse: () => Inventory(
          goodId: good.id,
          quantity: 0,
          recodeMode: Inventory.CREATE_MODE,
          recordTime: DateTime.now(),
        ),
      );
      allGoodInfo[good.id] = {
        'good': good,
        'inventory': inventory,
      };
    }
    return allGoodInfo;
  }
}

class GoodDetailLogic {
  final Good mainGood;
  GoodDetailLogic({required this.mainGood});

  BomProvider bomProvider = BomProvider();
  GoodProvider goodProvider = GoodProvider();
  InventoryProvider inventoryProvider = InventoryProvider();
  ValueNotifier<List<BomAndMaterial>> bomAndMaterialsNotifier = ValueNotifier([]);
  ValueNotifier<double> manufactureQuantityNotifier = ValueNotifier(0);

  List<Good> getAvailableMaterials({
    required List<Good> allGoods,
  }) {
    return allGoods.where((good) => good.id != mainGood.id).toList();
  }

  Future<List<BomAndMaterial>> getBomsByGoodId(int goodId) async {
    var boms = await bomProvider.getItemsByProductId(goodId) ?? [];
    var tempBomAndMaterials = bomAndMaterialsNotifier.value;
    for (var bom in boms) {
      var material = await goodProvider.getItem(bom.materialId);
      if (material != null) {
        tempBomAndMaterials.add(BomAndMaterial(bom: bom, material: material));
      }
    }
    bomAndMaterialsNotifier.value = tempBomAndMaterials;
    return bomAndMaterialsNotifier.value;
  }

  void addBomSetting({required int productId}) {
    BomAndMaterial bomAndMaterial = BomAndMaterial(
      bom: Bom(
        productId: productId,
        materialId: 0,
        quantity: 0,
        createdAt: DateTime.now(),
      ),
      material: Good(
        id: 0,
        name: '',
        unit: '',
        image: null,
      ),
    );
    bomAndMaterialsNotifier.value = List.from(bomAndMaterialsNotifier.value)..add(bomAndMaterial);
  }

  Future<Inventory> safetyGetInventory(int goodId) async {
    Inventory? inventoryOfMaterial = await inventoryProvider.getInventoryByGoodId(goodId);
    if (inventoryOfMaterial == null) {
      inventoryOfMaterial = Inventory(
        goodId: goodId,
        quantity: 0,
        recodeMode: Inventory.CREATE_MODE,
        recordTime: DateTime.now(),
      );
      await inventoryProvider.insert(inventoryOfMaterial);
    }
    return inventoryOfMaterial;
  }

  void manufactureProduct() async {
    //扣除原料數量
    for (BomAndMaterial bomAndMaterial in bomAndMaterialsNotifier.value) {
      double requiredQuantity = bomAndMaterial.bom.quantity * manufactureQuantityNotifier.value;
      Inventory inventoryOfMaterial = await safetyGetInventory(bomAndMaterial.material.id);
      inventoryOfMaterial.quantity -= requiredQuantity;
      inventoryProvider.update(inventoryOfMaterial, mode: Inventory.COMPUTE_MODE);
    }
    //增加產品數量
    Inventory inventoryOfProduct = await safetyGetInventory(mainGood.id);
    inventoryOfProduct.quantity += manufactureQuantityNotifier.value;
    inventoryProvider.update(inventoryOfProduct, mode: Inventory.COMPUTE_MODE);
    //製作數量歸0
    manufactureQuantityNotifier.value = 0;
  }

  void makeInventory(double quantity) async {
    Inventory productInventory = await safetyGetInventory(mainGood.id);
    productInventory.quantity = quantity;
    await inventoryProvider.update(productInventory, mode: Inventory.MANUAL_MODE);
  }
}

class BomDetailLogic {
  ValueNotifier<int> materialSelectorNotifier = ValueNotifier(0);
  BomProvider bomProvider = BomProvider();
  BomAndMaterial mainBomAndMaterial;
  BomDetailLogic({required this.mainBomAndMaterial});

  Future<void> setMaterialSelector({
    required int value,
    required Map<int, Good> allGoodsMap,
    required BomAndMaterial bomAndMaterial,
  }) async {
    materialSelectorNotifier.value = value;
    Good selectedGood = allGoodsMap[value] ?? Good(id: 0, name: '', unit: '');
    bomAndMaterial.material = selectedGood;
    bomAndMaterial.bom.materialId = selectedGood.id;
    if (bomAndMaterial.bom.materialId != 0 && bomAndMaterial.bom.quantity != 0) {
      if (bomAndMaterial.bom.id == 0) {
        bomAndMaterial.bom.id = await bomProvider.insert(bomAndMaterial.bom);
      } else {
        bomProvider.update(bomAndMaterial.bom);
      }
    }
  }

  Future<void> setBomQuantity({
    required double value,
    required BomAndMaterial bomAndMaterial,
  }) async {
    bomAndMaterial.bom.quantity = value;
    if (bomAndMaterial.bom.materialId != 0 && bomAndMaterial.bom.quantity != 0) {
      if (bomAndMaterial.bom.id == 0 || bomAndMaterial.bom.id == null) {
        bomAndMaterial.bom.id = await bomProvider.insert(bomAndMaterial.bom);
      } else {
        bomProvider.update(bomAndMaterial.bom);
      }
    }
  }

  Future<void> deleteBom({
    required Bom bom,
    required ValueNotifier<List<BomAndMaterial>> bomAndMaterialsNotifier,
  }) async {
    await bomProvider.delete(bom.id!);
    bomAndMaterialsNotifier.value = List.from(bomAndMaterialsNotifier.value)..removeWhere((element) => element.bom.id == bom.id);
  }
}

class BomAndMaterial {
  Bom bom;
  Good material;

  BomAndMaterial({
    required this.bom,
    required this.material,
  });
}
