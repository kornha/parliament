import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';

class MineView extends GameComponent {
  late GameComponent icon;
  TextComponent? text;
  bool? maskGreen;

  MineView({required Vector2 position, required Vector2 size, TextStyle? style})
      : super(position: position, size: size) {
    active = false;
    _style = style ?? const TextStyle(color: Colors.white70, fontSize: 15);
  }

  late TextStyle _style;

  int _n = 0;
  int get number => _n;
  set number(int n) {
    _n = n;
    text?.text = '$_n';
  }

  @override
  Future<void>? onLoad() async {
    await super.onLoad();
    if (size.x > size.y) {
      icon = GameComponent(
          position: (size / 2)..x = size.x * (1 / 3),
          size: Vector2(size.y, size.x * (2 / 3)));
      text = TextComponent(
          position: (size / 2)..x = size.x * (5 / 6),
          textRenderer: TextPaint(style: _style),
          anchor: Anchor.center);
    } else {
      icon = GameComponent(
          position: (size / 2)..y = size.y * (1 / 3),
          size: Vector2(size.x, size.y * (2 / 3)));
      text = TextComponent(
          position: (size / 2)..y = size.y * (5 / 6),
          textRenderer: TextPaint(style: _style),
          anchor: Anchor.center);
    }

    icon.sprite = GameConstants().neutral.mine;
    number = 0;
    add(icon);
    add(text!);
  }

  @override
  void render(Canvas c) {
    if (maskGreen != null) {
      Color? color = maskGreen! ? Colors.green[200] : Colors.red[200];
      c.drawRect(size.toRect(), Paint()..color = color!.withOpacity(0.3));
    }
    super.render(c);
  }
}
