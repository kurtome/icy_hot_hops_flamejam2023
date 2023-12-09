import 'package:flutter/foundation.dart';
import 'package:icy_hot_hops_flamejam2023/entities/enemy_bumper.dart';
import 'package:icy_hot_hops_flamejam2023/entities/player.dart';
import 'package:icy_hot_hops_flamejam2023/main.dart';
import 'package:leap/leap.dart';

class EnemyCharacter extends Character<IcyHotGame> {
  EnemyCharacter({
    super.static = false,
    super.removeOnDeath,
    super.finishAnimationBeforeRemove,
  }) {
    tags.add('Enemy');

    // This makes it possible for players to "bop" from the top.
    isSolidFromLeft = false;
    isSolidFromRight = false;
    isSolidFromBottom = false;
  }

  bool faceLeft = true;
  bool animationFacesLeft = true;

  late double walkSpeed;
  bool walking = true;
  bool reverseOnBumper = true;

  @override
  @mustCallSuper
  void onLoad() {
    walkSpeed = tileSize * 1;
  }

  @override
  @mustCallSuper
  void update(double dt) {
    super.update(dt);

    if (isDead) {
      return;
    }

    if (walking) {
      if (faceLeft) {
        velocity.x = -walkSpeed;
      } else {
        velocity.x = walkSpeed;
      }
    }

    for (final other in collisionInfo.allCollisions) {
      if (other is EnemyBumper) {
        faceLeft = other.x > x;
      }

      if (other is Player) {
        other.health -= 1;
      }
    }

    // Update sprite for direction
    if ((!animationFacesLeft && velocity.x < 0) ||
        (animationFacesLeft && velocity.x > 0)) {
      characterAnimation!.scale.x = -characterAnimation!.scale.x.abs();
    } else if ((!animationFacesLeft && velocity.x > 0) ||
        (animationFacesLeft && velocity.x < 0)) {
      characterAnimation!.scale.x = characterAnimation!.scale.x.abs();
    }
  }
}
