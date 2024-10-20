import 'package:flutter/material.dart';
import 'package:political_think/common/extensions.dart';

class ZExpansionTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final List<Widget> children;
  final ValueChanged<bool>? onExpansionChanged;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry? childrenPadding;
  final Widget? trailing;
  final EdgeInsetsGeometry? tilePadding;
  final Color? backgroundColor;
  final bool maintainState;
  final Color? collapsedBackgroundColor;
  final Color? collapsedTextColor;
  final Color? collapsedIconColor;
  final Color? textColor;
  final Color? iconColor;
  final ShapeBorder? shape;
  final ShapeBorder? collapsedShape;
  final Clip clipBehavior;
  final Alignment? expandedAlignment;
  final CrossAxisAlignment? expandedCrossAxisAlignment;

  const ZExpansionTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.children = const <Widget>[],
    this.onExpansionChanged,
    this.initiallyExpanded = true, // Default to true as per your change
    this.childrenPadding,
    this.trailing,
    this.tilePadding,
    this.backgroundColor,
    this.maintainState = false,
    this.collapsedBackgroundColor,
    this.collapsedTextColor,
    this.collapsedIconColor,
    this.textColor,
    this.iconColor,
    this.shape,
    this.collapsedShape,
    this.clipBehavior = Clip.none,
    this.expandedAlignment,
    this.expandedCrossAxisAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent, // Remove divider
      ),
      child: ExpansionTile(
        key: key,
        leading: leading,
        title: title,
        subtitle: subtitle,
        onExpansionChanged: onExpansionChanged,
        initiallyExpanded: initiallyExpanded,
        childrenPadding: childrenPadding ??
            EdgeInsets.only(
              bottom: context.sh.height!, // Apply custom bottom padding
            ),
        trailing: trailing,
        tilePadding: tilePadding,
        backgroundColor: backgroundColor,
        maintainState: maintainState,
        collapsedBackgroundColor: collapsedBackgroundColor,
        collapsedTextColor: collapsedTextColor,
        collapsedIconColor: collapsedIconColor,
        textColor: textColor,
        iconColor: iconColor,
        shape: shape,
        collapsedShape: collapsedShape,
        clipBehavior: clipBehavior,
        expandedAlignment: expandedAlignment,
        expandedCrossAxisAlignment: expandedCrossAxisAlignment,
        children: children,
      ),
    );
  }
}
