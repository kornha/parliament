import 'package:flutter/material.dart';
import 'package:political_think/common/extensions.dart';

class ZTextField extends StatelessWidget {
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
  final Function(PointerDownEvent)? onTapOutside;
  final TextAlign? textAlign;
  final bool autoCorrect;

  const ZTextField({
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
    this.onTapOutside,
    this.textAlign,
    this.autoCorrect = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      textAlign: textAlign ?? TextAlign.start,
      enabled: enabled,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      autocorrect: autoCorrect,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: context.m.copyWith(color: context.surfaceColorBright),
        border: InputBorder.none,
        filled: true,
        fillColor: context.backgroundColor,
      ),
      cursorColor: cursorColor ?? context.secondaryColor,
      onChanged: onChanged,
      onTapOutside: onTapOutside ??
          (event) {
            // Only unfocus if the current focus is on this TextField
            if (focusNode?.hasFocus ?? true) {
              FocusScope.of(context).unfocus();
            }
          },
    );
  }
}
