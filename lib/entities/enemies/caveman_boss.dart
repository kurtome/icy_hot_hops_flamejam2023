import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:icy_hot_hops_flamejam2023/entities/door.dart';
import 'package:icy_hot_hops_flamejam2023/entities/enemies/enemy_character.dart';
import 'package:leap/leap.dart';
import 'package:tiled/tiled.dart';

class CavemanBoss extends EnemyCharacter {
  CavemanBoss(double x, double y)
      : super(
          static: false,
          removeOnDeath: true,
          finishAnimationBeforeRemove: true,
        ) {
    solidTags.add(CommonTags.ground);

    width = 8;
    height = 12;
    priority = 2;

    this.x = x;
    this.y = y;

    animationFacesLeft = false;

    characterAnimation = CavemanAnimation();
    _animationWrapper = _AnimationWrapper(characterAnimation!);
    characterAnimation!.addToParent(_animationWrapper);
    add(_animationWrapper);

    health = 4;
  }

  CavemanBoss.fromTiledObject(TiledObject object) : this(object.x, object.y);

  late _AnimationWrapper _animationWrapper;
  bool grown = false;
  Vector2 baseSize = Vector2(8, 12);
  Vector2 targetSize = Vector2(8, 12);
  Vector2 targetAnimationScale = Vector2(1, 1);
  double targetScale = 10;
  PhysicalEntity? lastDown;
  double jumpTimer = 3;

  @override
  @mustCallSuper
  void update(double dt) {
    super.update(dt);

    debugHitbox = false;
    debugCollisions = false;

    if (isDead) {
      return;
    }

    walkSpeed = tileSize * health * 2;

    if (collisionInfo.down) {
      lastDown = collisionInfo.downCollision;
    }
    if (!grown && collisionInfo.down) {
      walking = true;
      grown = true;
      targetScale = 8.0;
      _jump();
      targetSize.setValues(baseSize.x * targetScale, baseSize.y * targetScale);
      targetAnimationScale.setAll(targetScale);
      bottom = collisionInfo.downCollision!.top;
    } else {
      targetScale = health * 2;
      targetSize.setValues(baseSize.x * targetScale, baseSize.y * targetScale);
      targetAnimationScale.setAll(targetScale);
    }

    if (grown) {
      if (jumpTimer <= 0) {
        _jump();
        jumpTimer = 4;
      } else {
        jumpTimer -= dt;
      }
    }

    size.lerp(targetSize, dt / 2);
    _animationWrapper.scale.lerp(targetAnimationScale, dt / 2);
  }

  void _jump() {
    velocity.y = -walkSpeed * 3;
  }

  @override
  @mustCallSuper
  void onDeath() {
    super.onDeath();
    velocity.x = 0;
    velocity.y = 0;
    if (lastDown != null) {
      bottom = lastDown!.top;
    }
    statuses.add(DeadCavemanStatus());

    FlameAudio.bgm.play('waiting-time.mp3');
    map.add(
      Door.placedToMap(
        position: Vector2(right, lastDown!.top - tileSize),
        size: Vector2(tileSize, tileSize),
        destinationMap: 'map_level_credits.tmx',
      ),
    );
  }
}

/// Wrapper to compensate for the CharacterAnimation positioning so we can scale
/// this to grow/shrink the Caveman
class _AnimationWrapper extends PositionComponent
    with HasAncestor<CavemanBoss> {
  final CharacterAnimation wrapped;

  _AnimationWrapper(this.wrapped);

  @override
  void update(double dt) {
    // tbh no idea why this math works, gamejam hack :)

    // facing left changes the x-scale in the character animation
    if (ancestor.faceLeft) {
      x = (wrapped.x * -scale.x) +
          ancestor.width +
          (wrapped.width - ancestor.baseSize.x) * scale.x / 2;
    } else {
      x = (wrapped.x * -scale.x) +
          ancestor.width -
          (wrapped.width - ancestor.baseSize.x) * scale.x * 1.5;
    }

    y = (wrapped.y * -scale.y) -
        (wrapped.height - ancestor.baseSize.y) * scale.y;
  }
}

enum _AnimationState { run, melt }

class CavemanAnimation
    extends CharacterAnimation<_AnimationState, CavemanBoss> {
  @override
  @mustCallSuper
  Future<void> onLoad() async {
    final tileset = await Flame.images.load('snowman_animation.png');

    animations = {
      _AnimationState.run: SpriteAnimation.fromFrameData(
        tileset,
        SpriteAnimationData.sequenced(
          amount: 3,
          stepTime: 0.2,
          textureSize: Vector2(16, 16),
          texturePosition: Vector2(0, 0),
        ),
      ),
      _AnimationState.melt: SpriteAnimation.fromFrameData(
        tileset,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.4,
          textureSize: Vector2(16, 16),
          texturePosition: Vector2(0, 16),
          loop: false,
        ),
      ),
    };


    // tint red to differentiate from the snowman boss
    add(
      ColorEffect(
        Colors.red,
        EffectController(duration: 3, infinite: true),
        // Means, applies from 0% to 80% of the color
        opacityTo: 0.3,
        opacityFrom: 0.5,
      ),
    );

    return super.onLoad();
  }

  @override
  @mustCallSuper
  void update(double dt) {
    if (character.isDead) {
      current = _AnimationState.melt;
    } else {
      current = _AnimationState.run;
    }
    super.update(dt);
  }
}

class DeadCavemanStatus extends StatusComponent with IgnoredByWorld {}

class CavemanBossTrigger extends PhysicalEntity {
  CavemanBossTrigger(TiledObject object) : super(static: true) {
    x = object.x;
    y = object.y;
    width = object.width;
    height = object.height;
  }

  @override
  @mustCallSuper
  void onLoad() {
    super.onLoad();
    FlameAudio.audioCache.load('broken-bitz.mp3');
  }

  void trigger() {
    map.add(CavemanBoss(right + map.tileSize * 5, bottom - map.tileSize * 3));
    FlameAudio.bgm.play('broken-bitz.mp3');
    removeFromParent();
  }
}

class CavemanBossFactory implements TiledObjectHandler {
  CavemanBossFactory();

  @override
  void handleObject(TiledObject object, Layer layer, LeapMap map) {
    map.add(CavemanBoss.fromTiledObject(object));
  }
}

class CavemanBossTriggerFactory implements TiledObjectHandler {
  CavemanBossTriggerFactory();

  @override
  void handleObject(TiledObject object, Layer layer, LeapMap map) {
    map.add(CavemanBossTrigger(object));
  }
}
