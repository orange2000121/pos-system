import 'package:pos/store/model/sell/order.dart';

class OrderHistoryLogic {
  final OrderProvider orderProvider = OrderProvider();

  void deleteOrder(int orderId) {
    orderProvider.delete(orderId);
  }
}
