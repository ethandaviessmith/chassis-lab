extends BaseFighter
class_name Enemy

signal enemy_defeated  # Also emits BaseFighter's fighter_defeated signal

var id: String
var enemy_name: String
var damage: int = 1
var behavior: String = "default"
var special_abilities = []
var attack_timer: float = 0.0

# Enemy-specific properties
# We'll use energy and max_energy from BaseFighter instead of hp/max_hp
# These functions provide compatibility with existing code
func get_hp() -> int:
    return energy
    
func get_max_hp() -> int:
    return max_energy

# References
@onready var sprite = $Sprite
@onready var attack_indicator = $AttackIndicator
var enemy_visuals: EnemyVisuals
@onready var robot_visuals = $RobotVisuals  # Reference to RobotVisuals node

# Combat indicators with emojis
var INDICATORS = {
    "melee_attack": "🗡️",
    "range_attack": "🏹",
    "shield": "🛡️",
    "heal": "❤️",
    "overheat": "🔥",
    "cooldown": "❄️",
}

func _ready():
    # Call BaseFighter's _ready first
    super._ready()
    
    # Set up the enemy visuals - fallback for compatibility
    enemy_visuals = EnemyVisuals.new()
    add_child(enemy_visuals)
    enemy_visuals.visible = false  # Hide by default since we'll use RobotVisuals
    
    # Hide old sprite if present
    if sprite:
        sprite.visible = false
    
    # Set up attack indicator
    if attack_indicator and attack_indicator is Label:
        attack_indicator.add_theme_font_size_override("font_size", 32)
    
    # Initialize robot visuals with random parts
    if robot_visuals:
        setup_robot_visuals()
    
    update_bars()

# Set up random robot parts for the enemy
func setup_robot_visuals():
    # Generate random robot parts
    var robot_parts = generate_random_robot_parts()
    
    # Pass to robot visuals
    if robot_visuals:
        robot_visuals.initialize_from_robot_parts(robot_parts)

# Generate random robot parts based on enemy type/level
func generate_random_robot_parts() -> Dictionary:
    var enemy_robot_parts = {}
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    
    # Basic random head
    enemy_robot_parts["head"] = {
        "name": "Enemy Head",
        "type": "Head",
        "frame_index": rng.randi_range(30, 33), # Random head frame
        "frames": 1,
        "effects": []
    }
    
    # Basic random core
    enemy_robot_parts["core"] = {
        "name": "Enemy Core",
        "type": "Core",
        "frame_index": rng.randi_range(40, 43), # Random core frame
        "frames": 1,
        "effects": []
    }
    
    # Basic random left arm
    enemy_robot_parts["left_arm"] = {
        "name": "Enemy Left Arm",
        "type": "Arm",
        "frame_index": rng.randi_range(20, 23), # Random left arm frame
        "frames": 1,
        "effects": []
    }
    
    # Basic random right arm
    enemy_robot_parts["right_arm"] = {
        "name": "Enemy Right Arm",
        "type": "Arm",
        "frame_index": rng.randi_range(10, 13), # Random right arm frame
        "frames": 1,
        "effects": []
    }
    
    # Basic random legs
    enemy_robot_parts["legs"] = {
        "name": "Enemy Legs",
        "type": "Legs",
        "frame_index": rng.randi_range(0, 3), # Random legs frame
        "frames": 1,
        "effects": []
    }
    
    return enemy_robot_parts

func initialize_from_data(data: Dictionary, view: CombatView):
    enemy_name = data.name
    energy = data.hp
    max_energy = data.hp
    armor = data.get("armor", 0)
    damage = data.damage
    attack_speed = data.attack_speed
    move_speed = data.move_speed
    behavior = data.behavior
    
    # Load attack types and ranges if present
    if "attack_type" in data:
        attack_types = data.attack_type
    
    if "attack_range" in data:
        attack_ranges = data.attack_range
        
    # Make sure arrays are same length, otherwise use defaults
    if attack_types.size() != attack_ranges.size():
        attack_types = ["melee"]
        attack_ranges = [1.0]
    
    # Load special abilities if present
    if "special_abilities" in data:
        special_abilities = data.special_abilities
    
    # Load sprite if specified
    if "sprite" in data and data.sprite != "":
        var texture = load(data.sprite)
        if texture:
            sprite.texture = texture
    
    # Find combat view
    combat_view = view
    
    # Check for robot parts data
    if "robot_parts" in data and data.robot_parts is Dictionary:
        # Use provided robot parts data
        if robot_visuals:
            robot_visuals.initialize_from_robot_parts(data.robot_parts)
    else:
        # Use randomly generated parts
        if robot_visuals:
            setup_robot_visuals()

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

# Using BaseFighter's find_target implementation

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
    
    # Update visuals for walking animation
    if robot_visuals:
        robot_visuals.start_walking()
    elif enemy_visuals:
        enemy_visuals.start_walking()

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
    # Check if enemy is defeated (energy <= 0)
    if energy <= 0:
        return  # Don't attack if defeated

    attack_timer += delta
    
    # Add randomization to attack speed (±15%)
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    var speed_variation = rng.randf_range(0.85, 1.15)
    
    # Can attack based on attack speed with randomization and behavior modifier
    var effective_attack_speed = attack_speed * speed_modifier * speed_variation
    
    if attack_timer >= 1.0 / effective_attack_speed:
        attack_timer = 0.0
        
        # Get current attack range
        var current_range = attack_ranges[current_attack_index] * 100.0  # Convert to pixels (approx)
        
        # Get distance to target
        if target and is_instance_valid(target):
            var distance = global_position.distance_to(target.global_position)
            
            # Check if within range for this attack type
            if distance <= current_range:
                attack_target(target)
            else:
                # Not in range for current attack type, try next attack type
                current_attack_index = (current_attack_index + 1) % attack_types.size()

func attack_target(target_node):
    # No valid target
    if not target_node or not is_instance_valid(target_node):
        return
    
    # Get current attack type and range
    var attack_type = attack_types[current_attack_index]
    var attack_range = attack_ranges[current_attack_index] * 100.0  # Convert to pixels (approx)
    
    # Get distance to target
    var distance = global_position.distance_to(target_node.global_position)
    
    # Check if within range for this attack type
    if distance <= attack_range:
        # Apply damage randomization (±20%)
        var rng = RandomNumberGenerator.new()
        rng.randomize()
        var damage_variation = rng.randf_range(0.8, 1.2)
        var varied_damage = round(damage * damage_variation)
        varied_damage = max(1, varied_damage)  # Ensure minimum damage of 1
        
        # Attack based on type
        if attack_type == "melee":
            # Direct melee attack
            if target_node.has_method("take_damage"):
                target_node.take_damage(varied_damage)
                print(enemy_name, " attacked for ", varied_damage, " damage with melee")
                
                # Play attack sound
                Sound.play_attack()
                
                # Show attack indicator via combat view
                if combat_view:
                    combat_view.show_combat_effect("melee_attack", self)
                    combat_view.show_damage_number(damage, target_node)
            
        elif attack_type == "range":
            # Ranged attack - fire a projectile
            # Play ranged attack sound
            Sound.play_range_attack()  # Higher pitch for ranged attacks
            
            if combat_view:
                print(enemy_name, " fired a projectile for ", varied_damage, " damage")
                combat_view.show_combat_effect("range_attack", self)
                combat_view.fire_projectile(self, target_node.global_position, varied_damage, attack_range)
        
        # Cycle to next attack type
        current_attack_index = (current_attack_index + 1) % attack_types.size()
        
        # Play attack animation
        play_attack_animation()

func take_damage(amount: int):
    # Apply randomization to damage taken (±15%)
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    var damage_variation = rng.randf_range(0.85, 1.15)
    var varied_amount = round(amount * damage_variation)
    
    # Calculate actual damage
    var actual_damage = max(0, varied_amount - armor)
    energy -= actual_damage
    energy = max(0, energy)
    update_bars()
    
    print(enemy_name, " took ", actual_damage, " damage (", energy, "/", max_energy, " HP)")
    
    # Show shield indicator if armor reduced damage significantly
    if armor > 0 and amount > actual_damage and combat_view:
        combat_view.show_combat_effect("shield", self)
    
    # Use visuals system for hit animation
    if robot_visuals:
        robot_visuals.play_hit()
    elif enemy_visuals:
        enemy_visuals.play_hit()
    
    # Check for defeat
    if energy <= 0:
        # Play death animation before signaling defeat
        if robot_visuals:
            var tween = robot_visuals.play_death_animation()
            # Wait for animation to finish
            await tween.finished
        elif enemy_visuals:
            var tween = enemy_visuals.play_death_animation()
            # Wait for animation to finish
            await tween.finished
        
        # Signal defeat
        emit_signal("enemy_defeated")
        emit_signal("fighter_defeated")
    
    # Check for special ability triggers
    for ability in special_abilities:
        if ability.trigger == "on_damage":
            activate_special_ability(ability)

func activate_special_ability(ability: Dictionary):
    match ability.effect:
        "self_heal":
            energy += int(max_energy * 0.1)  # Heal 10% of max energy
            energy = min(energy, max_energy)
            update_bars()
            if combat_view:
                combat_view.show_combat_effect("heal", self)
        "speed_boost":
            move_speed *= 1.5
            if combat_view:
                combat_view.show_combat_effect("cooldown", self)  # Using cooldown as a speed boost indicator
            await get_tree().create_timer(3.0).timeout
            move_speed /= 1.5
        "shield_up":
            armor += 2  # Temporary armor boost
            if combat_view:
                combat_view.show_combat_effect("shield", self)
            await get_tree().create_timer(2.0).timeout
            armor -= 2
        # Add more special abilities as needed

# Override the update_bars method from BaseFighter
func update_bars():
    # Use BaseFighter's method
    super.update_bars()

func play_attack_animation():
    # Use our visuals system for attack animation
    if robot_visuals:
        robot_visuals.play_attack()
    elif enemy_visuals:
        enemy_visuals.play_attack()
    else:
        # Call BaseFighter's animation method
        super.play_attack_animation()

func play_hurt_animation():
    # Use visuals system for hit animation
    if robot_visuals:
        robot_visuals.play_hit()
    elif enemy_visuals:
        enemy_visuals.play_hit()
    else:
        # Call BaseFighter's animation method
        super.play_hurt_animation()

# Already inherited from BaseFighter
#func get_armor() -> int:
#    return armor

# Already inherited from BaseFighter
#func is_defeated() -> bool:
#    return energy <= 0

# Methods for CombatView integration
func set_target(new_target):
    target = new_target

func activate():
    is_active = true
    print(enemy_name, " activated for combat")

func deactivate():
    is_active = false
