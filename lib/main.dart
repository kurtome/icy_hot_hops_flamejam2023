import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:icy_hot_hops_flamejam2023/entities/basic_ladder.dart';
import 'package:icy_hot_hops_flamejam2023/entities/coin.dart';
import 'package:icy_hot_hops_flamejam2023/entities/door.dart';
import 'package:icy_hot_hops_flamejam2023/entities/info_sign.dart';
import 'package:icy_hot_hops_flamejam2023/entities/player.dart';
import 'package:icy_hot_hops_flamejam2023/entities/snowy_moving_platform.dart';
import 'package:icy_hot_hops_flamejam2023/input.dart';
import 'package:icy_hot_hops_flamejam2023/ui/hud.dart';
import 'package:leap/leap.dart';

void main() {
  runApp(GameWidget(game: IcyHotGame(tileSize: 16)));
}

class IcyHotGame extends LeapGame with HasKeyboardHandlerComponents {
  IcyHotGame({
    required super.tileSize,
  });

  Player? player;
  late final IcyHotInput input;
  late final Map<String, TiledObjectHandler> tiledObjectHandlers;
  late final Map<String, GroundTileHandler> groundTileHandlers;

  var _currentLevel = 'map_level_0.tmx';

  Future<void> _loadLevel() async {
    await loadWorldAndMap(
      tiledMapPath: _currentLevel,
      tiledObjectHandlers: tiledObjectHandlers,
      groundTileHandlers: groundTileHandlers,
    );

    // Don't let the camera move outside the bounds of the map, inset
    // by half the viewport size to the edge of the camera if flush with the
    // edge of the map.
    final inset = camera.viewport.virtualSize;
    camera.setBounds(
      Rectangle.fromLTWH(
        inset.x / 2,
        inset.y / 2,
        leapMap.width - inset.x,
        leapMap.height - inset.y,
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    tiledObjectHandlers = {
      'Coin': await CoinFactory.createFactory(),
      'SnowyMovingPlatform': await SnowyMovingPlatformFactory.createFactory(),
      'BasicLadder': await BasicLadderFactory.createFactory(),
      'InfoSign': InfoSignFactory(),
      'Door': DoorFactory(),
    };

    groundTileHandlers = {
      'OneWayTopPlatform': OneWayTopPlatformHandler(),
    };

    // Default the camera size to the bounds of the Tiled map.
    camera = CameraComponent.withFixedResolution(
      world: world,
      width: tileSize * 32,
      height: tileSize * 16,
    );

    input = IcyHotInput();
    add(input);

    await _loadLevel();

    player = Player();
    world.add(player!);
    camera.follow(player!);

    if (!FlameAudio.bgm.isPlaying) {
      FlameAudio.bgm.play('village_music.mp3');
    }

    camera.viewport.add(Hud());
  }

  @override
  void onMapUnload(LeapMap map) {
    player?.removeFromParent();
  }

  @override
  void onMapLoaded(LeapMap map) {
    if (player != null) {
      player = Player();
      world.add(player!);
      camera.follow(player!);
    }
  }

  Future<void> goToLevel(String mapName) async {
    _currentLevel = mapName;
    await _loadLevel();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // On web, we need to wait for a user interaction before playing any sound.
    if (input.justPressed && !FlameAudio.bgm.isPlaying) {
      FlameAudio.bgm.play('village_music.mp3');
    }
  }
}
