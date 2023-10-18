// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, no_leading_underscores_for_local_identifiers

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pos/logic/cashier_logic.dart';
import 'package:pos/store/sharePreferenes/setting_key.dart';
import 'package:pos/store/sharePreferenes/sharepreference_helper.dart';
import 'package:pos/store/model/customer.dart';
import 'package:pos/store/model/goods.dart';
import 'package:pos/store/model/goods_group.dart';
import 'package:pos/store/sharePreferenes/user_info_key.dart';
import 'package:printing/printing.dart';
import 'package:shipment/sample.dart';

class CashierInit {
  SharedPreferenceHelper sharedPreferenceHelper = SharedPreferenceHelper.instance;
  final BuildContext context;
  CashierInit(this.context);
  Future<bool> init() async {
    await sharedPreferenceHelper.init();
    if (!context.mounted) return false;
    Navigator.push(context, MaterialPageRoute(builder: (context) => Cashier(init: this)));
    return true;
  }
}

class Cashier extends StatefulWidget {
  final CashierInit init;
  const Cashier({
    super.key,
    required this.init,
  });

  @override
  State<Cashier> createState() => _CashierState();
}

class _CashierState extends State<Cashier> {
  late CashierLogic cashierLogic;
  late ValueNotifier<int> groupIdNotifier = ValueNotifier(-1); // -1: 全部
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
      child: ListView(children: [
        ListTile(
          title: const Text('開立收據'),
          trailing: Switch(
              value: widget.init.sharedPreferenceHelper.setting.getSetting(BoolSettingKey.useReceiptPrinter) ?? false,
              onChanged: (isAvailable) {
                widget.init.sharedPreferenceHelper.setting.editSetting(isAvailable, BoolSettingKey.useReceiptPrinter);
                setState(() {});
              }),
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
      onTap: () async {
        // 新增商品
        ShopItem? tempItem = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text(item.name),
                  content: abacus(ShopItem(item.id ?? -1, item.name, item.price, 1, item.unit)),
                ));
        if (tempItem == null) return;
        cashierLogic.addItem(tempItem.id, tempItem.name, tempItem.price, tempItem.ice ?? '', tempItem.sugar ?? '', tempItem.quantity, tempItem.unit, note: tempItem.note);
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
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
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

  Widget abacus(ShopItem item, {int num = 1, String ice = '', String sugar = ''}) {
    List<Widget> sugarChoseWidgets = [];
    List<Widget> iceChoseWidgets = [];
    List<String> sugarList = ['正常糖', '少糖', '半糖', '微糖', '無糖'];
    List<String> iceList = ['正常冰', '少冰', '半冰', '微冰', '去冰'];
    String chosenSugar = sugar, chosenIce = ice;
    TextEditingController quantity = TextEditingController(text: num.toString());
    TextEditingController noteEditingController = TextEditingController(text: item.note);
    for (var i = 0; i < sugarList.length; i++) {
      sugarChoseWidgets.add(ElevatedButton(
        onPressed: () {
          chosenSugar = sugarList[i];
        },
        child: Text(sugarList[i]),
      ));
    }
    for (var i = 0; i < iceList.length; i++) {
      iceChoseWidgets.add(ElevatedButton(
        onPressed: () {
          chosenIce = iceList[i];
        },
        child: Text(iceList[i]),
      ));
    }
    return Column(
      children: [
        const Text('糖度'),
        Row(children: sugarChoseWidgets),
        const Text('冰塊'),
        Row(children: iceChoseWidgets),
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
              height: 60,
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
        TextField(
          controller: noteEditingController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '備註',
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
                context,
                ShopItem(
                  item.id,
                  item.name,
                  item.price,
                  int.parse(quantity.text),
                  item.unit,
                  ice: chosenIce,
                  sugar: chosenSugar,
                  note: noteEditingController.text,
                ));
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
            return Dismissible(
              key: Key(shopItems[index].name),
              onDismissed: (direction) {
                cashierLogic.shopItemsNotifier.value.removeAt(index);
                cashierLogic.shopItemsNotifier.notifyListeners();
              },
              child: ListTile(
                title: Text(shopItems[index].name),
                subtitle: Text('${shopItems[index].ice} ${shopItems[index].sugar}'),
                trailing: Text(shopItems[index].quantity.toString()),
                onTap: () async {
                  ShopItem? item = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: Text(shopItems[index].name),
                            content: abacus(
                              shopItems[index],
                              num: shopItems[index].quantity,
                            ),
                          ));
                  if (item != null) cashierLogic.editItem(shopItems[index], ice: item.ice, sugar: item.sugar, quantity: item.quantity);
                },
              ),
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
                      int? isSettle;
                      if (widget.init.sharedPreferenceHelper.setting.getSetting(BoolSettingKey.useReceiptPrinter) ?? false) {
                        isSettle = await showDialog(context: context, builder: (context) => receiptOption());
                      }
                      if (isSettle != -1) {
                        cashierLogic.customerId = isSettle;
                        cashierLogic.settleAccount();
                        receivedCashNotifier.value = '';
                      }
                      if (isSettle == -1) {
                        cashierLogic.clear();
                        receivedCashNotifier.value = '';
                      }
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
    ReceiptSample receiptSample = ReceiptSample(userName: '', customName: '', contactPerson: '', phone: '', address: '', data: const []);
    TextEditingController _name = TextEditingController(), _phone = TextEditingController(), _contactPerson = TextEditingController(), _address = TextEditingController();
    FocusNode _nameFocusNode = FocusNode(), _phoneFocusNode = FocusNode(), _contactPersonFocusNode = FocusNode(), _addressFocusNode = FocusNode();
    List dropdownItems = [];
    return AlertDialog(
      actions: [
        ElevatedButton(
            onPressed: () async {
              String receiptFolder = 'receipt';
              String customerName = _name.text;
              // 建立pdf儲存資料夾
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
              // 最後更新客戶資料
              receiptSample.customName = _name.text;
              receiptSample.contactPerson = _contactPerson.text;
              receiptSample.phone = _phone.text;
              receiptSample.address = _address.text;
              // 更新客戶資料
              customerProvider.update(customerValueNotifier.value.id!, customerValueNotifier.value);
              customerValueNotifier.notifyListeners();
              await receiptSample.upatePdf();
              // pdf存檔
              Uint8List bytes = await receiptSample.pdf.save();
              await file.writeAsBytes(bytes);
              // 列印pdf
              Printing.layoutPdf(
                onLayout: (PdfPageFormat format) async => bytes,
                format: const PdfPageFormat(21.5 * PdfPageFormat.cm, 14 * PdfPageFormat.cm, marginAll: 1.5 * PdfPageFormat.cm),
                usePrinterSettings: true,
              );
              Customer? insertCustomer;
              if (customerValueNotifier.value.id == null) {
                insertCustomer = await customerProvider.insert(customerValueNotifier.value);
                customerValueNotifier.value.id = insertCustomer.id;
              }
              if (context.mounted) Navigator.pop(context, customerValueNotifier.value.id);
            },
            child: const Text('列印')),
        ElevatedButton(
            onPressed: () {
              Navigator.pop(context, -1);
            },
            child: const Text('取消')),
      ],
      title: const Text('發票'),
      content: Column(
        children: [
          FutureBuilder(
            future: customerProvider.getAll(),
            builder: (context, snapshot) {
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
              List<SaleItemData> data = [];
              for (var i = 0; i < cashierLogic.shopItemsNotifier.value.length; i++) {
                data.add(
                  SaleItemData(
                    id: cashierLogic.shopItemsNotifier.value[i].id.toString(),
                    name: cashierLogic.shopItemsNotifier.value[i].name,
                    price: cashierLogic.shopItemsNotifier.value[i].price.toInt(),
                    num: cashierLogic.shopItemsNotifier.value[i].quantity.toInt(),
                    unit: cashierLogic.shopItemsNotifier.value[i].unit,
                    note: cashierLogic.shopItemsNotifier.value[i].note,
                  ),
                );
              }
              receiptSample.customName = dropdownItems.first.name;
              receiptSample.contactPerson = dropdownItems.first.contactPerson;
              receiptSample.phone = dropdownItems.first.phone;
              receiptSample.address = dropdownItems.first.address;
              receiptSample.data = data;
              _name.text = customerValueNotifier.value.name;
              _phone.text = customerValueNotifier.value.phone;
              _contactPerson.text = customerValueNotifier.value.contactPerson;
              _address.text = customerValueNotifier.value.address;
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
                      width: MediaQuery.of(context).size.height * 0.6,
                      child: ValueListenableBuilder(
                        valueListenable: customerValueNotifier,
                        builder: (context, value, child) {
                          receiptSample = ReceiptSample(
                              userName: widget.init.sharedPreferenceHelper.userInfo.getUserInfo(UserInfoKey.userName) ?? '',
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
