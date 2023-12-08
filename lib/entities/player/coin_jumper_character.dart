import 'package:icy_hot_hops_flamejam2023/entities/player/coin_jumper_behavior.dart';
import 'package:icy_hot_hops_flamejam2023/main.dart';
import 'package:leap/leap.dart';

/// Based on leap/src/characters/jumper_character.dart
class CoinJumperCharacter extends Character<IcyHotGame> {
  CoinJumperCharacter({super.removeOnDeath, super.health})
      : super(behaviors: [CoinJumperBehavior()]);

  /// When true the character is facing left, otherwise right.
  bool faceLeft = false;

  /// Indicates the character is actively jumping (not just in the air).
  /// Typically this means the jump button is being held down.
  bool jumping = false;

  /// When true moves at [walkSpeed] in the direction the
  /// character is facing.
  bool walking = false;

  /// The walking speed of the character.
  double walkSpeed = 0;

  /// The minimum impulse applied when jumping.
  double minJumpImpulse = 1;

  /// The maximum hold time when jumping.
  double maxJumpHoldTime = 0.35;

  /// The last ground velocity of the character on the horizontal axis.
  double airXVelocity = 0;

  /// Stop walking.
  void stand() => walking = false;

  /// Start walking.
  void walk() => walking = true;

  bool get faceRight => !faceLeft;

  bool get isOnGround => collisionInfo.down;

  @override
  void update(double dt) {
    super.update(dt);

    if (characterAnimation != null) {
      if (velocity.x < 0) {
        characterAnimation!.scale.x = -characterAnimation!.scale.x.abs();
      } else if (velocity.x > 0) {
        characterAnimation!.scale.x = characterAnimation!.scale.x.abs();
      }
    }
  }
}
