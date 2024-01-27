import 'package:flutter/material.dart';

class ProductCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? image;
  final double width;
  final double height;

  ///可用於展示單個商品的卡片，可自定義圖片、標題、副標題、寬高
  const ProductCard({
    super.key,
    required this.title,
    this.image,
    this.subtitle,
    this.width = 50,
    this.height = 50,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Card(
        child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              children: [
                Align(alignment: Alignment.center, child: widget.image ?? const SizedBox()),
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: constraints.maxWidth,
                    // width: widget.width,
                    color: Colors.black.withOpacity(0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                if (widget.subtitle != null)
                  Positioned(
                    right: 0,
                    child: Container(
                      // width: constraints.maxWidth,
                      color: Colors.black.withOpacity(0.5),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Text(
                          widget.subtitle ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            )),
      );
    });
  }
}
