// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, no_leading_underscores_for_local_identifiers

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos/logic/cashier_logic.dart';
import 'package:pos/model/customer.dart';
import 'package:pos/model/goods.dart';
import 'package:pos/model/goods_group.dart';
import 'package:shipment/sample.dart';

class Cashier extends StatefulWidget {
  const Cashier({super.key});

  @override
  State<Cashier> createState() => _CashierState();
}

class _CashierState extends State<Cashier> {
  late CashierLogic cashierLogic;
  late ValueNotifier<int> groupIdNotifier = ValueNotifier(-1); // -1: 全部
  Map<String, dynamic> setting = {
    'receipt': false,
  };
  @override
  void initState() {
    super.initState();
    cashierLogic = CashierLogic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cashier')),
      endDrawer: drawer(),
      body: Row(children: [
        Expanded(
          flex: 1,
          child: Column(children: [
            Expanded(flex: 3, child: shoppingCart()),
            const Divider(),
            Expanded(flex: 2, child: settleAccount()),
          ]),
        ),
        const VerticalDivider(),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              groupList(),
              const Divider(),
              goodsList(),
            ],
          ),
        ),
      ]),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                   Widget                                   */
  /* -------------------------------------------------------------------------- */
  Widget drawer() {
    return Drawer(
      child: Column(children: [
        Row(
          children: [
            const Text('開立收據'),
            Switch(
                value: setting['receipt'],
                onChanged: (isAvailable) {
                  setting['receipt'] = isAvailable;
                  setState(() {});
                }),
          ],
        )
      ]),
    );
  }

  /// 顯示收銀員畫面左側的商品分類列表中的一個分類項目。
  ///
  /// 這個 widget 會顯示一個卡片，包含商品分類的圖片和名稱。
  /// 當用戶點擊這個項目時，會通過 [groupIdNotifier] 通知父 widget，以便更新商品列表。
  ///
  /// [item] 是一個 [GoodsGroupItem] 對象，包含了分類的名稱、ID 和圖片。
  Widget cashierGroupItem(GoodsGroupItem item) {
    double size = 100;
    return InkWell(
      onTap: () => groupIdNotifier.value = item.id!,
      child: Card(
        child: SizedBox(
          width: size,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.memory(
                width: 50,
                height: 50,
                fit: BoxFit.contain,
                item.image ?? Uint8List(0),
                errorBuilder: (context, error, stackTrace) => const FlutterLogo(size: 50),
              ),
              Text(item.name),
            ],
          ),
        ),
      ),
    );
  }

  Widget groupList() {
    double size = 100;
    return SizedBox(
      height: size,
      child: FutureBuilder(
        future: GoodsGroupProvider().getAll(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Widget> groupListWidgets = [];
            for (var i = 0; i < snapshot.data!.length; i++) {
              groupListWidgets.add(cashierGroupItem(snapshot.data![i]));
            }
            return ListView(
              scrollDirection: Axis.horizontal,
              children: [
                cashierGroupItem(GoodsGroupItem('全部', id: -1, image: Uint8List(0))),
                ...groupListWidgets,
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget cashierProduct(Good item) {
    return InkWell(
      onTap: () {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text(item.name),
                  content: abacus(item.name, item.price),
                ));
      },
      child: Card(
          child: SizedBox(
        width: 80,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.name),
            Text(item.price.toString()),
            SizedBox(
              width: 80,
              height: 80,
              child: Image.memory(
                item.image!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const FlutterLogo(size: 50),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget goodsList() {
    return FutureBuilder(
        future: GoodsProvider().getAll(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Map<int, List<Good>> groupMap = {};
            for (var i = 0; i < snapshot.data!.length; i++) {
              if (groupMap.containsKey(snapshot.data![i].groupId)) {
                groupMap[snapshot.data![i].groupId]!.add(snapshot.data![i]);
              } else {
                groupMap[snapshot.data![i].groupId] = [snapshot.data![i]];
              }
            }
            return Expanded(
                child: ValueListenableBuilder(
                    valueListenable: groupIdNotifier,
                    builder: (context, groupId, child) {
                      int goodListLength;
                      if (groupId == -1) {
                        goodListLength = snapshot.data!.length;
                      } else {
                        goodListLength = groupMap[groupId]?.length ?? 0;
                      }
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                        ),
                        itemCount: goodListLength,
                        itemBuilder: (context, index) {
                          if (groupId == -1) {
                            return cashierProduct(snapshot.data![index]);
                          } else {
                            return cashierProduct(groupMap[groupId]![index]);
                          }
                        },
                      );
                    }));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Widget abacus(String name, double price, {int num = 1, Function? onFinished}) {
    List<Widget> sugar = [];
    List<Widget> ice = [];
    List<String> sugarList = ['正常糖', '少糖', '半糖', '微糖', '無糖'];
    List<String> iceList = ['正常冰', '少冰', '半冰', '微冰', '去冰'];
    String chosenSugar = '', chosenIce = '';
    TextEditingController quantity = TextEditingController(text: num.toString());
    for (var i = 0; i < sugarList.length; i++) {
      sugar.add(ElevatedButton(
        onPressed: () {
          chosenSugar = sugarList[i];
        },
        child: Text(sugarList[i]),
      ));
    }
    for (var i = 0; i < iceList.length; i++) {
      ice.add(ElevatedButton(
        onPressed: () {
          chosenIce = iceList[i];
        },
        child: Text(iceList[i]),
      ));
    }
    return Column(
      children: [
        const Text('糖度'),
        Row(children: sugar),
        const Text('冰塊'),
        Row(children: ice),
        const Text('數量'),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                if (int.parse(quantity.text) > 1) {
                  quantity.text = (int.parse(quantity.text) - 1).toString();
                }
              },
              child: const Text('-'),
            ),
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.all(10),
              child: TextField(
                keyboardType: TextInputType.number,
                controller: quantity,
                onTap: () => quantity.value = TextEditingValue.empty,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                quantity.text = (int.parse(quantity.text) + 1).toString();
              },
              child: const Text('+'),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () {
            if (onFinished == null) {
              cashierLogic.addItem(name, price, chosenIce, chosenSugar, int.parse(quantity.text));
            } else {
              onFinished();
            }
            Navigator.pop(context, ShopItem(name, price, chosenIce, chosenSugar, int.parse(quantity.text)));
          },
          child: const Text('確定'),
        ),
      ],
    );
  }

  /// 所有點餐項目的列表。
  Widget shoppingCart() {
    return ValueListenableBuilder(
      valueListenable: cashierLogic.shopItemsNotifier,
      builder: (context, shopItems, child) {
        return ListView.builder(
          itemCount: shopItems.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(shopItems[index].name),
              subtitle: Text('${shopItems[index].ice} ${shopItems[index].sugar}'),
              trailing: Text(shopItems[index].quantity.toString()),
              onTap: () async {
                ShopItem item = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                          title: Text(shopItems[index].name),
                          content: abacus(
                            shopItems[index].name,
                            shopItems[index].price,
                            num: shopItems[index].quantity,
                          ),
                        ));
              },
            );
          },
        );
      },
    );
  }

  Widget settleAccount() {
    ValueNotifier<String> receivedCashNotifier = ValueNotifier('');

    return Row(
      children: [
        Expanded(
            flex: 1,
            child: Column(
              children: [
                // Row(
                //   children: [
                //     Text('實收現金'),
                //     ValueListenableBuilder(
                //         valueListenable: receivedCashNotifier,
                //         builder: (context, receivedCash, child) {
                //           return Text(receivedCash);
                //         }),
                //   ],
                // ),
                Row(
                  children: [
                    const Text('總價'),
                    ValueListenableBuilder(
                        valueListenable: cashierLogic.totalPriceNotifier,
                        builder: (context, totalPrice, child) {
                          return Text(totalPrice.toString());
                        }),
                  ],
                ),
                // Row(
                //   children: [
                //     const Text('找零'),
                //     ValueListenableBuilder(
                //         valueListenable: receivedCashNotifier,
                //         builder: (context, receivedCash, child) {
                //           double change;
                //           if (receivedCash.isEmpty)
                //             change = 0;
                //           else
                //             change = double.parse(receivedCash) - cashierLogic.totalPrice;
                //           return Text(change.toString());
                //         }),
                //   ],
                // ),
              ],
            )),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Expanded(
              //   child: GridView(
              //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
              //     children: [
              //       for (var i = 1; i <= 9; i++)
              //         ElevatedButton(
              //           onPressed: () {
              //             receivedCashNotifier.value += i.toString();
              //           },
              //           child: Text(i.toString()),
              //         ),
              //       ElevatedButton(
              //         onPressed: () {
              //           receivedCashNotifier.value += '0';
              //         },
              //         child: const Text('0'),
              //       ),
              //       ElevatedButton(
              //         onPressed: () {
              //           receivedCashNotifier.value = '';
              //         },
              //         child: const Text('C'),
              //       ),
              //     ],
              //   ),
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (setting['receipt']) {
                        await showDialog(context: context, builder: (context) => receiptOption());
                      }
                      cashierLogic.settleAccount();
                      receivedCashNotifier.value = '';
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      alignment: Alignment.center,
                      child: const Text(
                        '現金\n結帳',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget receiptOption() {
    CustomerProvider customerProvider = CustomerProvider();
    ValueNotifier<Customer> customerValueNotifier = ValueNotifier<Customer>(Customer('', '', '', ''));
    ReceiptSample receiptSample = ReceiptSample(customName: '', contactPerson: '', phone: '', address: '', data: const []);
    TextEditingController _name = TextEditingController(), _phone = TextEditingController(), _contactPerson = TextEditingController(), _address = TextEditingController();
    FocusNode _nameFocusNode = FocusNode(), _phoneFocusNode = FocusNode(), _contactPersonFocusNode = FocusNode(), _addressFocusNode = FocusNode();
    List dropdownItems = [];
    return AlertDialog(
      actions: [
        ElevatedButton(
            onPressed: () async {
              Navigator.pop(context, true);
              final output = await getDownloadsDirectory();
              final file = File("${output?.path}/example.pdf");
              while (true) {
                try {
                  await file.writeAsBytes(await receiptSample.pdf.save());
                  break;
                } catch (e) {}
              }

              if (!await customerProvider.isExist(customerValueNotifier.value.name)) {
                await customerProvider.insert(customerValueNotifier.value);
              }
            },
            child: const Text('列印')),
        ElevatedButton(
            onPressed: () {
              Navigator.pop(context, false);
              customerProvider.deleteAll();
            },
            child: const Text('取消')),
      ],
      title: const Text('發票'),
      content: Column(
        children: [
          FutureBuilder(
            future: customerProvider.getAll(),
            builder: (context, snapshot) {
              // customerValueNotifier.value = (snapshot.data!.isNotEmpty ? snapshot.data?.first : Customer('', '', '', '')) ?? Customer('', '', '', '');
              _name.text = customerValueNotifier.value.name;
              _phone.text = customerValueNotifier.value.phone;
              _contactPerson.text = customerValueNotifier.value.contactPerson;
              _address.text = customerValueNotifier.value.address;
              _nameFocusNode.addListener(() {
                if (!_nameFocusNode.hasFocus) {
                  customerValueNotifier.value.name = _name.text;
                  receiptSample.customName = _name.text;
                  customerValueNotifier.notifyListeners();
                }
              });
              _phoneFocusNode.addListener(() {
                if (!_phoneFocusNode.hasFocus) {
                  customerValueNotifier.value.phone = _phone.text;
                  receiptSample.phone = _phone.text;
                  customerValueNotifier.notifyListeners();
                }
              });
              _contactPersonFocusNode.addListener(() {
                if (!_contactPersonFocusNode.hasFocus) {
                  customerValueNotifier.value.contactPerson = _contactPerson.text;
                  receiptSample.contactPerson = _contactPerson.text;
                  customerValueNotifier.notifyListeners();
                }
              });
              _addressFocusNode.addListener(() {
                if (!_addressFocusNode.hasFocus) {
                  customerValueNotifier.value.address = _address.text;
                  receiptSample.address = _address.text;
                  customerValueNotifier.notifyListeners();
                }
              });

              dropdownItems = snapshot.data ?? [];
              dropdownItems.add(Customer('新增客戶', '', '', ''));
              customerValueNotifier.value = dropdownItems.first;
              List<Map<String, dynamic>> data = [];
              for (var i = 0; i < cashierLogic.shopItemsNotifier.value.length; i++) {
                data.add({
                  'name': cashierLogic.shopItemsNotifier.value[i].name,
                  'num': cashierLogic.shopItemsNotifier.value[i].quantity.toInt(),
                  'price': cashierLogic.shopItemsNotifier.value[i].price.toInt(),
                });
              }
              receiptSample.customName = dropdownItems.first.name;
              receiptSample.contactPerson = dropdownItems.first.contactPerson;
              receiptSample.phone = dropdownItems.first.phone;
              receiptSample.address = dropdownItems.first.address;
              receiptSample.data = data;
              return Column(
                children: [
                  ValueListenableBuilder(
                    valueListenable: customerValueNotifier,
                    builder: (context, value, child) => DropdownButton<Customer>(
                      value: customerValueNotifier.value, // 選擇的值
                      isDense: true,
                      items: List.generate(dropdownItems.length, (index) {
                        return DropdownMenuItem<Customer>(
                          value: dropdownItems[index], // 每個選項的值
                          child: Text(dropdownItems[index].name),
                        );
                      }),
                      onChanged: (newValue) {
                        setState(() {
                          customerValueNotifier.value = newValue!;
                          _name.text = newValue.name;
                          _phone.text = newValue.phone;
                          _contactPerson.text = newValue.contactPerson;
                          _address.text = newValue.address;
                        });
                        print((customerValueNotifier.value));
                      },
                    ),
                  ),
                  Table(
                    children: [
                      TableRow(children: [
                        TextFormField(
                          decoration: const InputDecoration(hintText: '客戶名稱'),
                          controller: _name,
                          focusNode: _nameFocusNode,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(hintText: '電話'),
                          controller: _phone,
                          focusNode: _phoneFocusNode,
                        ),
                      ]),
                      TableRow(children: [
                        TextFormField(
                          decoration: const InputDecoration(hintText: '聯絡人'),
                          controller: _contactPerson,
                          focusNode: _contactPersonFocusNode,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(hintText: '地址'),
                          controller: _address,
                          focusNode: _addressFocusNode,
                        ),
                      ])
                    ],
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      width: MediaQuery.of(context).size.height * 0.3,
                      child: ValueListenableBuilder(
                        valueListenable: customerValueNotifier,
                        builder: (context, value, child) {
                          print('recepid: ${receiptSample.customName}');
                          receiptSample = ReceiptSample(
                              customName: customerValueNotifier.value.name,
                              contactPerson: customerValueNotifier.value.contactPerson,
                              phone: customerValueNotifier.value.phone,
                              address: customerValueNotifier.value.address,
                              data: receiptSample.data);
                          return receiptSample; // 根据新值构建用户界面
                        },
                      ))
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
