import 'package:pos/store/model/order.dart';
import 'package:pos/store/model/sell.dart';

class BugFixes {
  static void fix_version0_0_2_database() async {
    OrderProvider orderProvider = OrderProvider();
    SellProvider sellProvider = SellProvider();
    List<OrderItem> orders = await orderProvider.getAll();
    for (OrderItem order in orders) {
      List<SellItem> sells = await sellProvider.getItemByOrderId(order.id!);
      double total = 0;
      for (SellItem sell in sells) {
        total += sell.price * sell.quantity;
      }
      if (total == order.totalPrice) continue;
      order.totalPrice = total;
      await orderProvider.update(order.id!, order);
    }
  }
}
