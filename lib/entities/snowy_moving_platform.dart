import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:icy_hot_hops_flamejam2023/main.dart';
import 'package:leap/leap.dart';
import 'package:tiled/tiled.dart';

class SnowyMovingPlatform extends MovingPlatform<IcyHotGame> {
  SnowyMovingPlatform(TiledObject tiledObject, this.sprite, double tileSize)
      : super.fromTiledObject(tiledObject, tileSize) {
    width = 16 * 6;
    height = 16 * 2;
    priority = 2;

    add(
      SpriteComponent(
        sprite: sprite,
      ),
    );
  }

  final Sprite sprite;
}

class SnowyMovingPlatformFactory implements TiledObjectHandler {
  late final Sprite sprite;

  SnowyMovingPlatformFactory(this.sprite);

  @override
  void handleObject(TiledObject object, Layer layer, LeapMap map) {
    final platform = SnowyMovingPlatform(object, sprite, map.tileSize);
    map.add(platform);
  }

  static Future<SnowyMovingPlatformFactory> createFactory() async {
    final tileset =
        await Flame.images.load('pixel_platformer_tileset/ice/ice_tileset.png');
    final sprite = Sprite(
      tileset,
      srcPosition: Vector2(97, 64),
      srcSize: Vector2(16 * 6, 16 * 2),
    );
    return SnowyMovingPlatformFactory(sprite);
  }
}
