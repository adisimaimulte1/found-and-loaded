import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Bullet extends SpriteComponent with HasGameRef, CollisionCallbacks {
  final Vector2 velocity;

  Bullet({required this.velocity}) : super(size: Vector2(24, 48));

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('bullet/bullet_default.png'); // your new design
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    // Auto remove when off-screen
    if (position.y < -size.y || position.y > gameRef.size.y + size.y) {
      removeFromParent();
    }
  }
}