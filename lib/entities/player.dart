import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:icy_hot_hops_flamejam2023/entities/coin.dart';
import 'package:icy_hot_hops_flamejam2023/entities/door.dart';
import 'package:icy_hot_hops_flamejam2023/entities/enemies/caveman_boss.dart';
import 'package:icy_hot_hops_flamejam2023/entities/enemies/snowman_boss.dart';
import 'package:icy_hot_hops_flamejam2023/entities/info_sign.dart';
import 'package:icy_hot_hops_flamejam2023/entities/player/coin_jumper_character.dart';
import 'package:icy_hot_hops_flamejam2023/input.dart';
import 'package:leap/leap.dart';

class Player extends CoinJumperCharacter {
  Player({super.health = initialHealth}) : super(removeOnDeath: false) {
    solidTags.add(CommonTags.ground);
    solidTags.add('Enemy');
  }

  static const initialHealth = 1;

  int coins = 0;

  late Vector2 _spawn;
  late final IcyHotInput _input;

  double deadTime = 0;
  double timeHoldingJump = 0;
  bool didEnemyBop = false;
  bool didAirJump = false;
  int jumpCount = 0;
  double iFramesTime = 0;

  /// Render on top of the map tiles.
  @override
  int get priority => 10;

  @override
  Future<void> onLoad() async {
    _input = game.input;
    _spawn = map.playerSpawn;

    characterAnimation = PlayerSpriteAnimation();

    // Size controls player hitbox, which should be slightly smaller than
    // visual size of the sprite.
    size = Vector2(10, 24);

    resetPosition();

    walkSpeed = map.tileSize * 10;
    minJumpImpulse = world.gravity * 0.6;
  }

  @override
  Future<void> update(double dt) async {
    // check this before super.update
    if (wasAlive && !isAlive) {
      FlameAudio.play('die.wav');
    }

    super.update(dt);

    iFramesTime -= dt;
    iFramesTime = max(0, iFramesTime);

    debugCollisions = false;

    final wasJumping = jumping;

    didAirJump = false;
    didEnemyBop = false;

    updateHandleInput(dt);

    updateCollisionInteractions(dt);

    if (isDead) {
      deadTime += dt;
      walking = false;
    }

    if (world.isOutside(this) || (isDead && deadTime > 2)) {
      await game.reloadLevel();
      coins = 0;
      deadTime = 0;
      health = initialHealth;
    }
    if (!wasJumping && jumping) {
      FlameAudio.play('jump.wav');
    }
  }

  void resetPosition() {
    _spawn = map.playerSpawn;
    x = _spawn.x;
    y = _spawn.y;
    velocity.x = 0;
    velocity.y = 0;
    airXVelocity = 0;
    faceLeft = false;
    jumping = false;

    FlameAudio.play('spawn.wav');
  }

  @override
  @mustCallSuper
  void onDeath() {
    super.onDeath();
    coins = 0;
  }

  void updateHandleInput(double dt) {
    if (isAlive) {
      // Keep jumping if started.
      if (jumping &&
          _input.isPressedJump &&
          timeHoldingJump < maxJumpHoldTime &&
          // hitting a ceiling should behave the same
          // as letting go of the jump button
          !collisionInfo.up) {
        jumping = true;
        timeHoldingJump += dt;
      } else {
        jumping = false;
        timeHoldingJump = 0;
      }
    }

    final ladderCollision =
        collisionInfo.allCollisions.whereType<Ladder>().firstOrNull;
    final onLadderStatus = getStatus<OnLadderStatus>();
    if ((_input.isJustPressedUp ||
            _input.isJustPressedDown ||
            _input.isJustPressedAction) &&
        ladderCollision != null &&
        onLadderStatus == null) {
      final status = OnLadderStatus(ladderCollision);
      add(status);
      walking = false;
      airXVelocity = 0;
      if (isOnGround) {
        status.movement = LadderMovement.down;
      } else {
        status.movement = LadderMovement.up;
      }
    } else if (onLadderStatus != null) {
      if (_input.isPressedUp) {
        onLadderStatus.movement = LadderMovement.up;
      } else if (_input.isPressedDown) {
        onLadderStatus.movement = LadderMovement.down;
      } else {
        onLadderStatus.movement = LadderMovement.stopped;
      }

      if (_input.isJustPressedJump) {
        // JumperBehavior will handle applying the jump and exiting the ladder
        jumping = true;
        airXVelocity = walkSpeed;
        walking = true;
        // Make sure the player exits the ladder facing the direction jumped
        faceLeft = _input.isPressedLeft;
      }
    } else {
      // Not on a ladder or anything

      // Tapped left.
      if (_input.isPressedLeft) {
        walking = true;
        faceLeft = true;
      } else if (_input.isPressedRight) {
        walking = true;
        faceLeft = false;
      } else {
        walking = false;
      }

      if (_input.isJustPressedJump && isOnGround) {
        jumping = true;
        jumpCount = 1;
      } else if (isOnGround) {
        jumpCount = 0;
      }

      /// Double jumps, costs a coin, must be in air, only once
      if (_input.isJustPressedJump &&
          !jumping &&
          coins > 0 &&
          !isOnGround &&
          jumpCount < 2) {
        jumping = true;
        didAirJump = true;
        jumpCount++;
        coins--;
      }
    }
  }

  void updateCollisionInteractions(double dt) {
    if (collisionInfo.downCollision?.tags.contains('Hazard') ?? false) {
      health -= collisionInfo.downCollision!.hazardDamage;
    }

    if (isDead) {
      return;
    }

    if (collisionInfo.down &&
        collisionInfo.downCollision!.tags.contains('Enemy')) {
      (collisionInfo.downCollision! as Character).health -= 1;
      didEnemyBop = true;
      jumping = true;

      // avoid a bug with taking damage from bosses after bopping
      iFramesTime = 0.5;
    }

    for (final other in collisionInfo.allCollisions) {
      if (other is Coin) {
        other.collect();
        coins++;
      }

      if (other is InfoSign) {
        other.activateText();
      }

      if (other is Door &&
          (_input.isJustPressedDown ||
              _input.isJustPressedUp ||
              _input.isJustPressedAction) &&
          !hasStatus<EnteringDoorStatus>()) {
        other.startEnter(this);
      }

      if (other is SnowmanBossTrigger) {
        other.trigger();
      }
      if (other is CavemanBossTrigger) {
        other.trigger();
      }
    }
  }
}

enum _AnimationState { idle, walk, jump, fall, death, ladder }

class PlayerSpriteAnimation extends CharacterAnimation<_AnimationState, Player>
    with HasGameRef<LeapGame> {
  PlayerSpriteAnimation() : super(scale: Vector2.all(2));

  @override
  Future<void>? onLoad() async {
    final spritesheet = await gameRef.images.load('player_spritesheet.png');

    animations = {
      _AnimationState.idle: SpriteAnimation.fromFrameData(
        spritesheet,
        SpriteAnimationData.sequenced(
          amount: 2,
          stepTime: 0.4,
          textureSize: Vector2.all(16),
          amountPerRow: 2,
        ),
      ),
      _AnimationState.walk: SpriteAnimation.fromFrameData(
        spritesheet,
        SpriteAnimationData.sequenced(
          amount: 2,
          stepTime: 0.2,
          textureSize: Vector2.all(16),
          texturePosition: Vector2(0, 16),
          amountPerRow: 2,
        ),
      ),
      _AnimationState.jump: SpriteAnimation.fromFrameData(
        spritesheet,
        SpriteAnimationData.sequenced(
          amount: 1,
          stepTime: 1,
          textureSize: Vector2.all(16),
          texturePosition: Vector2(16 * 4, 0),
          amountPerRow: 1,
          loop: false,
        ),
      ),
      _AnimationState.fall: SpriteAnimation.fromFrameData(
        spritesheet,
        SpriteAnimationData.sequenced(
          amount: 2,
          stepTime: 0.2,
          textureSize: Vector2.all(16),
          texturePosition: Vector2(16 * 2, 0),
          amountPerRow: 2,
        ),
      ),
      _AnimationState.death: SpriteAnimation.fromFrameData(
        spritesheet,
        SpriteAnimationData.sequenced(
          amount: 8,
          stepTime: 0.15,
          textureSize: Vector2.all(16),
          texturePosition: Vector2(0, 16 * 2),
          amountPerRow: 6,
          loop: false,
        ),
      ),
      _AnimationState.ladder: SpriteAnimation.fromFrameData(
        spritesheet,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.15,
          textureSize: Vector2.all(16),
          texturePosition: Vector2(0, 16 * 6),
          amountPerRow: 4,
        ),
      ),
    };

    current = _AnimationState.idle;

    return super.onLoad();
  }

  @override
  @mustCallSuper
  void update(double dt) {
    // Default to playing animations
    playing = true;

    if (character.isDead) {
      current = _AnimationState.death;
    } else if (character.hasStatus<EnteringDoorStatus>()) {
      current = _AnimationState.ladder;
      playing = true;
    } else if (character.hasStatus<OnLadderStatus>()) {
      if (character.getStatus<OnLadderStatus>()!.movement ==
          LadderMovement.stopped) {
        playing = false;
      } else {
        playing = true;
      }
      current = _AnimationState.ladder;
    } else {
      if (character.isOnGround) {
        // On the ground.
        if (character.velocity.x.abs() > 0) {
          current = _AnimationState.walk;
        } else {
          current = _AnimationState.idle;
        }
      } else {
        // In the air.
        if (character.velocity.y > (game.world.maxVelocity / 4)) {
          current = _AnimationState.fall;
        } else if (character.velocity.y < 0) {
          current = _AnimationState.jump;
        }
      }
    }
    super.update(dt);
  }
}
