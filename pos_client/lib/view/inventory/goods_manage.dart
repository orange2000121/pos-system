import 'package:flutter/material.dart';
import 'package:pos/store/model/good/good.dart';
import 'package:pos/template/routes_page.dart';

class GoodsManage extends StatefulWidget {
  const GoodsManage({super.key});

  @override
  State<GoodsManage> createState() => _GoodsManageState();
}

class _GoodsManageState extends State<GoodsManage> {
  GoodProvider goodProvider = GoodProvider();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: goodProvider.getAll(),
        builder: (context, goodsSnapshot) {
          return RoutesPage(
            pageName: '貨物管理',
            children: [
              RoutesPageCard(icon: const Icon(Icons.cases), name: '添加貨物', page: const Scaffold()),
              if (goodsSnapshot.hasData)
                ...goodsSnapshot.data!.map((e) {
                  return RoutesPageCard(
                    icon: e.image!.isNotEmpty
                        ? SizedBox(
                            width: 70,
                            height: 70,
                            child: Image.memory(
                              e.image!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.cases),
                    name: e.name,
                    page: SizedBox(),
                  );
                }),
            ],
          );
        });
  }
}
