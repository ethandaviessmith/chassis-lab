extends CharacterBody2D
class_name Enemy

signal enemy_defeated

var id: String
var enemy_name: String
var hp: int
var max_hp: int
var armor: int
var damage: int
var attack_speed: float
var move_speed: float
var behavior: String
var special_abilities = []

# Combat state
var attack_timer: float = 0.0
var target = null
var is_active: bool = false

# References
@onready var sprite = $Sprite
@onready var health_bar = $HealthBar
@onready var animation_player = $AnimationPlayer
@onready var attack_indicator = $AttackIndicator

func _ready():
    # Set up the sprite emoji
    if sprite and sprite is Label:
        sprite.add_theme_font_size_override("font_size", 48)
    
    # Set up attack indicator
    if attack_indicator and attack_indicator is Label:
        attack_indicator.add_theme_font_size_override("font_size", 32)
    
    update_health_bar()

func initialize_from_data(data: Dictionary):
    enemy_name = data.name
    hp = data.hp
    max_hp = data.hp
    armor = data.get("armor", 0)
    damage = data.damage
    attack_speed = data.attack_speed
    move_speed = data.move_speed
    behavior = data.behavior
    
    # Load special abilities if present
    if "special_abilities" in data:
        special_abilities = data.special_abilities
    
    # Load sprite if specified
    if "sprite" in data and data.sprite != "":
        var texture = load(data.sprite)
        if texture:
            sprite.texture = texture
    
    # Add to enemies group
    add_to_group("enemies")

func _physics_process(delta):
    # Only process if active (set by CombatView)
    if not is_active:
        return
        
    # Find target if we don't have one
    if not target or not is_instance_valid(target):
        target = find_target()
        
    if target:
        process_behavior(delta)

func find_target():
    # Look for player robot in combat group
    var player_robots = get_tree().get_nodes_in_group("player_robot")
    if player_robots.size() > 0:
        return player_robots[0]
    
    # Fallback - look for any player
    var players = get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        return players[0]
    return null

func process_behavior(delta):
    match behavior:
        "default":
            # Basic behavior - move to target and attack when in range
            default_behavior(target, delta)
        "aggressive":
            # Charge directly at target, prioritize getting close for maximum damage
            aggressive_behavior(target, delta)
        "defensive":
            # Stay at mid-range, prioritize survival and steady damage
            defensive_behavior(target, delta)
        "flanking":
            # Try to circle around target and attack from sides
            flanking_behavior(target, delta)
        _:  # Fallback to default
            default_behavior(target, delta)

# Default behavior - straightforward approach and attack
func default_behavior(target_node, delta):
    if target_node:
        var distance = global_position.distance_to(target_node.global_position)
        
        # Move toward target if too far
        if distance > 80:
            move_to_target(target_node)
        else:
            # Stop and attack when close
            velocity = Vector2.ZERO
        
        try_attack(delta)

# Aggressive behavior - charge in fast and hit hard
func aggressive_behavior(target_node, delta):
    if target_node:
        var distance = global_position.distance_to(target_node.global_position)
        
        # Always move toward target, even when close (more aggressive)
        if distance > 50:  # Closer range than default
            var direction = (target_node.global_position - global_position).normalized()
            velocity = direction * move_speed * 1.2  # 20% faster movement
            move_and_slide()
        else:
            velocity = Vector2.ZERO
        
        # More frequent attacks
        try_attack(delta, 1.3)  # 30% faster attack rate

# Defensive behavior - maintain distance and steady damage
func defensive_behavior(target_node, delta):
    if target_node:
        keep_distance(target_node, 150.0)  # Stay at longer range
        try_attack(delta, 0.8)  # 20% slower but more deliberate attacks

# Flanking behavior - circle around target
func flanking_behavior(target_node, delta):
    if target_node:
        var distance = global_position.distance_to(target_node.global_position)
        
        if distance > 120:
            # Move closer if too far
            move_to_target(target_node)
        elif distance < 80:
            # Back away if too close
            var direction = (global_position - target_node.global_position).normalized()
            velocity = direction * move_speed * 0.8
            move_and_slide()
        else:
            # Circle around target
            circle_target(target_node)
        
        try_attack(delta)

func move_to_target(target_node):
    var direction = (target_node.global_position - global_position).normalized()
    velocity = direction * move_speed
    move_and_slide()

func keep_distance(target_node, ideal_distance):
    var direction = (global_position - target_node.global_position)
    var distance = direction.length()
    
    if distance < ideal_distance * 0.8:
        # Too close, back up
        velocity = direction.normalized() * move_speed
    elif distance > ideal_distance * 1.2:
        # Too far, move closer
        velocity = -direction.normalized() * move_speed
    else:
        # Good distance, strafe
        velocity = direction.normalized().rotated(PI/2) * move_speed * 0.5
    
    move_and_slide()

func circle_target(target_node):
    var to_target = target_node.global_position - global_position
    var circle_direction = to_target.rotated(PI/2).normalized()
    
    # Mix of circling and approaching
    var distance = to_target.length()
    var approach_weight = clamp(distance / 200.0 - 0.5, 0.0, 1.0)
    var final_direction = circle_direction.lerp(-to_target.normalized(), approach_weight)
    
    velocity = final_direction * move_speed
    move_and_slide()

func try_attack(delta, speed_modifier: float = 1.0):
    attack_timer += delta
    
    # Can attack based on attack speed (attacks per second) with behavior modifier
    var effective_attack_speed = attack_speed * speed_modifier
    if attack_timer >= 1.0 / effective_attack_speed:
        attack_timer = 0.0
        attack_target(target)

func attack_target(target_node):
    # Simple direct attack
    if target_node and is_instance_valid(target_node) and global_position.distance_to(target_node.global_position) < 100:
        if target_node.has_method("take_damage"):
            target_node.take_damage(damage)
            print(enemy_name, " attacked for ", damage, " damage")
        play_attack_animation()

func take_damage(amount: int):
    var actual_damage = max(0, amount - armor)
    hp -= actual_damage
    hp = max(0, hp)
    update_health_bar()
    play_hurt_animation()
    
    print(enemy_name, " took ", actual_damage, " damage (", hp, "/", max_hp, " HP)")
    
    # Check for defeat
    if hp <= 0:
        emit_signal("enemy_defeated")
    
    # Check for special ability triggers
    for ability in special_abilities:
        if ability.trigger == "on_damage":
            activate_special_ability(ability)

func activate_special_ability(ability: Dictionary):
    match ability.effect:
        "self_heal":
            hp += int(max_hp * 0.1)  # Heal 10% of max HP
            hp = min(hp, max_hp)
            update_health_bar()
        "speed_boost":
            move_speed *= 1.5
            await get_tree().create_timer(3.0).timeout
            move_speed /= 1.5
        # Add more special abilities as needed

func update_health_bar():
    if health_bar:
        health_bar.value = 100.0 * hp / max_hp

func play_attack_animation():
    if animation_player and animation_player.has_animation("attack"):
        animation_player.play("attack")
    else:
        # Simple feedback without animation
        sprite.scale = Vector2(1.2, 1.2)
        await get_tree().create_timer(0.1).timeout
        sprite.scale = Vector2(1.0, 1.0)

func play_hurt_animation():
    if animation_player and animation_player.has_animation("hurt"):
        animation_player.play("hurt")
    else:
        # Simple feedback without animation
        sprite.modulate = Color(1, 0.5, 0.5)  # Red tint
        await get_tree().create_timer(0.1).timeout
        sprite.modulate = Color(1, 1, 1)

func get_armor() -> int:
    return armor

func is_defeated() -> bool:
    return hp <= 0

# Methods for CombatView integration
func set_target(new_target):
    target = new_target

func activate():
    is_active = true
    print(enemy_name, " activated for combat")

func deactivate():
    is_active = false
