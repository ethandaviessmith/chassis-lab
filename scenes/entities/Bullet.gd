extends Area2D
class_name Bullet

signal hit_target(target)

var speed: float = 300.0
var damage: int = 1
var direction: Vector2 = Vector2.RIGHT
var max_range: float = 200.0
var source = null  # Who fired this bullet

@onready var lifetime_timer = $LifetimeTimer

func _ready():
    # Set lifetime based on max_range and speed
    var lifetime = max_range / speed
    lifetime_timer.wait_time = lifetime

func _physics_process(delta):
    position += direction * speed * delta

func setup(source_entity, target_pos: Vector2, damage_amount: int, bullet_range: float):
    source = source_entity
    damage = damage_amount
    max_range = bullet_range
    
    # Calculate direction to target
    direction = (target_pos - global_position).normalized()
    
    # Rotate to face direction
    rotation = direction.angle()
    
    # Update the bullet appearance based on damage
    var bullet_label = $Label
    if bullet_label:
        if damage >= 5:
            bullet_label.text = "●"  # Bigger bullet for higher damage
            bullet_label.add_theme_font_size_override("font_size", 18)
        else:
            bullet_label.text = "•"
            bullet_label.add_theme_font_size_override("font_size", 14)

func _on_body_entered(body):
    if body != source and body.has_method("take_damage"):
        # Don't hit the source that fired the bullet
        body.take_damage(damage)
        emit_signal("hit_target", body)
        queue_free()

func _on_lifetime_timer_timeout():
    # Bullet reached max range without hitting anything
    queue_free()
