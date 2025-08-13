extends CharacterBody2D
class_name Enemy

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

# References
@onready var sprite = $Sprite
@onready var health_bar = $HealthBar
@onready var animation_player = $AnimationPlayer

func _ready():
    update_health_bar()

func initialize_from_data(data: Dictionary):
    id = data.id
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
    # Only process during combat
    var combat_resolver = get_node("/root/Managers/CombatResolver")
    if not combat_resolver.combat_active:
        return
        
    # Find target if we don't have one
    if not target or not is_instance_valid(target):
        target = find_target()
        
    if target:
        process_behavior(delta)

func find_target():
    # Default targeting - player robot
    var player = get_tree().get_nodes_in_group("player")
    if player.size() > 0:
        return player[0]
    return null

func process_behavior(delta):
    match behavior:
        "aggressive":
            move_to_target(target)
            try_attack(delta)
        "defensive":
            # Stay at mid-range and attack
            keep_distance(target, 150.0)
            try_attack(delta)
        "flanking":
            # Try to circle around target
            circle_target(target)
            try_attack(delta)
        _:  # Default
            move_to_target(target)
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

func try_attack(delta):
    attack_timer += delta
    
    # Can attack based on attack speed (attacks per second)
    if attack_timer >= 1.0 / attack_speed:
        attack_timer = 0.0
        attack_target(target)

func attack_target(target_node):
    # Simple direct attack
    if target_node and is_instance_valid(target_node) and global_position.distance_to(target_node.global_position) < 100:
        var combat_resolver = get_node("/root/Managers/CombatResolver")
        combat_resolver.apply_damage(self, target_node, damage)
        play_attack_animation()

func take_damage(amount: int):
    hp -= amount
    update_health_bar()
    play_hurt_animation()
    
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
