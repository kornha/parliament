import 'package:flutter/material.dart';
import 'package:political_think/common/extensions.dart';

class ZTextfield extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onChanged;
  final Color? cursorColor;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final bool enabled;

  const ZTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.cursorColor,
    this.maxLines,
    this.minLines,
    this.keyboardType,
    this.focusNode,
    this.textCapitalization = TextCapitalization.sentences,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: enabled,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      decoration: InputDecoration(
        hintText: hintText,
        border: InputBorder.none,
        filled: true,
        fillColor: context.backgroundColor,
      ),
      cursorColor: cursorColor,
      onChanged: onChanged,
      onTapOutside: (event) {
        FocusScope.of(context).unfocus();
      },
    );
  }
}
