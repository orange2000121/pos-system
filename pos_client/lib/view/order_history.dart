import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pos/logic/cashier_logic.dart';
import 'package:pos/store/model/customer.dart';
import 'package:pos/store/model/goods.dart';
import 'package:pos/store/model/order.dart';
import 'package:pos/store/model/sell.dart';
import 'package:pos/store/sharePreferenes/setting_key.dart';
import 'package:pos/store/sharePreferenes/sharepreference_helper.dart';
import 'package:pos/store/sharePreferenes/user_info_key.dart';
import 'package:pos/template/data_retrieval_widget.dart';
import 'package:pos/template/date_picker.dart';
import 'package:pos/view/cashier.dart';
import 'package:shipment/sample.dart';

class OrderHistory extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? customerId;
  const OrderHistory({
    super.key,
    this.startDate,
    this.endDate,
    this.customerId,
  });

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  OrderProvider orderProvider = OrderProvider();
  SellProvider sellProvider = SellProvider();
  CustomerProvider customerProvider = CustomerProvider();
  ValueNotifier<DateTime?> startDateNotifier = ValueNotifier(null);
  ValueNotifier<DateTime?> endDateNotifier = ValueNotifier(null);
  int? customerId;
  @override
  void initState() {
    super.initState();
    startDateNotifier.value = widget.startDate;
    endDateNotifier.value = widget.endDate;
    customerId = widget.customerId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: FutureBuilder(
              future: customerProvider.getItem(customerId!),
              builder: (context, AsyncSnapshot<Customer> snapshot) {
                if (snapshot.hasData) {
                  return Text('『${snapshot.data!.name}』歷史訂單');
                } else {
                  return const Text('歷史訂單');
                }
              })),
      body: Column(
        children: [
          filterBar(startDateNotifier: startDateNotifier, endDateNotifier: endDateNotifier, onChanged: () => setState(() {})),
          Expanded(
            child: FutureBuilder(
                future: getOrders(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.2,
                          child: sellOverview(snapshot.data!.values.toList()),
                        ),
                        Expanded(child: ordersListView(snapshot.data!)),
                      ],
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                }),
          ),
        ],
      ),
    );
  }

  Widget sellOverview(List<List<SellItem>> sellItems) {
    Map<String, Map<String, int>> sellMap = {};
    final scrollController = ScrollController();

    for (var element in sellItems) {
      for (var element in element) {
        if (sellMap.containsKey(element.name)) {
          sellMap[element.name] = {
            'quantity': sellMap[element.name]!['quantity']! + element.quantity,
            'totalPrice': sellMap[element.name]!['totalPrice']! + element.price.toInt() * element.quantity,
          };
        } else {
          sellMap[element.name] = {
            'quantity': element.quantity,
            'totalPrice': element.price.toInt() * element.quantity,
          };
        }
      }
    }
    int totalQuantity = 0;
    int totalPrice = 0;
    for (var element in sellMap.values) {
      totalQuantity += element['quantity']!;
      totalPrice += element['totalPrice']!;
    }
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        scrollController.jumpTo(scrollController.offset - details.delta.dx);
      },
      child: Scrollbar(
        controller: scrollController,
        child: ListView(
          scrollDirection: Axis.horizontal,
          controller: scrollController,
          children: sellMap.keys.map((e) {
            return Card(
              child: SizedBox(
                width: (MediaQuery.of(context).size.width * 0.2) > 200 ? MediaQuery.of(context).size.width * 0.2 : 200,
                child: Column(
                  children: [
                    Text(e),
                    Expanded(
                      child: ListView(
                        children: [
                          Text('${(sellMap[e]!['quantity']! / totalQuantity * 100).toStringAsFixed(2)}%' '  ' '銷售數量：${sellMap[e]?['quantity']}'),
                          Text('${(sellMap[e]!['totalPrice']! / totalPrice * 100).toStringAsFixed(2)}%' '  ' '總銷售額：${sellMap[e]?['totalPrice']}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget ordersListView(Map<OrderItem, List<SellItem>> orderMap) {
    return ListView.builder(
      itemCount: orderMap.length,
      itemBuilder: (context, index) {
        List<SellItem> sellItems = orderMap.values.toList()[index];
        OrderItem order = orderMap.keys.toList()[index];
        ValueNotifier editSwitchNotifier = ValueNotifier(false);
        return SmallItemCard(
          title: ValueListenableBuilder(
              valueListenable: editSwitchNotifier,
              builder: (context, isEdit, child) {
                return isEdit
                    ? DatePickerField(
                        selectedDate: order.createAt,
                        onChanged: (date) => order.createAt = date,
                      )
                    : Text(
                        order.createAt.toString().split('.')[0],
                        textAlign: TextAlign.center,
                      );
              }),
          simpleInfo: sellItems.map((e) {
            return Text('${e.name} x${e.quantity}');
          }).toList(),
          detailedInfo: sellItems.map((e) {
            return ValueListenableBuilder(
                valueListenable: editSwitchNotifier,
                builder: (context, value, child) {
                  return ListTile(
                    leading: value
                        ? IconButton(
                            onPressed: () {
                              showDialog(context: context, builder: (context) => editSellItem(context, e));
                            },
                            icon: const Icon(Icons.edit),
                          )
                        : null,
                    title: Text(e.name),
                    subtitle: Text('${e.sugar} ${e.ice}'),
                    trailing: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${e.price} x${e.quantity}'),
                          Text('${e.price * e.quantity}'),
                        ],
                      ),
                    ),
                  );
                });
          }).toList(),
          dialogAction: [
            ElevatedButton(
              onPressed: () async {
                List<ShopItem> shopItems = [];
                for (var element in sellItems) {
                  shopItems.add(ShopItem(
                    element.id!,
                    element.name,
                    element.price,
                    element.quantity,
                    '',
                    ice: element.ice,
                    sugar: element.sugar,
                  ));
                }
                ShopItemEditData shopItemEditData = ShopItemEditData(
                  customerId: order.customerId ?? 0,
                  orderId: order.id!,
                  createAt: order.createAt ?? DateTime.now(),
                  shopItems: shopItems,
                );
                Navigator.of(context).pop();
                await CashierInit(context).initEdit(shopItemEditData);
                setState(() {});
              },
              child: const Text('編輯'),
            ),
            ValueListenableBuilder(
              valueListenable: editSwitchNotifier,
              builder: (context, value, child) => Switch(
                value: editSwitchNotifier.value,
                thumbIcon: MaterialStateProperty.all(const Icon(Icons.edit)),
                onChanged: (value) => editSwitchNotifier.value = value,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                orderProvider.delete(order.id!);
                setState(() {
                  Navigator.of(context).pop();
                });
              },
              child: const Text('刪除', style: TextStyle(color: Colors.red)),
            ),
            ValueListenableBuilder(
              valueListenable: editSwitchNotifier,
              builder: (context, value, child) => ElevatedButton(
                onPressed: value
                    ? () {
                        double totalPrice = 0;
                        for (var element in sellItems) {
                          sellProvider.update(element.id!, element); //更新sellItem
                          totalPrice += element.price * element.quantity;
                        }
                        order.totalPrice = totalPrice;
                        orderProvider.update(order.id!, order);
                        setState(() {
                          Navigator.of(context).pop();
                        });
                      }
                    : () {
                        Navigator.of(context).pop();
                      },
                child: Text(value ? '確認' : '關閉'),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Customer customer = await customerProvider.getItem(customerId!);
                SharedPreferenceHelper sharedPreferenceHelper = SharedPreferenceHelper();
                await sharedPreferenceHelper.init();
                String userName = sharedPreferenceHelper.userInfo.getUserInfo(UserInfoKey.userName) ?? '';
                List<SellItem> sellItemsTemp = await sellProvider.getItemByOrderId(order.id!);
                List<SaleItemData> data = [];
                GoodsProvider goodsProvider = GoodsProvider();

                for (var element in sellItemsTemp) {
                  data.add(SaleItemData(
                    id: element.id!.toString(),
                    name: element.name,
                    num: element.quantity,
                    price: element.price.toInt(),
                    unit: await goodsProvider.getItemByName(element.name).then((value) => value?.unit ?? ''),
                  ));
                }
                if (!context.mounted) return;
                DateTime sellDate = order.createAt ?? DateTime.now();
                String formatSellDate = '${sellDate.year}-${sellDate.month}-${sellDate.day}';
                double? shippingPaperWidth = sharedPreferenceHelper.setting.getDoubleSetting(DoubleSettingKey.shippingPaperWidth);
                double? shippingPaperHeight = sharedPreferenceHelper.setting.getDoubleSetting(DoubleSettingKey.shippingPaperHeight);
                PdfPageFormat? pdfPageFormat;
                CreateReceipt receiptSample;
                if (shippingPaperWidth != null && shippingPaperHeight != null) {
                  pdfPageFormat = PdfPageFormat(shippingPaperWidth * PdfPageFormat.mm, shippingPaperHeight * PdfPageFormat.mm, marginAll: 10 * PdfPageFormat.mm);
                  receiptSample = CreateReceipt(
                    userName: userName,
                    customName: customer.name,
                    contactPerson: customer.contactPerson,
                    phone: customer.phone,
                    address: customer.address,
                    formattedDate: formatSellDate,
                    data: data,
                    pdfPageFormat: pdfPageFormat,
                  );
                } else {
                  receiptSample = CreateReceipt(
                    userName: userName,
                    customName: customer.name,
                    contactPerson: customer.contactPerson,
                    phone: customer.phone,
                    address: customer.address,
                    formattedDate: formatSellDate,
                    data: data,
                  );
                }
                // 建立pdf儲存資料夾
                String receiptFolder = 'receipt';
                String customerName = customer.name;
                final output = await getApplicationDocumentsDirectory();
                if (File('${output.path}/$receiptFolder').existsSync() == false) {
                  Directory('${output.path}/$receiptFolder').createSync();
                }
                if (File('${output.path}/$receiptFolder/$customerName').existsSync() == false) {
                  Directory('${output.path}/$receiptFolder/$customerName').createSync();
                }
                DateTime now = DateTime.now();
                String formattedDate = '${now.year}-${now.month}-${now.day}-${now.hour}-${now.minute}-${now.second}';
                final file = File('${output.path}/$receiptFolder/$customerName/$customerName$formattedDate.pdf');
                // pdf存檔
                Uint8List bytes = await receiptSample.layout().then((value) => value.save());
                await file.writeAsBytes(bytes);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('列印歷史訂單'),
            ),
          ],
          onPop: (popValue) {
            editSwitchNotifier.value = false;
          },
        );
      },
    );
  }

  AlertDialog editSellItem(BuildContext context, SellItem e) {
    return AlertDialog(
      title: const Text('編輯商品紀錄'),
      content: SizedBox(
        width: MediaQuery.of(context).size.height * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: GridView(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: MediaQuery.of(context).size.width * 0.2,
          ),
          children: [
            editCard(context, '商品名稱', e.name, (value) => e.name = value),
            editCard(context, '糖度', e.sugar, (value) => e.sugar = value),
            editCard(context, '冰塊', e.ice, (value) => e.ice = value),
            editCard(context, '數量', e.quantity.toString(), (value) => e.quantity = int.parse(value)),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            // sellProvider.update(e.id!, e);
            setState(() {
              Navigator.of(context).pop();
            });
          },
          child: const Text('確認'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('關閉'),
        ),
      ],
    );
  }

  Card editCard(BuildContext context, String hint, String initialValue, Function(String value) onChanged) {
    return Card(
      color: const Color.fromARGB(188, 184, 156, 184),
      child: Column(
        children: [
          Flexible(
            flex: 2,
            child: Center(child: Text(hint)),
          ),
          Flexible(
            flex: 4,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.08,
              child: TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  fillColor: Color.fromARGB(255, 130, 107, 107),
                ),
                initialValue: initialValue,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<OrderItem, List<SellItem>>> getOrders() async {
    List orders;

    if (customerId != null) {
      orders = await orderProvider.getAllFromCustomerIdAndDateRange(customerId!, startDateNotifier.value ?? DateTime(2000), endDateNotifier.value ?? DateTime(2100));
    } else {
      orders = await orderProvider.getAllFromDateRange(startDateNotifier.value ?? DateTime(2000), endDateNotifier.value ?? DateTime(2100));
    }
    Map<OrderItem, List<SellItem>> orderMap = {};
    for (var i = 0; i < orders.length; i++) {
      orderMap[orders[i]] = await sellProvider.getItemByOrderId(orders[i].id!);
    }
    return orderMap;
  }
}
