import 'package:flutter/material.dart';
import 'package:mobile_project/utils/app_textstyles.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(String)? onSearch;
  final String initialText;

  const CustomSearchBar({
    super.key,
    this.onSearch,
    this.initialText = '',
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialText,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        style: AppTextStyle.withColor(
          AppTextStyle.buttonMedium,
          Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm',
          hintStyle: AppTextStyle.withColor(
            AppTextStyle.buttonMedium,
            isDark ? Colors.grey[400]! : Colors.grey[600]!,
          ),

          /// 🔍 Nút tìm kiếm
          prefixIcon: IconButton(
            icon: Icon(
              Icons.search,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onPressed: () {
              widget.onSearch?.call(_controller.text);
            },
          ),

          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
