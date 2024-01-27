import 'package:flutter/material.dart';

class TagsGridViewTag {
  final String name;
  final Color color;
  final Function? onDeleted;
  final bool showDeleteIcon;
  final Function()? onTap;
  const TagsGridViewTag({
    required this.name,
    required this.color,
    this.onDeleted,
    this.showDeleteIcon = true,
    this.onTap,
  });
}

class TagsGridView extends StatefulWidget {
  final List<TagsGridViewTag> tags;
  final Function(List<TagsGridViewTag> tags)? onChanged;

  ///可用於展示多個標籤的網格
  const TagsGridView({super.key, required this.tags, this.onChanged});

  @override
  State<TagsGridView> createState() => _TagsGridViewState();
}

class _TagsGridViewState extends State<TagsGridView> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      // spacing: 5,
      // runSpacing: 5,
      children: widget.tags
          .map(
            (e) => InkWell(
              mouseCursor: SystemMouseCursors.click,
              hoverColor: Colors.black,
              onTap: e.onTap,
              child: Chip(
                label: Text(e.name),
                backgroundColor: e.color,
                onDeleted: e.showDeleteIcon
                    ? () {
                        setState(() {
                          widget.tags.remove(e);
                          if (e.onDeleted != null) {
                            e.onDeleted!();
                          }
                          if (widget.onChanged != null) {
                            widget.onChanged!(widget.tags);
                          }
                        });
                      }
                    : null,
                deleteIcon: const Icon(Icons.close),
              ),
            ),
          )
          .toList(),
    );
  }
}
