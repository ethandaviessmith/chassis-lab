extends CharacterBody2D
class_name RobotFighter

signal robot_updated
signal robot_defeated
signal robot_overheated

# Resources
var energy: int = 10  # Health/energy combined
var max_energy: int = 10
var heat: int = 0
var max_heat: int = 10

# Stats
var move_speed: float = 100.0
var attack_speed: float = 1.0
var armor: int = 0

# Parts data (for stat calculation)
var scrapper = null
var head = null
var core = null
var left_arm = null
var right_arm = null
var legs = null
var utility = null

# Part effects cache
var effects = {}

# Combat sprite (placeholder robot emoji for now)
@onready var combat_sprite = $CombatSprite
@onready var health_bar = $HealthBar
@onready var heat_bar = $HeatBar
@onready var attack_indicator = $AttackIndicator
@onready var animation_player = $AnimationPlayer

# Combat behavior variables
var current_target = null
var last_attack_time = 0.0
var is_combat_active = false

func _ready():
    # Set up the placeholder robot sprite
    if combat_sprite and combat_sprite is Label:
        combat_sprite.text = "🤖"  # Robot emoji placeholder
        combat_sprite.add_theme_font_size_override("font_size", 48)
    
    # Set up attack indicator
    if attack_indicator and attack_indicator is Label:
        attack_indicator.add_theme_font_size_override("font_size", 32)
    
    update_bars()

func _physics_process(delta):
    if is_combat_active:
        process_combat_behavior(delta)

# Build robot stats from chassis slot data
func build_from_chassis(attached_parts: Dictionary):
    # Clear existing parts
    clear_all_parts()
    
    # Reset base stats
    reset_to_base_stats()
    
    # Process slots in specific order for proper stat calculation
    var slot_order = ["scrapper", "head", "core", "arm_left", "arm_right", "legs", "utility"]
    
    print("RobotFighter: Building robot from chassis:")
    for slot_name in slot_order:
        if attached_parts.has(slot_name) and is_instance_valid(attached_parts[slot_name]):
            var card = attached_parts[slot_name]
            if card is Card and card.data.size() > 0:
                print("  - Adding ", slot_name, ": ", card.data.name)
                
                # Convert slot names to robot part names
                var robot_slot = slot_name
                if slot_name == "arm_left":
                    robot_slot = "left_arm"
                elif slot_name == "arm_right":
                    robot_slot = "right_arm"
                
                # Create a part object from card data
                var part_data = create_part_from_card(card.data)
                attach_part(part_data, robot_slot)
    
    print("RobotFighter: Build complete - Energy: ", energy, "/", max_energy, ", Heat: ", heat, "/", max_heat, ", Armor: ", armor)
    update_bars()
    emit_signal("robot_updated")

# Create a part object from card data
func create_part_from_card(card_data: Dictionary):
    # Convert card data to a part object that the robot can use for stats
    var part = {
        "name": card_data.get("name", "Unknown Part"),
        "type": card_data.get("type", "Unknown"),
        "cost": card_data.get("cost", 0),
        "heat": card_data.get("heat", 0),
        "durability": card_data.get("durability", 1),
        "effects": card_data.get("effects", [])
    }
    
    # Parse effects for stat modifications
    if card_data.has("effects"):
        var parsed_effects = []
        for effect in card_data.effects:
            if effect is Dictionary and effect.has("description"):
                # Parse effect description for stat bonuses
                # This is a simplified parser - in a full game you'd have more sophisticated effect definitions
                var desc = effect.description.to_lower()
                if "+2 armor" in desc:
                    parsed_effects.append({"type": "armor", "value": 2})
                elif "gain materials" in desc:
                    parsed_effects.append({"type": "scrapper_bonus", "value": 1})
                # Add more effect parsing as needed
        part.effects = parsed_effects
    
    return part

# Attach a part and apply its effects
func attach_part(part, slot: String):
    match slot:
        "scrapper":
            scrapper = part
        "head":
            head = part
        "core":
            core = part
        "left_arm":
            left_arm = part
        "right_arm":
            right_arm = part
        "legs":
            legs = part
        "utility":
            utility = part
    
    # Apply part effects to stats
    apply_part_effects(part)
    emit_signal("robot_updated")

# Remove a part and its effects
func remove_part(part):
    if scrapper == part:
        scrapper = null
    elif head == part:
        head = null
    elif core == part:
        core = null
    elif left_arm == part:
        left_arm = null
    elif right_arm == part:
        right_arm = null
    elif legs == part:
        legs = null
    elif utility == part:
        utility = null
    
    # Remove part effects
    remove_part_effects(part)
    emit_signal("robot_updated")

# Apply stat effects from a part
func apply_part_effects(part):
    # Apply stat changes from part
    for effect in part.effects:
        match effect.type:
            "max_energy":
                max_energy += effect.value
                energy += effect.value  # Also increase current energy
            "max_heat":
                max_heat += effect.value
            "armor":
                armor += effect.value
            "move_speed_percent":
                move_speed *= (1 + effect.value / 100.0)
            "attack_speed_percent":
                attack_speed *= (1 + effect.value / 100.0)
    
    # Store effects for later removal
    effects[part] = part.effects

# Remove previously applied part effects
func remove_part_effects(part):
    if part in effects:
        var part_effects = effects[part]
        for effect in part_effects:
            match effect.type:
                "max_energy":
                    max_energy -= effect.value
                "max_heat":
                    max_heat -= effect.value
                "armor":
                    armor -= effect.value
                "move_speed_percent":
                    move_speed /= (1 + effect.value / 100.0)
                "attack_speed_percent":
                    attack_speed /= (1 + effect.value / 100.0)
        
        # Remove from effects cache
        effects.erase(part)

# Clear all attached parts
func clear_all_parts():
    scrapper = null
    head = null
    core = null
    left_arm = null
    right_arm = null
    legs = null
    utility = null
    effects.clear()

# Reset stats to base values
func reset_to_base_stats():
    energy = 10
    max_energy = 10
    heat = 0
    max_heat = 10
    move_speed = 100.0
    attack_speed = 1.0
    armor = 0
    effects.clear()

# Combat behavior processing
func process_combat_behavior(delta):
    if not current_target:
        current_target = find_target()
    
    if current_target and is_instance_valid(current_target):
        move_toward_target(current_target)
        try_attack(current_target, delta)
    else:
        # No valid target, stop moving
        velocity = Vector2.ZERO

func find_target():
    # Default targeting - can be overridden by head parts
    var enemies = get_tree().get_nodes_in_group("enemies")
    if enemies.size() > 0:
        # Find closest enemy
        var closest_enemy = null
        var closest_distance = INF
        
        for enemy in enemies:
            if is_instance_valid(enemy):
                var distance = global_position.distance_to(enemy.global_position)
                if distance < closest_distance:
                    closest_distance = distance
                    closest_enemy = enemy
        
        return closest_enemy
    return null

func move_toward_target(target):
    var direction = (target.global_position - global_position).normalized()
    velocity = direction * move_speed
    
    # Apply modifiers from parts
    if heat >= 8:
        velocity *= 0.8  # Slow down when overheating
    
    move_and_slide()

func try_attack(target, _delta):
    # Check if enough time has passed since last attack
    var current_time = Time.get_time_dict_from_system()
    var time_since_last_attack = (current_time.hour * 3600 + current_time.minute * 60 + current_time.second) - last_attack_time
    
    # Simple time-based attack cooldown
    if time_since_last_attack >= (1.0 / attack_speed):
        # Check if close enough to attack
        var distance_to_target = global_position.distance_to(target.global_position)
        if distance_to_target <= 50:  # Attack range
            perform_attack(target)
            last_attack_time = current_time.hour * 3600 + current_time.minute * 60 + current_time.second

func perform_attack(target):
    # Calculate damage based on arms equipped
    var damage = 1  # Base damage
    
    # Add damage from arms
    if left_arm:
        damage += 2  # Example: left arm adds damage
    if right_arm:
        damage += 2  # Example: right arm adds damage
    
    # Apply damage to target
    if target.has_method("take_damage"):
        target.take_damage(damage)
    
    # Show attack animation
    if animation_player and animation_player.has_animation("attack"):
        animation_player.play("attack")
    
    # Generate heat from attacking
    add_heat(1)
    
    print("RobotFighter: Attacked for ", damage, " damage")

# Health and resource management
func take_damage(amount: int):
    var actual_damage = max(0, amount - armor)
    energy -= actual_damage
    energy = max(0, energy)
    
    update_bars()
    print("RobotFighter: Took ", actual_damage, " damage (", amount, " - ", armor, " armor)")
    
    if energy <= 0:
        emit_signal("robot_defeated")

func heal(amount: int):
    energy = min(energy + amount, max_energy)
    update_bars()

func add_heat(amount: int):
    heat = min(heat + amount, max_heat)
    update_bars()
    
    if heat >= max_heat:
        emit_signal("robot_overheated")
        # Overheating penalties could be applied here

func reduce_heat(amount: int):
    heat = max(0, heat - amount)
    update_bars()

# Combat state management
func start_combat():
    is_combat_active = true
    add_to_group("player_robot")  # Make sure enemy can find us
    print("RobotFighter: Combat started")

func end_combat():
    is_combat_active = false
    current_target = null
    velocity = Vector2.ZERO
    print("RobotFighter: Combat ended")

# Status checks
func get_armor() -> int:
    return armor

func is_defeated() -> bool:
    return energy <= 0

func is_overheated() -> bool:
    return heat >= max_heat

func get_combat_effectiveness() -> float:
    # Return a value between 0-1 representing how effective the robot is
    var health_factor = float(energy) / float(max_energy)
    var heat_factor = 1.0 - (float(heat) / float(max_heat))
    return (health_factor + heat_factor) / 2.0

# UI updates
func update_bars():
    if health_bar:
        health_bar.value = 100.0 * energy / max_energy
    
    if heat_bar:
        heat_bar.value = 100.0 * heat / max_heat
        
        # Update heat bar color
        if heat >= max_heat:
            heat_bar.modulate = Color(1, 0, 0)  # Red for overheat
        elif heat >= 8:
            heat_bar.modulate = Color(1, 0.5, 0)  # Orange for high heat
        else:
            heat_bar.modulate = Color(1, 0.8, 0)  # Yellow-orange normal

# Get robot status summary
func get_status_summary() -> String:
    var status = "Energy: " + str(energy) + "/" + str(max_energy)
    status += " | Heat: " + str(heat) + "/" + str(max_heat)
    status += " | Armor: " + str(armor)
    if is_defeated():
        status += " | DEFEATED"
    elif is_overheated():
        status += " | OVERHEATED"
    return status

# Development helper to set placeholder sprite
func set_placeholder_sprite(emoji: String):
    if combat_sprite and combat_sprite is Label:
        combat_sprite.text = emoji
