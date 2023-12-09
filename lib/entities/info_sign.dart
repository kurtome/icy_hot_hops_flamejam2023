import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:icy_hot_hops_flamejam2023/main.dart';
import 'package:leap/leap.dart';
import 'package:tiled/tiled.dart';

class InfoSign extends PhysicalEntity<IcyHotGame> {
  InfoSign(TiledObject object)
      : super(
          position: Vector2(object.x, object.y),
          size: Vector2(object.width, object.height),
          static: true,
        ) {
    text = object.properties.getValue<String>('Text') ??
        'Lorem ipsum mising text.';
  }

  late final String text;
  TextBoxComponent? textBoxComponent;

  void activateText() {
    if (textBoxComponent == null) {
      textBoxComponent = InfoTextBox(
        text: text,
        position: Vector2(-16, -48),
      );
      add(textBoxComponent!);
    }
  }

  @override
  @mustCallSuper
  void update(double dt) {
    super.update(dt);
    if (textBoxComponent?.finished ?? false) {
      textBoxComponent!.removeFromParent();
      textBoxComponent = null;
    }
  }
}

class InfoTextBox extends TextBoxComponent {
  InfoTextBox({super.text, super.position})
      : super(
          boxConfig:
              TextBoxConfig(dismissDelay: 3, margins: const EdgeInsets.all(4)),
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white,
            ),
          ),
        );

  final bgPaint = Paint()..color = Colors.black.withOpacity(0.5);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), bgPaint);
    super.render(canvas);
  }
}

class InfoSignFactory implements TiledObjectHandler {
  @override
  void handleObject(TiledObject object, Layer layer, LeapMap map) {
    final component = InfoSign(object);
    map.add(component);
  }
}
