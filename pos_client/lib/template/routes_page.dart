import 'package:flutter/material.dart';

class RoutesPageCard {
  String name;
  Widget? icon;
  Widget page;
  RoutesPageCard({required this.name, this.icon, required this.page});
}

class RoutesPage extends StatefulWidget {
  final String? pageName;
  final List<RoutesPageCard> children;

  ///集合要到的路由的頁面
  const RoutesPage({super.key, this.pageName, required this.children});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageName ?? ''),
      ),
      body: GridView(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
        ),
        children: widget.children.map((e) {
          return InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => e.page));
            },
            child: Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  e.icon ?? const SizedBox(),
                  Text(e.name),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
