
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

class TransparentGame extends FlameGame {
  @override
  Color backgroundColor() => Colors.transparent;
}

class PlayerGame extends TransparentGame with TapCallbacks {
  final VoidCallback shootCallback;
  late Player player;

  PlayerGame({required this.shootCallback});

  @override
  Future<void> onLoad() async {
    player = Player(shootCallback: shootCallback);
    add(player);
  }

  @override
  void onTapDown(TapDownEvent event) {
    player.onTapDown(event);
  }
}


class FlameAudio {
}

class Player extends SpriteComponent with HasGameRef, TapCallbacks {
  double cooldown = 0.5;
  double lastShotTime = 0;
  bool isTilting = false;
  double tiltAmount = -0.2;
  double tiltDuration = 0.2;
  double tiltTimer = 0;

  Player({required VoidCallback shootCallback}) : super(size: Vector2(320, 320)); // make it bigger

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('player/player_default.png');
    anchor = Anchor.bottomRight;
    position = Vector2(
      gameRef.size.x+10, // right padding
      gameRef.size.y, // bottom padding
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isTilting) {
      tiltTimer -= dt;
      if (tiltTimer > 0) {
        angle = tiltAmount * (tiltTimer / tiltDuration);
      } else {
        angle = 0;
        isTilting = false;
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final now = gameRef.currentTime();
    if (now - lastShotTime >= cooldown) {
      lastShotTime = now;
      _shoot();
    }
  }

  void _shoot() {
    isTilting = true;
    tiltTimer = tiltDuration;

    final player = AudioPlayer();
    player.play(AssetSource('music/gunshot.mp3'));
  }
}


