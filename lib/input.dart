import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:leap/leap.dart';

class IcyHotInput extends Component
    with HasGameRef<LeapGame>, AppLifecycleAware, KeyboardHandler {
  double pressedTime = 0;
  bool justPressed = false;

  @override
  void appLifecycleStateChanged(
    AppLifecycleState previous,
    AppLifecycleState current,
  ) {
    // When the app is backgrounded or foregrounded, reset inputs to avoid
    // any weirdness with tap/key state getting out of sync.
    keysDown.clear();
    pressedTime = 0;
    justPressed = false;
  }

  bool get _appFocused =>
      game.appState == AppLifecycleState.resumed ||
      game.appState == AppLifecycleState.detached;

  IcyHotInput() {
    leftKeys = {
      PhysicalKeyboardKey.arrowLeft,
      PhysicalKeyboardKey.keyA,
      PhysicalKeyboardKey.keyH,
    };

    rightKeys = {
      PhysicalKeyboardKey.arrowRight,
      PhysicalKeyboardKey.keyD,
      PhysicalKeyboardKey.keyL,
    };

    upKeys = {
      PhysicalKeyboardKey.arrowUp,
      PhysicalKeyboardKey.keyW,
      PhysicalKeyboardKey.keyK,
    };

    downKeys = {
      PhysicalKeyboardKey.arrowDown,
      PhysicalKeyboardKey.keyS,
      PhysicalKeyboardKey.keyJ,
    };

    jumpKeys = {
      PhysicalKeyboardKey.space,
    };

    actionKeys = {
      PhysicalKeyboardKey.enter,
      PhysicalKeyboardKey.shiftLeft,
    };

    relevantKeys = leftKeys
        .union(rightKeys)
        .union(upKeys)
        .union(downKeys)
        .union(jumpKeys)
        .union(actionKeys);
  }

  @override
  void update(double dt) {
    if (isPressed) {
      justPressed = pressedTime == 0;
      pressedTime += dt;
    } else {
      pressedTime = 0;
    }

    keysDown.forEach((key) {
      if (!keysAlreadyPressed.contains(key)) {
        keysJustPressed.add(key);
        keysAlreadyPressed.add(key);
      } else {
        keysJustPressed.remove(key);
      }
    });
  }

  late final Set<PhysicalKeyboardKey> leftKeys;
  late final Set<PhysicalKeyboardKey> rightKeys;
  late final Set<PhysicalKeyboardKey> upKeys;
  late final Set<PhysicalKeyboardKey> downKeys;
  late final Set<PhysicalKeyboardKey> actionKeys;
  late final Set<PhysicalKeyboardKey> jumpKeys;
  late final Set<PhysicalKeyboardKey> relevantKeys;

  final Set<PhysicalKeyboardKey> keysDown = {};
  final Set<PhysicalKeyboardKey> keysJustPressed = {};
  final Set<PhysicalKeyboardKey> keysAlreadyPressed = {};

  bool get isPressed => _appFocused && keysDown.isNotEmpty;

  bool get isPressedLeft =>
      _appFocused && isPressed && keysDown.intersection(leftKeys).isNotEmpty;

  bool get isJustPressedLeft =>
      _appFocused &&
      isPressed &&
      keysJustPressed.intersection(leftKeys).isNotEmpty;

  bool get isPressedRight =>
      _appFocused && isPressed && keysDown.intersection(rightKeys).isNotEmpty;

  bool get isJustPressedRight =>
      _appFocused &&
      isPressed &&
      keysJustPressed.intersection(rightKeys).isNotEmpty;

  bool get isPressedUp =>
      _appFocused && isPressed && keysDown.intersection(upKeys).isNotEmpty;

  bool get isJustPressedUp =>
      _appFocused &&
      isPressed &&
      keysJustPressed.intersection(upKeys).isNotEmpty;

  bool get isPressedDown =>
      _appFocused && isPressed && keysDown.intersection(downKeys).isNotEmpty;

  bool get isJustPressedDown =>
      _appFocused &&
      isPressed &&
      keysJustPressed.intersection(downKeys).isNotEmpty;

  bool get isPressedJump =>
      _appFocused && isPressed && keysDown.intersection(jumpKeys).isNotEmpty;

  bool get isJustPressedJump =>
      _appFocused &&
      isPressed &&
      keysJustPressed.intersection(jumpKeys).isNotEmpty;

  bool get isPressedAction =>
      _appFocused && isPressed && keysDown.intersection(actionKeys).isNotEmpty;

  bool get isJustPressedAction =>
      _appFocused &&
      isPressed &&
      keysJustPressed.intersection(actionKeys).isNotEmpty;

  @override
  bool onKeyEvent(RawKeyEvent keyEvent, Set<LogicalKeyboardKey> keysPressed) {
    // Ignore irrelevant keys.
    if (relevantKeys.contains(keyEvent.physicalKey)) {
      if (keyEvent is RawKeyDownEvent) {
        keysDown.add(keyEvent.physicalKey);
      } else if (keyEvent is RawKeyUpEvent) {
        keysDown.remove(keyEvent.physicalKey);
        keysJustPressed.remove(keyEvent.physicalKey);
        keysAlreadyPressed.remove(keyEvent.physicalKey);
      }
    }
    return true;
  }
}
