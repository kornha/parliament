import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/constants.dart';

/// Visual style for a damage-over-time effect on an enemy.
enum DotStyle { fire, spark, poison, generic }

/// Procedural combat effects (no external assets): additive glow, spark bursts
/// and flashes. Built on Flame's particle system so each effect cleans itself
/// up when it finishes.
class Fx {
  static final Random _rnd = Random();

  /// A small, repeatable puff for a damage-over-time debuff, emitted from the
  /// enemy's position ([world] space). Each [style] has its own look so burn /
  /// electrocution / poison read distinctly and consistently.
  static void dot(Component parent, Vector2 position, Color color,
      DotStyle style) {
    final pos = position.clone();
    final count = style == DotStyle.spark ? 4 : 3;
    parent.add(ParticleSystemComponent(
      position: pos,
      priority: Constants.PROJECTILE_PRIORITY,
      particle: Particle.generate(
        count: count,
        generator: (i) => _dotParticle(style, color),
      ),
    ));
  }

  static Particle _dotParticle(DotStyle style, Color color) {
    switch (style) {
      case DotStyle.fire:
        // Embers that rise and shrink, orange→yellow.
        final vel = Vector2((_rnd.nextDouble() - 0.5) * 10, -10 - _rnd.nextDouble() * 12);
        final life = 0.4 + _rnd.nextDouble() * 0.3;
        return AcceleratedParticle(
          speed: vel,
          acceleration: Vector2(0, -8),
          lifespan: life,
          child: ComputedParticle(
            lifespan: life,
            renderer: (canvas, p) {
              final t = p.progress;
              canvas.drawCircle(
                Offset.zero,
                2.4 * (1 - t * 0.6),
                Paint()
                  ..blendMode = BlendMode.plus
                  ..color = (Color.lerp(color, Colors.yellow, (1 - t) * 0.5) ??
                          color)
                      .withOpacity((1 - t).clamp(0.0, 1.0))
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
              );
            },
          ),
        );
      case DotStyle.spark:
        // Quick electric sparks that shoot out and decelerate, white-blue.
        final a = _rnd.nextDouble() * 2 * pi;
        final speed = 22 + _rnd.nextDouble() * 34;
        final vel = Vector2(cos(a), sin(a)) * speed;
        final life = 0.16 + _rnd.nextDouble() * 0.14;
        return AcceleratedParticle(
          speed: vel,
          acceleration: vel * -3.5,
          lifespan: life,
          child: ComputedParticle(
            lifespan: life,
            renderer: (canvas, p) {
              final t = p.progress;
              canvas.drawCircle(
                Offset.zero,
                1.7 * (1 - t),
                Paint()
                  ..blendMode = BlendMode.plus
                  ..color = (Color.lerp(color, Colors.white, 0.5) ?? color)
                      .withOpacity((1 - t).clamp(0.0, 1.0)),
              );
            },
          ),
        );
      case DotStyle.poison:
        // Slow green bubbles drifting up.
        final vel = Vector2((_rnd.nextDouble() - 0.5) * 7, -6 - _rnd.nextDouble() * 6);
        final life = 0.5 + _rnd.nextDouble() * 0.4;
        return AcceleratedParticle(
          speed: vel,
          lifespan: life,
          child: ComputedParticle(
            lifespan: life,
            renderer: (canvas, p) {
              final t = p.progress;
              canvas.drawCircle(
                Offset.zero,
                2.2 * (1 - t * 0.4),
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1.1
                  ..color =
                      color.withOpacity((0.7 * (1 - t)).clamp(0.0, 1.0)),
              );
            },
          ),
        );
      case DotStyle.generic:
        // Small motes drifting up in the ability's own color.
        final vel = Vector2((_rnd.nextDouble() - 0.5) * 8, -8 - _rnd.nextDouble() * 8);
        final life = 0.4 + _rnd.nextDouble() * 0.3;
        return AcceleratedParticle(
          speed: vel,
          lifespan: life,
          child: ComputedParticle(
            lifespan: life,
            renderer: (canvas, p) {
              final t = p.progress;
              canvas.drawCircle(
                Offset.zero,
                2.0 * (1 - t * 0.5),
                Paint()
                  ..blendMode = BlendMode.plus
                  ..color = color.withOpacity((1 - t).clamp(0.0, 1.0))
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
              );
            },
          ),
        );
    }
  }

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
