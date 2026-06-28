import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/constants.dart';

/// Procedural combat effects (no external assets): additive glow, spark bursts
/// and flashes. Built on Flame's particle system so each effect cleans itself
/// up when it finishes.
class Fx {
  static final Random _rnd = Random();

  /// Cached additive-glow paints, keyed by size+color+scale. The radial shader
  /// bakes a fixed local center/radius, and every projectile of a given type
  /// shares the same size, so one paint is reused across all of them (cheap
  /// enough for lots of simultaneous bullets — no per-frame blur).
  static final Map<int, Paint> _glowCache = {};

  /// Draws a soft additive glow centered inside [size]. Call from render().
  static void glow(ui.Canvas canvas, Vector2 size, Color color,
      {double scale = 1.6}) {
    final r = (size.x + size.y) / 4 * scale;
    if (r <= 0) return;
    final center = Offset(size.x / 2, size.y / 2);
    final key = Object.hash(size.x, size.y, color.value, scale);
    final paint = _glowCache.putIfAbsent(
      key,
      () => Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(center, r, [
          Color.lerp(color, Colors.white, 0.55)!.withOpacity(0.95),
          color.withOpacity(0.5),
          color.withOpacity(0.0),
        ], const [
          0.0,
          0.4,
          1.0,
        ]),
    );
    canvas.drawCircle(center, r, paint);
  }

  /// A layered explosion at [position] (world space): a bright central flash
  /// plus radial glowing sparks. [radius] is in world units.
  static void explosion(
    Component parent,
    Vector2 position,
    Color color,
    double radius, {
    int sparks = 12,
  }) {
    if (radius <= 0) return;
    final pos = position.clone();

    // Central flash: a quick expanding, fading bloom.
    parent.add(ParticleSystemComponent(
      position: pos,
      priority: Constants.PROJECTILE_PRIORITY,
      particle: ComputedParticle(
        lifespan: 0.26,
        renderer: (canvas, particle) {
          final t = Curves.easeOut.transform(particle.progress);
          canvas.drawCircle(
            Offset.zero,
            radius * (0.35 + t * 0.85),
            Paint()
              ..blendMode = BlendMode.plus
              ..color = (Color.lerp(Colors.white, color, t) ?? color)
                  .withOpacity((1 - t).clamp(0.0, 1.0))
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.3),
          );
        },
      ),
    ));

    // Radial sparks that fly out and decelerate.
    parent.add(ParticleSystemComponent(
      position: pos.clone(),
      priority: Constants.PROJECTILE_PRIORITY,
      particle: Particle.generate(
        count: sparks,
        generator: (i) {
          final a = (i / sparks) * 2 * pi + _rnd.nextDouble() * 0.6;
          final speed = radius * (1.6 + _rnd.nextDouble() * 1.8);
          final vel = Vector2(cos(a), sin(a)) * speed;
          final life = 0.32 + _rnd.nextDouble() * 0.32;
          final r0 = radius * (0.10 + _rnd.nextDouble() * 0.10);
          return AcceleratedParticle(
            speed: vel,
            acceleration: vel * -2.2,
            lifespan: life,
            child: ComputedParticle(
              lifespan: life,
              renderer: (canvas, particle) {
                final t = particle.progress;
                canvas.drawCircle(
                  Offset.zero,
                  r0 * (1 - t * 0.7),
                  Paint()
                    ..blendMode = BlendMode.plus
                    ..color = color.withOpacity((1 - t).clamp(0.0, 1.0))
                    ..maskFilter =
                        const MaskFilter.blur(BlurStyle.normal, 1.5),
                );
              },
            ),
          );
        },
      ),
    ));
  }
}
