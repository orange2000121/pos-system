import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SaleItemData {
  String id;
  String name;
  int num;
  int price;
  String unit;
  String? note;
  SaleItemData({
    required this.id,
    required this.name,
    required this.num,
    required this.price,
    required this.unit,
    this.note,
  });
}

// ignore: must_be_immutable
class ReceiptSample extends StatefulWidget {
  late String userName;
  late String customName;
  late String contactPerson;
  late String phone;
  late String address;
  late double taxRate;
  late List<SaleItemData> data;
  late pw.Document pdf;
  late Function upatePdf;
  late Function layout;

  ///```
  ///const ReceiptSample(
  ///   customName: '中正店',
  ///   phone: '0908811233',
  ///   contactPerson: '許子霆',
  ///   address: '中正路',
  ///   data: [
  ///     {'name': '湯包', 'num': 10, 'price': 500},
  ///     {'name': '大吸管', 'num': 3, 'price': 200},
  ///     {'name': '四顆裝梅餅', 'num': 20, 'price': 50},
  ///   ],
  /// )
  /// ```
  ReceiptSample({
    super.key,
    required this.userName,
    required this.customName,
    required this.contactPerson,
    required this.phone,
    required this.address,
    required this.data,
    this.taxRate = 0,
  });

  @override
  State<ReceiptSample> createState() => _ReceiptSampleState();
}

class _ReceiptSampleState extends State<ReceiptSample> {
  final double textSize = 10, titleSize = 20;
  final int pageNum = 10;

  pw.Widget companyInfo(pw.Font ttf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [pw.Text(widget.userName, style: pw.TextStyle(font: ttf, fontSize: titleSize, height: 0.8, fontBold: pw.Font.timesBold()))]),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [pw.Text('出貨單', style: pw.TextStyle(font: ttf, fontSize: titleSize - 5, height: 0.8))]),
      ],
    );
  }

  pw.Widget customInfo(pw.Font ttf, int page) {
    DateTime now = DateTime.now();
    String formattedDate = "${now.year}-${now.month}-${now.day}";

    return pw.Container(
      // decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('客戶名稱： ${widget.customName}', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('送貨地址： ${widget.address}', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Row(children: [
                pw.Text('聯絡人： ${widget.contactPerson}', style: pw.TextStyle(font: ttf, fontSize: textSize)),
                pw.SizedBox(width: 10),
                pw.Text('電話： ${widget.phone}', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              ]),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('銷貨日期： $formattedDate', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('頁次 $page/${(widget.data.length - 1) ~/ pageNum + 1}', style: pw.TextStyle(font: ttf, fontSize: textSize)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget salesItem(pw.Font ttf, {int page = 1}) {
    return pw.Column(children: [
      pw.Table(
        // border: pw.TableBorder.symmetric(outside: const pw.BorderSide()),
        // columnWidths: {
        //   0: const pw.FlexColumnWidth(6),
        //   1: const pw.FlexColumnWidth(1),
        //   2: const pw.FlexColumnWidth(1),
        //   3: const pw.FlexColumnWidth(2),
        // },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(width: 1),
                top: pw.BorderSide(width: 1),
              ),
            ),
            children: [
              pw.Text('產品編號', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('品名', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('數量', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('單位', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('單價', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('金額', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('備註', style: pw.TextStyle(font: ttf, fontSize: textSize)),
            ],
          ),
          ...widget.data.sublist(min((page - 1) * 10, widget.data.length - 1), min((page - 1) * 10 + 10, widget.data.length)).map((item) {
            int subtotal = item.num * item.price;
            return pw.TableRow(
              children: [
                pw.Text(item.id, style: pw.TextStyle(font: ttf, fontSize: textSize)),
                pw.Text(item.name, style: pw.TextStyle(font: ttf, fontSize: textSize)),
                pw.Text(item.num.toString(), style: pw.TextStyle(font: ttf, fontSize: textSize)),
                pw.Text(item.unit, style: pw.TextStyle(font: ttf, fontSize: textSize)),
                pw.Text(item.price.toString(), style: pw.TextStyle(font: ttf, fontSize: textSize)),
                pw.Text(subtotal.toString(), style: pw.TextStyle(font: ttf, fontSize: textSize)),
                pw.Text(item.note ?? '', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              ],
            );
          }),
        ],
      ),
    ]);
  }

  pw.Widget total(pw.Font ttf) {
    double allPrice = 0;
    for (var item in widget.data) {
      int subtotal = item.num * item.price;
      allPrice += subtotal;
    }
    return pw.Container(
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 1))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('合計： $allPrice', style: pw.TextStyle(font: ttf, fontSize: textSize)),
          pw.Text('稅額： ${allPrice * widget.taxRate}', style: pw.TextStyle(font: ttf, fontSize: textSize)),
          pw.Text('總計： ${allPrice * (1 + widget.taxRate)}', style: pw.TextStyle(font: ttf, fontSize: textSize)),
        ],
      ),
    );
  }

  pw.Widget footer(pw.Font ttf) {
    String signStr = '____________';
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('出貨$signStr', style: pw.TextStyle(font: ttf, fontSize: textSize)),
        pw.Text('會計$signStr', style: pw.TextStyle(font: ttf, fontSize: textSize)),
        pw.Text('倉管$signStr', style: pw.TextStyle(font: ttf, fontSize: textSize)),
        pw.Text('送貨$signStr', style: pw.TextStyle(font: ttf, fontSize: textSize)),
        pw.Text('簽收$signStr', style: pw.TextStyle(font: ttf, fontSize: textSize)),
      ],
    );
  }

  Future<pw.Document> addPage() async {
    final pdf = pw.Document();
    final font = await rootBundle.load("assets/font/NotoSansTC-VariableFont_wght.ttf");
    final ttf = pw.Font.ttf(font);
    for (int i = 0; i < widget.data.length; i += 10) {
      int page = i ~/ pageNum + 1;
      pdf.addPage(pw.Page(
          pageFormat: const PdfPageFormat(240 * PdfPageFormat.mm, 139.7 * PdfPageFormat.mm, marginAll: 10 * PdfPageFormat.mm),
          build: (pw.Context context) {
            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(children: [
                  companyInfo(ttf),
                  customInfo(ttf, page),
                ]),
                pw.Expanded(child: salesItem(ttf, page: page)),
                pw.Column(children: [
                  total(ttf),
                  pw.SizedBox(height: 20),
                  footer(ttf),
                ]),
              ],
            ); // Center
          })); // Page
    }
    return pdf;
  }

  Future<pw.Document> updatePage() async {
    pw.Document pdf = await addPage();
    widget.pdf = pdf;
    return pdf;
  }

  @override
  void initState() {
    super.initState();
    widget.layout = () => Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => widget.pdf.save(),
          format: const PdfPageFormat(21.5 * PdfPageFormat.cm, 14 * PdfPageFormat.cm, marginAll: 1.5 * PdfPageFormat.cm),
        );
  }

  @override
  Widget build(BuildContext context) {
    widget.upatePdf = updatePage;
    return Scaffold(
      body: Center(
        child: PdfPreview(
          useActions: false,
          build: (format) async {
            var pdf = await addPage();
            widget.pdf = pdf;

            return pdf.save();
          },
          onError: (context, error) {
            String errorText = error.toString();
            if (widget.data.isEmpty) {
              errorText = '資料不可為空';
            }
            return Center(
              child: Text(
                errorText,
                style: const TextStyle(color: Colors.red),
              ),
            );
          },
        ),
      ),
    );
  }
}
