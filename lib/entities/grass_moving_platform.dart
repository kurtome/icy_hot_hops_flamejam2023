import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:icy_hot_hops_flamejam2023/main.dart';
import 'package:leap/leap.dart';
import 'package:tiled/tiled.dart';

class GrassMovingPlatform extends MovingPlatform<IcyHotGame> {
  GrassMovingPlatform(super.tiledObject, super.tileSize)
      : super.fromTiledObject() {
    width = 16 * 6;
    height = 16 * 1.5;
    priority = 2;
  }

  late Sprite sprite;

  @override
  @mustCallSuper
  Future<void> onLoad() async {
    final tileset =
        await Flame.images.load('pixel_platformer_tileset/grass/grass_tileset.png');
    sprite = Sprite(
      tileset,
      srcPosition: Vector2(96, 62),
      srcSize: Vector2(16 * 6, 16 * 2),
    );

    add(
      SpriteComponent(
        sprite: sprite,
      ),
    );
  }
}

class GrassMovingPlatformFactory implements TiledObjectHandler {
  @override
  void handleObject(TiledObject object, Layer layer, LeapMap map) {
    final platform = GrassMovingPlatform(object, map.tileSize);
    map.add(platform);
  }

  static Future<GrassMovingPlatformFactory> createFactory() async {
    return GrassMovingPlatformFactory();
  }
}
