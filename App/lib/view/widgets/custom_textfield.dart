import 'package:flutter/material.dart';
import 'package:mobile_project/utils/app_textstyles.dart';

class CustomTextfield extends StatefulWidget {
  final String label;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final bool isPassword ;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final String? initialValue;

  const CustomTextfield({
    super.key,
    required this.label,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.controller,
    this.onChanged,
    this.validator,
    this.initialValue
  });

  @override
  State<CustomTextfield> createState() => _CustomTextfieldState();
}

class _CustomTextfieldState extends State<CustomTextfield> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: widget.controller,
      initialValue: widget.initialValue,
      obscureText: widget.isPassword && _obscureText,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged:  widget.onChanged,
      style: AppTextStyle.withColor(
        AppTextStyle.bodyMedium,
        Theme.of(context).textTheme.bodyLarge!.color!,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: AppTextStyle.withColor(
          AppTextStyle.bodyMedium,
          isDark ? Colors.grey[400]! : Colors.grey[600]!,
        ),
        prefixIcon: Icon(
          widget.prefixIcon,
          color:  isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        suffixIcon: widget.isPassword
          ? IconButton(
            onPressed: (){
              setState(() {
                _obscureText = ! _obscureText;
              });
            },
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
            ),
        )
      :null,
      border:  OutlineInputBorder(
        borderRadius:  BorderRadius.circular(12),
        borderSide: BorderSide(
          color : isDark ? Colors.grey[700]! : Colors.grey[300]!,
        )
      ),
        enabledBorder: OutlineInputBorder(
            borderRadius:  BorderRadius.circular(12),
            borderSide: BorderSide(
              color : isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius:  BorderRadius.circular(12),
            borderSide: BorderSide(
              color : Theme.of(context).primaryColor,
            ),
        ),
        errorBorder: OutlineInputBorder(
            borderRadius:  BorderRadius.circular(12),
            borderSide: BorderSide(
              color : Theme.of(context).colorScheme.error,
            ),
        ),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius:  BorderRadius.circular(12),
            borderSide: BorderSide(
              color : Theme.of(context).colorScheme.error,
            ),
        ),
      ),
    );
  }
}
