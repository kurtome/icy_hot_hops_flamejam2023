import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:icy_hot_hops_flamejam2023/main.dart';
import 'package:leap/leap.dart';
import 'package:tiled/tiled.dart';

class ColdMovingPlatform extends MovingPlatform<IcyHotGame> {
  ColdMovingPlatform(super.tiledObject, super.tileSize)
      : super.fromTiledObject() {
    width = 16 * 6;
    height = 16 * 2;
    priority = 2;
  }

  late Sprite sprite;

  final _moveSpeed = Vector2(2, 2);
  @override
  Vector2 get moveSpeed => _moveSpeed;

  @override
  @mustCallSuper
  Future<void> onLoad() async {
    super.onLoad();

    final tileset = await Flame.images
        .load('pixel_platformer_tileset/ice/ice_tileset.png');
    sprite = Sprite(
      tileset,
      srcPosition: Vector2(97, 64),
      srcSize: Vector2(16 * 6, 16 * 2),
    );

    add(
      SpriteComponent(
        sprite: sprite,
      ),
    );
  }
}

class ColdMovingPlatformFactory implements TiledObjectHandler {
  ColdMovingPlatformFactory();

  @override
  void handleObject(TiledObject object, Layer layer, LeapMap map) {
    final platform = ColdMovingPlatform(object, map.tileSize);
    map.add(platform);
  }

  static Future<ColdMovingPlatformFactory> createFactory() async {
    return ColdMovingPlatformFactory();
  }
}
