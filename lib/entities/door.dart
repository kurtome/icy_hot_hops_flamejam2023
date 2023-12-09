import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/foundation.dart';
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

  late final String? destinationMap;
  late final TiledObject? destinationObject;

  void enter(PhysicalEntity other) {
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
    add(
      SpriteAnimationComponent(
        playing: false,
        position: Vector2(-16, -16),
        animation: SpriteAnimation.fromFrameData(
          image,
          SpriteAnimationData.sequenced(
            amount: 5,
            stepTime: 0.1,
            textureSize: Vector2(16 * 3, 16 * 2),
          ),
        ),
      ),
    );
  }
}

class DoorFactory implements TiledObjectHandler {
  @override
  void handleObject(TiledObject object, Layer layer, LeapMap map) {
    final component = Door(object, layer as ObjectGroup);
    map.add(component);
  }
}
