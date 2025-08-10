import 'package:flutter_test/flutter_test.dart';
import 'package:pos/logic/sell/cashier_logic.dart';

void main() {
  group('CashierLogic', () {
    late CashierLogic cashierLogic;

    setUp(() {
      cashierLogic = CashierLogic();
    });

    test('addItem should add item and update totalPrice', () {
      cashierLogic.addItem(1, 'Test Product', 100.0, 2, 'pcs');
      expect(cashierLogic.shopItems.length, 1);
      expect(cashierLogic.totalPrice, 200.0);
    });

    test('editItem should update quantity', () {
      cashierLogic.addItem(2, 'Another Product', 50.0, 1, 'pcs');
      final item = cashierLogic.shopItems.first;
      cashierLogic.editItem(item, quantity: 5);
      expect(item.quantity, 5);
      expect(cashierLogic.totalPrice, 250.0);
    });

    test('settleAccount should not create order if no items', () async {
      var result = await cashierLogic.settleAccount(123);
      expect(result, isNull);
    });
  });
}
