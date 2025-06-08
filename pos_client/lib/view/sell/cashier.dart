// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, no_leading_underscores_for_local_identifiers

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pos/logic/sell/cashier_logic.dart';
import 'package:pos/logic/sell/product_item.dart';
import 'package:pos/store/sharePreferenes/setting_key.dart';
import 'package:pos/store/sharePreferenes/sharepreference_helper.dart';
import 'package:pos/store/model/sell/customer.dart';
import 'package:pos/store/model/sell/product_providers/product.dart';
import 'package:pos/store/model/sell/product_providers/product_group.dart';
import 'package:pos/store/sharePreferenes/user_info_key.dart';
import 'package:pos/template/button/text_icon_button.dart';
import 'package:pos/template/date_picker.dart';
import 'package:pos/template/number_input_with_increment_decrement.dart';
import 'package:pos/template/product_card.dart';
import 'package:shipment/sample.dart';

class CashierInitData {
  SharedPreferenceHelper sharedPreferenceHelper = SharedPreferenceHelper.instance;
  Future<bool> init() async {
    await sharedPreferenceHelper.init();
    return true;
  }
}

class ShopItemEditData {
  final int customerId;
  final int orderId;
  final List<ShopItem> shopItems;
  final DateTime createAt;
  ShopItemEditData({
    required this.createAt,
    required this.customerId,
    required this.shopItems,
    required this.orderId,
  });
}

/// 收銀員畫面。<br>
/// 如果要編輯訂單，請將 [isEditMode] 設置為 `true`，並傳入 [editShopItems]。
class Cashier extends StatefulWidget {
  final bool isEditMode;
  final ShopItemEditData? editShopItems;
  const Cashier({
    super.key,
    this.isEditMode = false,
    this.editShopItems,
  });

  @override
  State<Cashier> createState() => _CashierState();
}

class _CashierState extends State<Cashier> {
  late CashierLogic cashierLogic;
  CashierInitData cashierInit = CashierInitData();
  late ValueNotifier<int> groupIdNotifier = ValueNotifier(-1); // -1: 全部
  CustomerProvider customerProvider = CustomerProvider();
  ValueNotifier<Customer> customerValueNotifier = ValueNotifier<Customer>(Customer('', '', '', ''));
  DateTime receiptDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    cashierLogic = CashierLogic();
    if (widget.isEditMode && widget.editShopItems == null) {
      throw Exception('editShopItems is null');
    }
    if (widget.isEditMode) {
      cashierLogic.shopItemsNotifier.value = widget.editShopItems!.shopItems.map((item) => item.copyWith()).toList();
      customerProvider.getItem(widget.editShopItems!.customerId).then((value) {
        customerValueNotifier.value = value;
      });
      receiptDate = DateTime(
          widget.editShopItems!.createAt.year, widget.editShopItems!.createAt.month, widget.editShopItems!.createAt.day, widget.editShopItems!.createAt.hour, widget.editShopItems!.createAt.minute);
    } else {
      customerProvider.getAll().then((value) {
        if (value.isNotEmpty) {
          customerValueNotifier.value = value.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: cashierInit.init(),
        builder: (context, cashierInitSnapshot) {
          return Scaffold(
            appBar: AppBar(title: const Text('收銀臺')),
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
                    productList(),
                  ],
                ),
              ),
            ]),
          );
        });
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
              value: cashierInit.sharedPreferenceHelper.setting.getSetting(BoolSettingKey.useReceiptPrinter) ?? false,
              onChanged: (isAvailable) {
                cashierInit.sharedPreferenceHelper.setting.editSetting(isAvailable, BoolSettingKey.useReceiptPrinter);
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
  /// [item] 是一個 [ProductGroupItem] 對象，包含了分類的名稱、ID 和圖片。
  Widget cashierGroupItem(ProductGroupItem item) {
    return InkWell(
      onTap: () => groupIdNotifier.value = item.id!,
      child: SizedBox(
        width: 100,
        child: ProductCard(
          width: 100,
          height: 100,
          title: item.name,
          image: Image.memory(
            // width: 50,
            // height: 50,
            fit: BoxFit.contain,
            item.image ?? Uint8List(0),
            errorBuilder: (context, error, stackTrace) => const FlutterLogo(size: 50),
          ),
          // child: SizedBox(
          //   width: size,
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Image.memory(
          //         width: 50,
          //         height: 50,
          //         fit: BoxFit.contain,
          //         item.image ?? Uint8List(0),
          //         errorBuilder: (context, error, stackTrace) => const FlutterLogo(size: 50),
          //       ),
          //     ],
          //   ),
          // ),
        ),
      ),
    );
  }

  Widget groupList() {
    double size = 100;
    return SizedBox(
      height: size,
      child: FutureBuilder(
        future: ProductGroupProvider().getAll(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Widget> groupListWidgets = [];
            for (var i = 0; i < snapshot.data!.length; i++) {
              groupListWidgets.add(cashierGroupItem(snapshot.data![i]));
            }
            return ListView(
              scrollDirection: Axis.horizontal,
              children: [
                cashierGroupItem(ProductGroupItem('全部', id: -1, image: Uint8List(0))),
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

  Widget cashierProduct(ProductItem item) {
    return InkWell(
      onTap: () async {
        // 新增商品
        ShopItem? tempItem = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text(item.name),
                  content: abacus(ShopItem(item.id, item.name, item.price, 1, item.unit)),
                ));
        if (tempItem == null) return;
        cashierLogic.addItem(tempItem.id, tempItem.name, tempItem.price, tempItem.quantity, tempItem.unit, note: tempItem.note);
      },
      child: ProductCard(
        title: item.name,
        subtitle: '\$${item.price.toString()}',
        image: item.image != null
            ? Image.memory(
                item.image!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const FlutterLogo(size: 50),
              )
            : null,
      ),
    );
  }

  Widget productList() {
    Future<List<ProductItem>> getProductList() async {
      // 取得所有商品，並結合good資料
      List<Product> products = await ProductProvider().getAll();
      return await ProductItems().convertProducts2ProductItems(products);
    }

    return FutureBuilder(
        future: getProductList(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Map<int, List<ProductItem>> groupMap = {};
            for (var i = 0; i < snapshot.data!.length; i++) {
              // 將商品依照分類ID分組
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
                      int productListLength;
                      if (groupId == -1) {
                        productListLength = snapshot.data!.length;
                      } else {
                        productListLength = groupMap[groupId]?.length ?? 0;
                      }
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                        ),
                        itemCount: productListLength,
                        itemBuilder: (context, index) {
                          //如果沒有選擇分類，顯示所有商品
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
    /* -------------------------------- variable -------------------------------- */
    double w = MediaQuery.of(context).size.width;
    TextEditingController quantity = TextEditingController(text: num.toString());
    TextEditingController noteEditingController = TextEditingController(text: item.note);
    TextEditingController discountEditingController = TextEditingController();
    ValueNotifier<List<Widget>> annotationOptions = ValueNotifier(
        [TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: '%off'), controller: discountEditingController)]); // 備註選項
    void finishEdit() {
      item.note = noteEditingController.text;
      if (discountEditingController.text.isNotEmpty) {
        item.price = item.price * (1 - double.parse(discountEditingController.text) / 100);
        item.note = '${item.note}${noteEditingController.text.isEmpty ? '' : ', '}折扣${discountEditingController.text}%';
      }
      Navigator.pop(
          context,
          ShopItem(
            item.id,
            item.name,
            item.price,
            double.parse(quantity.text).toInt(),
            item.unit,
            note: item.note,
          ));
    }

    return SizedBox(
      height: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(
            width: max(400, w * 0.4),
            height: 200,
            child: Row(
              children: [
                Flexible(
                  flex: 1,
                  child: Column(
                    children: [
                      TextIconButton(
                        onPressed: () {
                          annotationOptions.value = [
                            TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: '%off',
                              ),
                              controller: discountEditingController,
                            ),
                          ];
                        },
                        text: '折扣',
                        icon: Icons.arrow_right,
                      ),
                      TextIconButton(
                        onPressed: () {
                          annotationOptions.value = [
                            TextField(
                              controller: noteEditingController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: '備註',
                              ),
                            ),
                          ];
                        },
                        text: '備註',
                        icon: Icons.arrow_right,
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(),
                Expanded(
                  flex: 2,
                  child: ValueListenableBuilder(
                      valueListenable: annotationOptions,
                      builder: (context, options, child) {
                        return GridView(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 150,
                          ),
                          children: options,
                        );
                      }),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  const Text('數量'),
                  const SizedBox(width: 8),
                  NumberInputWithIncrementDecrement(
                    initialNumber: double.parse(quantity.text),
                    onChanged: (value) {
                      quantity.text = value.toString();
                    },
                    onEditingComplete: (number) => finishEdit(),
                  )
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  finishEdit();
                },
                child: const Text('加入'),
              ),
            ],
          ),
        ],
      ),
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
              key: UniqueKey(),
              onDismissed: (direction) {
                cashierLogic.shopItemsNotifier.value.removeAt(index);
                cashierLogic.shopItemsNotifier.notifyListeners();
                // setState(() {});
              },
              child: ListTile(
                leading: Text(shopItems[index].quantity.toString()),
                title: Text(shopItems[index].name),
                subtitle: shopItems[index].note == null ? null : Text(shopItems[index].note!),
                trailing: Text('${shopItems[index].price * shopItems[index].quantity}'),
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
                  if (item != null) cashierLogic.editItem(shopItems[index], quantity: item.quantity);
                },
              ),
            );
          },
        );
      },
    );
  }

  /// 顯示收銀員畫面左側的結帳區域。
  Widget settleAccount() {
    // ValueNotifier<String> receivedCashNotifier = ValueNotifier('');
    double h = MediaQuery.of(context).size.height;
    return Column(
      children: [
        Expanded(
            flex: 4,
            child: Column(
              children: [
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
              ],
            )),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Container(
                // width: 100,
                height: 50,
                alignment: Alignment.center,
                child: Text(
                  widget.isEditMode ? '確認編輯' : '現金結帳',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              onPressed: () async {
                if (!widget.isEditMode) {
                  int? isSettle; // -1: 取消, 其他: 客戶ID
                  if (cashierInit.sharedPreferenceHelper.setting.getSetting(BoolSettingKey.useReceiptPrinter) ?? false) {
                    isSettle = await showDialog(context: context, builder: (context) => receiptOption());
                    if (isSettle == -1) {
                      cashierLogic.clear();
                      // receivedCashNotifier.value = '';
                      return;
                    }
                    if (isSettle == null) return;
                  }
                  // 存入資料庫
                  cashierLogic.settleAccount(isSettle, createAt: receiptDate);
                  //? receivedCashNotifier.value = '';
                } else if (widget.isEditMode && widget.editShopItems != null) {
                  int? isSettle; // -1: 取消, 其他: 客戶ID
                  if (cashierInit.sharedPreferenceHelper.setting.getSetting(BoolSettingKey.useReceiptPrinter) ?? false) {
                    isSettle = await showDialog(context: context, builder: (context) => receiptOption());
                  }
                  if (isSettle == null) return;
                  if (isSettle == -1) {
                    if (!mounted) return;
                    Navigator.pop(context);
                    return;
                  }
                  await cashierLogic.editOrder(
                    orderId: widget.editShopItems!.orderId,
                    originShopItems: widget.editShopItems!.shopItems,
                    customerId: isSettle,
                    createAt: receiptDate,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  //todo 修改庫存
                }
              },
            ),
          ],
        ),
        SizedBox(height: min(15, h * 0.015)),
      ],
    );
  }

  Widget receiptOption() {
    ReceiptSample receiptSample = ReceiptSample(
      userName: '',
      customName: '',
      contactPerson: '',
      phone: '',
      address: '',
      data: const [],
      date: DateTime.now(),
    );
    TextEditingController _name = TextEditingController(), _phone = TextEditingController(), _contactPerson = TextEditingController(), _address = TextEditingController();
    FocusNode _nameFocusNode = FocusNode(), _phoneFocusNode = FocusNode(), _contactPersonFocusNode = FocusNode(), _addressFocusNode = FocusNode();
    List<Customer> customerDropdownItems = [];
    ValueNotifier<bool> showPriceNotifier = ValueNotifier<bool>(true);
    return AlertDialog(
      title: const Text('發票'),
      icon: DatePickerField(
        initialDate: receiptDate,
        onChanged: (date) {
          receiptDate = date ?? DateTime.now();
          receiptSample.date = receiptDate;
          customerValueNotifier.notifyListeners(); // 更新畫面
        },
      ),
      actions: [
        ValueListenableBuilder(
          valueListenable: showPriceNotifier,
          builder: (context, showPrice, child) => Switch(
              value: showPriceNotifier.value,
              thumbIcon: WidgetStateProperty.resolveWith<Icon?>((Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return const Icon(Icons.attach_money);
                }
                return const Icon(Icons.money_off);
              }),
              onChanged: (value) {
                showPriceNotifier.value = value;
                receiptSample.showPrice = value;
              }),
        ),
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
              String formattedDate = '${receiptDate.year}-${receiptDate.month}-${receiptDate.day}-${receiptDate.hour}-${receiptDate.minute}-${receiptDate.second}';
              final file = File('${output.path}/$receiptFolder/$customerName/$customerName$formattedDate.pdf');
              // 最後更新客戶資料
              receiptSample.customName = _name.text;
              receiptSample.contactPerson = _contactPerson.text;
              receiptSample.phone = _phone.text;
              receiptSample.address = _address.text;
              // 更新客戶資料
              if (customerValueNotifier.value.id != null) {
                customerProvider.update(customerValueNotifier.value.id!, customerValueNotifier.value);
              }
              customerValueNotifier.notifyListeners();
              // ignore: await_only_futures
              await receiptSample.updatePdf;
              // pdf存檔
              Uint8List bytes = await receiptSample.pdf.save();
              await file.writeAsBytes(bytes);
              // 列印pdf
              receiptSample.layout();
              Customer? insertCustomer;
              if (customerValueNotifier.value.id == null) {
                insertCustomer = await customerProvider.insert(customerValueNotifier.value);
                customerValueNotifier.value.id = insertCustomer.id;
              }
              if (mounted) Navigator.pop(context, customerValueNotifier.value.id);
            },
            child: const Text('列印')),
        ElevatedButton(
            onPressed: () {
              Navigator.pop(context, -1);
            },
            child: const Text('取消')),
        if (widget.isEditMode)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, customerValueNotifier.value.id);
            },
            child: const Text('完成編輯'),
          ),
      ],
      content: FutureBuilder(
        future: customerProvider.getAll(),
        builder: (context, allCustomerSnapshot) {
          /* -------------------------------- 監聽客戶資料變更 -------------------------------- */
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
          /* --------------------------------- 初始化客戶資料 -------------------------------- */
          customerDropdownItems = allCustomerSnapshot.data ?? [];
          // Replace the customer in the dropdown items if the IDs match
          bool replaceFlag = false;
          customerDropdownItems.add(Customer('新增客戶', '', '', ''));
          for (int i = 0; i < customerDropdownItems.length; i++) {
            if (customerDropdownItems[i].id == customerValueNotifier.value.id) {
              customerDropdownItems[i] = customerValueNotifier.value;
              replaceFlag = true;
              break;
            }
          }
          if (!replaceFlag) {
            customerDropdownItems.add(customerValueNotifier.value);
          }
          /* --------------------------------- 初始購物車資料 -------------------------------- */
          List<SaleItemData> saleItems = [];
          for (var i = 0; i < cashierLogic.shopItemsNotifier.value.length; i++) {
            saleItems.add(
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
          /* --------------------------------- 初始化收據資料 -------------------------------- */
          receiptSample.customName = customerValueNotifier.value.name;
          receiptSample.contactPerson = customerValueNotifier.value.contactPerson;
          receiptSample.phone = customerValueNotifier.value.phone;
          receiptSample.address = customerValueNotifier.value.address;
          receiptSample.data = saleItems;
          _name.text = customerValueNotifier.value.name;
          _phone.text = customerValueNotifier.value.phone;
          _contactPerson.text = customerValueNotifier.value.contactPerson;
          _address.text = customerValueNotifier.value.address;
          /* ----------------------------------- UI ----------------------------------- */
          return Column(
            children: [
              ValueListenableBuilder(
                valueListenable: customerValueNotifier,
                builder: (context, value, child) => DropdownButton<Customer>(
                  value: customerValueNotifier.value, // 選擇的值
                  isDense: true,
                  items: List.generate(customerDropdownItems.length, (index) {
                    return DropdownMenuItem<Customer>(
                      value: customerDropdownItems[index], // 每個選項的值
                      child: Text(customerDropdownItems[index].name),
                    );
                  }),
                  onChanged: (newValue) {
                    customerValueNotifier.value = newValue!;
                    _name.text = newValue.name;
                    _phone.text = newValue.phone;
                    _contactPerson.text = newValue.contactPerson;
                    _address.text = newValue.address;
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
                    valueListenable: showPriceNotifier,
                    builder: (context, showPrice, child) {
                      return ValueListenableBuilder(
                        valueListenable: customerValueNotifier,
                        builder: (context, customer, child) {
                          double? shippingPaperWidth = cashierInit.sharedPreferenceHelper.setting.getDoubleSetting(DoubleSettingKey.shippingPaperWidth);
                          double? shippingPaperHeight = cashierInit.sharedPreferenceHelper.setting.getDoubleSetting(DoubleSettingKey.shippingPaperHeight);
                          PdfPageFormat? pdfPageFormat;
                          if (shippingPaperWidth != null && shippingPaperHeight != null) {
                            pdfPageFormat = PdfPageFormat(shippingPaperWidth * PdfPageFormat.mm, shippingPaperHeight * PdfPageFormat.mm, marginAll: 10 * PdfPageFormat.mm);
                          }
                          receiptSample = ReceiptSample(
                            userName: cashierInit.sharedPreferenceHelper.userInfo.getUserInfo(UserInfoKey.userName) ?? '',
                            customName: customerValueNotifier.value.name,
                            contactPerson: customerValueNotifier.value.contactPerson,
                            phone: customerValueNotifier.value.phone,
                            address: customerValueNotifier.value.address,
                            data: receiptSample.data,
                            pdfPageFormat: pdfPageFormat,
                            showPrice: showPriceNotifier.value,
                            date: receiptDate,
                          );

                          return receiptSample; // 根据新值构建用户界面
                        },
                      );
                    },
                  ))
            ],
          );
        },
      ),
    );
  }
  /* -------------------------------------------------------------------------- */
  /*                                  FUNCTION                                  */
  /* -------------------------------------------------------------------------- */
}
