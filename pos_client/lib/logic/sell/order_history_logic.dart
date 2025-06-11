import 'package:pos/store/model/good/inventory.dart';
import 'package:pos/store/model/sell/order.dart';
import 'package:pos/store/model/sell/sell.dart';

class OrderHistoryLogic {
  final OrderProvider orderProvider = OrderProvider();
  final InventoryProvider inventoryProvider = InventoryProvider();

  void deleteOrder(int orderId, {required List<SellItem> sellItems}) {
    orderProvider.delete(orderId);
    Map<int, double> originalGoods = <int, double>{};
    for (SellItem item in sellItems) {
      originalGoods[item.goodId] = item.quantity.toDouble();
    }
    inventoryProvider.compareNewOldOrder(originalGoods: originalGoods, newGoods: <int, double>{});
  }
}
