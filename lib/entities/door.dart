import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/foundation.dart';
import 'package:icy_hot_hops_flamejam2023/entities/player.dart';
import 'package:icy_hot_hops_flamejam2023/main.dart';
import 'package:leap/leap.dart';
import 'package:tiled/tiled.dart';

class Door extends PhysicalEntity<IcyHotGame> {
  Door(TiledObject object, ObjectGroup layer)
      : super(
          position: Vector2(object.x, object.y),
          size: Vector2(object.width, object.height),
          static: true,
        ) {
    destinationMap = object.properties.getValue<String>('DestinationMap');
    final destinationObjectId =
        object.properties.getValue<int>('DestinationObject');
    if (destinationObjectId != null) {
      destinationObject =
          layer.objects.firstWhere((obj) => obj.id == destinationObjectId);
    }
  }

  Door.placedToMap({
    required super.position,
    required super.size,
    this.destinationMap,
  }) : super(
          static: true,
        );

  late final String? destinationMap;
  late final TiledObject? destinationObject;
  late SpriteAnimationComponent spriteAnimation;

  void startEnter(Player other) {
    spriteAnimation.playing = true;
    final status = EnteringDoorStatus(this, other);
    other.statuses.add(status);
    other.add(status);
  }

  void enter(Player other) {
    spriteAnimation.playing = false;
    spriteAnimation.animationTicker?.reset();

    other.characterAnimation!.opacity = 1;

    other.statuses.removeWhere((element) {
      // this is a hack, but it's the easiest way to remove the status component
      element.removeFromParent();
      return element is EnteringDoorStatus;
    });

    if (destinationMap != null) {
      game.goToLevel(destinationMap!);
    } else if (destinationObject != null) {
      other.x = destinationObject!.x;
      other.y = destinationObject!.y;
    }
  }

  @override
  @mustCallSuper
  Future<void> onLoad() async {
    super.onLoad();
    final image = await Flame.images.load('dungeon_toolkit/door_animation.png');
    spriteAnimation = SpriteAnimationComponent(
      playing: false,
      position: Vector2(-16, -16),
      animation: SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          loop: false,
          amount: 5,
          stepTime: 0.1,
          textureSize: Vector2(16 * 3, 16 * 2),
        ),
      ),
    );
    add(spriteAnimation);
  }
}

class EnteringDoorStatus extends StatusComponent with IgnoredByWorld {
  final Door door;
  final Player player;
  double timeElapsed = 0;

  EnteringDoorStatus(this.door, this.player);

  @override
  @mustCallSuper
  void update(double dt) {
    timeElapsed += dt;
    if (timeElapsed > 1) {
      door.enter(player);
      player.characterAnimation!.opacity = 1;
    } else {
      player.characterAnimation!.opacity = 1 - timeElapsed;
    }
  }
}

class DoorFactory implements TiledObjectHandler {
  @override
  void handleObject(TiledObject object, Layer layer, LeapMap map) {
    final component = Door(object, layer as ObjectGroup);
    map.add(component);
  }
}
