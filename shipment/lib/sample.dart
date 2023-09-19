import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ignore: must_be_immutable
class ReceiptSample extends StatefulWidget {
  late String customName;
  late String contactPerson;
  late String phone;
  late String address;
  late List<Map<String, dynamic>> data;
  late pw.Document pdf;
  late Function upatePdf;

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
    required this.customName,
    required this.contactPerson,
    required this.phone,
    required this.address,
    required this.data,
  });

  @override
  State<ReceiptSample> createState() => _ReceiptSampleState();
}

class _ReceiptSampleState extends State<ReceiptSample> {
  final double textSize = 10, titleSize = 24;
  pw.Widget companyInfo(pw.Font ttf) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: [
        pw.Column(
          children: [
            pw.Text('一朵花', style: pw.TextStyle(font: ttf, fontSize: titleSize, fontBold: pw.Font.timesBold())),
            pw.Row(children: [
              pw.Text('電話： 0975-203-230', style: pw.TextStyle(font: ttf, fontSize: textSize)),
            ]),
            pw.Row(children: [
              pw.Text('電話： 0975-203-230', style: pw.TextStyle(font: ttf, fontSize: textSize)),
            ]),
          ],
        ),
      ],
    );
  }

  pw.Widget customInfo(pw.Font ttf) {
    DateTime now = DateTime.now();
    String formattedDate = "${now.year}-${now.month}-${now.day}";

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('客戶名稱： ${widget.customName}', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('聯絡人： ${widget.contactPerson}', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('電話： ${widget.phone}', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('送貨地址： ${widget.address}', style: pw.TextStyle(font: ttf, fontSize: textSize)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('銷貨日期： $formattedDate', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('銷貨單號： ', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('發票日期： ', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('發票編號： ', style: pw.TextStyle(font: ttf, fontSize: textSize)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget salesItem(pw.Font ttf) {
    double allPrice = 0;
    return pw.Column(children: [
      pw.Table(
        border: pw.TableBorder.symmetric(outside: const pw.BorderSide()),
        columnWidths: {
          0: const pw.FlexColumnWidth(6),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            children: [
              pw.Text('品項', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('單價', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('數量', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Text('總價', style: pw.TextStyle(font: ttf, fontSize: textSize)),
            ],
          ),
          ...widget.data.map((item) {
            int subtotal = item['num'] * item['price'];
            allPrice += subtotal;
            return pw.TableRow(
              children: [
                pw.Text(item['name'], style: pw.TextStyle(font: ttf, fontSize: textSize)),
                pw.Text(item['price'].toString(), style: pw.TextStyle(font: ttf, fontSize: textSize)),
                pw.Text(item['num'].toString(), style: pw.TextStyle(font: ttf, fontSize: textSize)),
                pw.Text(subtotal.toString(), style: pw.TextStyle(font: ttf, fontSize: textSize)),
              ],
            );
          }),
        ],
      ),
      pw.Table(
        border: pw.TableBorder.all(),
        columnWidths: {
          0: const pw.FlexColumnWidth(6),
          1: const pw.FlexColumnWidth(4),
        },
        children: [
          pw.TableRow(
            children: [
              pw.Text('備註：', style: pw.TextStyle(font: ttf, fontSize: textSize)),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(children: [pw.Text('合計金額', style: pw.TextStyle(font: ttf, fontSize: textSize)), pw.Text(allPrice.toString(), style: pw.TextStyle(font: ttf, fontSize: textSize))]),
                  pw.TableRow(children: [pw.Text('稅額', style: pw.TextStyle(font: ttf, fontSize: textSize)), pw.Text('0', style: pw.TextStyle(font: ttf, fontSize: textSize))]),
                  pw.TableRow(children: [pw.Text('總金額', style: pw.TextStyle(font: ttf, fontSize: textSize)), pw.Text(allPrice.toString(), style: pw.TextStyle(font: ttf, fontSize: textSize))]),
                ],
              ),
            ],
          )
        ],
      )
    ]);
  }

  Future<pw.Document> addPage() async {
    final pdf = pw.Document();
    final font = await rootBundle.load("assets/font/NotoSansTC-VariableFont_wght.ttf");
    final ttf = pw.Font.ttf(font);
    pdf.addPage(pw.Page(
        pageFormat: const PdfPageFormat(24.5 * PdfPageFormat.cm, 14 * PdfPageFormat.cm, marginAll: 1.5 * PdfPageFormat.cm),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              companyInfo(ttf),
              customInfo(ttf),
              salesItem(ttf),
            ],
          ); // Center
        })); // Page
    return pdf;
  }

  Future<pw.Document> updatePage() async {
    pw.Document pdf = await addPage();
    widget.pdf = pdf;
    return pdf;
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
            }),
      ),
    );
  }
}
