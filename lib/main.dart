import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:icy_hot_hops_flamejam2023/entities/basic_ladder.dart';
import 'package:icy_hot_hops_flamejam2023/entities/cave_moving_platform.dart';
import 'package:icy_hot_hops_flamejam2023/entities/coin.dart';
import 'package:icy_hot_hops_flamejam2023/entities/door.dart';
import 'package:icy_hot_hops_flamejam2023/entities/enemies/caveman_boss.dart';
import 'package:icy_hot_hops_flamejam2023/entities/enemies/slug.dart';
import 'package:icy_hot_hops_flamejam2023/entities/enemies/snowman_boss.dart';
import 'package:icy_hot_hops_flamejam2023/entities/enemy_bumper.dart';
import 'package:icy_hot_hops_flamejam2023/entities/grass_moving_platform.dart';
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

  var _currentLevel = 'map_level_tutorial.tmx';

  // Any level not in this map will use the default music
  final _levelMusic = {
    'map_level_cave_2.tmx': 'just-a-dream-wake-up.mp3',
    'map_level_cave_3.tmx': 'waiting-time.mp3',
    'map_level_cold_2.tmx': 'just-a-dream-wake-up.mp3',
    'map_level_cold_3.tmx': 'waiting-time.mp3',
    'map_level_credits.tmx': 'just-a-dream-wake-up.mp3',
  };

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

    _playLevelBgm();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    tiledObjectHandlers = {
      'Coin': await CoinFactory.createFactory(),
      'ColdMovingPlatform': await ColdMovingPlatformFactory.createFactory(),
      'CaveMovingPlatform': await CaveMovingPlatformFactory.createFactory(),
      'GrassMovingPlatform': await GrassMovingPlatformFactory.createFactory(),
      'BasicLadder': await BasicLadderFactory.createFactory(),
      'InfoSign': InfoSignFactory(),
      'Door': DoorFactory(),
      'Bumper': EnemyBumperFactory(),
      'Enemy': SlugFactory(),
      'SnowmanBossTrigger': SnowmanBossTriggerFactory(),
      'CavemanBossTrigger': CavemanBossTriggerFactory(),
    };

    groundTileHandlers = {
      'OneWayTopPlatform': OneWayTopPlatformHandler(),
    };

    // Default the camera size to the bounds of the Tiled map.
    camera = CameraComponent.withFixedResolution(
      world: world,
      width: tileSize * 32,
      height: tileSize * 20,
    );

    input = IcyHotInput();
    add(input);

    await _loadLevel();

    player = Player();
    world.add(player!);
    camera.follow(player!);

    camera.viewport.add(Hud());
  }

  @override
  void onMapUnload(LeapMap map) {
    player?.removeFromParent();
  }

  @override
  void onMapLoaded(LeapMap map) {
    if (player != null) {
      world.add(player!);
      player!.resetPosition();
    }
  }

  Future<void> goToLevel(String mapName) async {
    _currentLevel = mapName;
    await _loadLevel();
  }

  void _playLevelBgm() {
    var track = 'village_music.mp3';
    if (_levelMusic.containsKey(_currentLevel)) {
      track = _levelMusic[_currentLevel]!;
    }
    FlameAudio.bgm.play(track);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // On web, we need to wait for a user interaction before playing any sound.
    if (input.justPressed && !FlameAudio.bgm.isPlaying) {
      _playLevelBgm();
    }
  }

  Future<void> reloadLevel() async {
    await _loadLevel();
  }
}
