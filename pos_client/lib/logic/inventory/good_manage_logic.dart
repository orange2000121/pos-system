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
    print('good count: ${allGoods.length}');
    print('inventory count: ${allInventories.length}');
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
  BomProvider bomProvider = BomProvider();
  GoodProvider goodProvider = GoodProvider();
  ValueNotifier<List<BomAndMaterial>> bomAndMaterialsNotifier = ValueNotifier([]);
  final Good mainGood;
  GoodDetailLogic({required this.mainGood});

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

  Future addBom(Bom bom) async {
    await bomProvider.insert(bom);
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
