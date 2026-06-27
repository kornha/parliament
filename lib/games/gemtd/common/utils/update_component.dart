import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';

class UpdateComponent extends GameComponent {
  UpdateComponent(this.updateCallback);

  final Function(double) updateCallback;
  @override
  void update(double dt) {
    super.update(dt);
    updateCallback.call(dt);
  }
}
