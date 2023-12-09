import 'package:leap/leap.dart';
import 'package:tiled/tiled.dart';

class EnemyBumper extends PhysicalEntity {
  EnemyBumper(TiledObject tiledObject) : super(static: true) {
    width = tiledObject.width;
    height = tiledObject.height;
    x = tiledObject.x;
    y = tiledObject.y;
  }
}

class EnemyBumperFactory implements TiledObjectHandler {
  @override
  void handleObject(TiledObject object, Layer layer, LeapMap map) {
    map.add(EnemyBumper(object));
  }
}
