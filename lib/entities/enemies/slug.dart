import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/foundation.dart';
import 'package:icy_hot_hops_flamejam2023/entities/enemies/enemy_character.dart';
import 'package:leap/leap.dart';
import 'package:tiled/tiled.dart';

class Slug extends EnemyCharacter {
  Slug(TiledObject tiledObject)
      : super(
          static: false,
          removeOnDeath: true,
          finishAnimationBeforeRemove: true,
        ) {
    solidTags.add(CommonTags.ground);

    width = 12;
    height = 10;
    priority = 2;

    position = Vector2(tiledObject.x - width / 2, tiledObject.y - width / 2);

    animationFacesLeft = false;
    characterAnimation = SlugAnimation();
  }

  @override
  @mustCallSuper
  void update(double dt) {
    super.update(dt);

    walkSpeed = tileSize * 2;
  }

  @override
  @mustCallSuper
  void onDeath() {
    super.onDeath();
    statuses.add(DeadSlugStatus());
  }
}

enum _AnimationState { run, death }

class SlugAnimation extends CharacterAnimation<_AnimationState, Slug> {
  @override
  @mustCallSuper
  Future<void> onLoad() async {
    final tileset = await Flame.images.load('slug_animation.png');

    animations = {
      _AnimationState.run: SpriteAnimation.fromFrameData(
        tileset,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.2,
          textureSize: Vector2(32, 16),
          texturePosition: Vector2(0, 0),
        ),
      ),
      _AnimationState.death: SpriteAnimation.fromFrameData(
        tileset,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.4,
          textureSize: Vector2(32, 16),
          texturePosition: Vector2(0, 16),
          loop: false,
        ),
      ),
    };

    return super.onLoad();
  }

  @override
  @mustCallSuper
  void update(double dt) {
    if (character.isDead) {
      current = _AnimationState.death;
    } else {
      current = _AnimationState.run;
    }
    super.update(dt);
  }
}

class DeadSlugStatus extends StatusComponent with IgnoredByWorld {}

class SlugFactory implements TiledObjectHandler {
  SlugFactory();

  @override
  void handleObject(TiledObject object, Layer layer, LeapMap map) {
    final slug = Slug(object);
    map.add(slug);
  }
}
