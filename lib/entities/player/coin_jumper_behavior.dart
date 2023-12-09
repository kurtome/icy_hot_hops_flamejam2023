import 'dart:math';

import 'package:icy_hot_hops_flamejam2023/entities/player.dart';
import 'package:leap/leap.dart';

/// Updates the [JumperCharacter] movement logic.
class CoinJumperBehavior extends PhysicalBehavior<Player> {
  @override
  void update(double dt) {
    super.update(dt);

    final ladderStatus = parent.getStatus<OnLadderStatus>();
    if (ladderStatus != null) {
      updateClimbingLadder(dt, ladderStatus);
    } else {
      updateNormal(dt);
    }
  }

  void updateNormal(double dt) {
    if (parent.jumping) {
      if (parent.isOnGround) {
        velocity.y = -parent.minJumpImpulse;
        if (parent.walking) {
          parent.gravityRate = 1.0;
        } else {
          parent.gravityRate = 1.4;
        }
      } else if (parent.didAirJump || parent.didEnemyBop) {
        velocity.y = -parent.minJumpImpulse;
      } else {
        // in the air, no longer accelerating upwards
        velocity.y = min(-parent.minJumpImpulse * 0.7, velocity.y);
      }
    } else if (!parent.isOnGround) {
      parent.gravityRate = 2.2;
    } else {
      parent.gravityRate = 1;
    }

    // Only apply walking acceleration when on ground
    if (parent.isOnGround) {
      if (parent.walking) {
        if (parent.faceLeft) {
          velocity.x = -parent.walkSpeed;
        } else {
          velocity.x = parent.walkSpeed;
        }
      } else {
        if (parent.faceLeft) {
          velocity.x = min(velocity.x + parent.walkSpeed * 2 * dt, 0);
        } else {
          velocity.x = max(velocity.x - parent.walkSpeed * 2 * dt, 0);
        }
      }
      parent.airXVelocity = velocity.x.abs();
    } else {
      // in the air
      if (parent.walking) {
        // should be able to accelerate from a stand still in the air
        parent.airXVelocity = max(parent.walkSpeed, parent.airXVelocity);

        if (parent.faceLeft) {
          velocity.x = -parent.airXVelocity;
        } else {
          velocity.x = parent.airXVelocity;
        }
      }
    }
  }

  void updateClimbingLadder(double dt, OnLadderStatus ladderStatus) {
    if (parent.jumping) {
      ladderStatus.removeFromParent();
      velocity.y = -parent.minJumpImpulse;
    }
  }
}
