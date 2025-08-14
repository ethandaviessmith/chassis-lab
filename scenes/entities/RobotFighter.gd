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

# Robot visuals
@onready var health_bar = $HealthBar
@onready var heat_bar = $HeatBar
@onready var animation_player = $AnimationPlayer
var robot_visuals: RobotVisuals

# Attack properties
var attack_types = ["melee"]    # Default to melee only
var attack_ranges = [1.0]       # Default range
var current_attack_index = 0    # Which attack type to use next
var combat_view = null          # Reference to combat view for effects

# Combat behavior variables
var current_target = null
var last_attack_time = 0.0
var is_combat_active = false

func _ready():
    # Set up the robot visuals
    robot_visuals = RobotVisuals.new()
    add_child(robot_visuals)
    
    # Find combat view for effects
    find_combat_view()
    
    update_bars()

# Find reference to combat view
func find_combat_view():
    await get_tree().process_frame  # Wait for scene to be ready
    combat_view = get_tree().get_first_node_in_group("combat_view")

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
    
    # Add attack type and range if present (for arms)
    if card_data.has("attack_type"):
        part["attack_type"] = card_data.attack_type
    
    if card_data.has("attack_range"):
        part["attack_range"] = card_data.attack_range
    
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
            # Update attack types and ranges from arm
            if part.has("attack_type") and part.has("attack_range"):
                update_attack_capabilities()
        "right_arm":
            right_arm = part
            # Update attack types and ranges from arm
            if part.has("attack_type") and part.has("attack_range"):
                update_attack_capabilities()
        "legs":
            legs = part
        "utility":
            utility = part
    
    # Apply part effects to stats
    apply_part_effects(part)
    emit_signal("robot_updated")
    
# Update attack types and ranges based on equipped arms
func update_attack_capabilities():
    attack_types = ["melee"]  # Default melee
    attack_ranges = [1.0]     # Default range
    
    # Check left arm
    if left_arm and left_arm.has("attack_type") and left_arm.has("attack_range"):
        for i in range(left_arm.attack_type.size()):
            var attack_type = left_arm.attack_type[i]
            var attack_range = left_arm.attack_range[i]
            
            # Add if not already present
            if not attack_type in attack_types:
                attack_types.append(attack_type)
                attack_ranges.append(attack_range)
    
    # Check right arm
    if right_arm and right_arm.has("attack_type") and right_arm.has("attack_range"):
        for i in range(right_arm.attack_type.size()):
            var attack_type = right_arm.attack_type[i]
            var attack_range = right_arm.attack_range[i]
            
            # Add if not already present
            if not attack_type in attack_types:
                attack_types.append(attack_type)
                attack_ranges.append(attack_range)

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
    
    # Update visuals based on movement
    if robot_visuals:
        if velocity.length() > 10:
            robot_visuals.start_walking()
        else:
            robot_visuals.stop_walking()
    
    move_and_slide()

func try_attack(target, _delta):
    # Check if enough time has passed since last attack
    var current_time = Time.get_time_dict_from_system()
    var time_since_last_attack = (current_time.hour * 3600 + current_time.minute * 60 + current_time.second) - last_attack_time
    
    # Calculate attack speed with small randomization (±15%)
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    var randomized_attack_speed = attack_speed * rng.randf_range(0.85, 1.15)
    
    # Simple time-based attack cooldown with randomized speed
    if time_since_last_attack >= (1.0 / randomized_attack_speed):
        # Check if close enough to attack
        var distance_to_target = global_position.distance_to(target.global_position)
        if distance_to_target <= 50:  # Attack range
            perform_attack(target)
            last_attack_time = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
            
            # Update visuals for attack animation
            if robot_visuals:
                robot_visuals.play_attack()

func perform_attack(target):
    # Calculate base damage
    var base_damage = 1  # Base damage
    
    # Add damage from arms
    if left_arm:
        base_damage += 2  # Example: left arm adds damage
    if right_arm:
        base_damage += 2  # Example: right arm adds damage
    
    # Apply randomization to damage (±20%)
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    var damage_variation = rng.randf_range(0.8, 1.2)
    var damage = round(base_damage * damage_variation)
    damage = max(1, damage)  # Ensure minimum damage of 1
    
    # Get current attack type and range
    var attack_type = attack_types[current_attack_index]
    var attack_range = attack_ranges[current_attack_index] * 100.0  # Convert to pixels
    
    # Attack based on type
    if attack_type == "melee":
        # Direct melee attack
        if target.has_method("take_damage"):
            target.take_damage(damage)
            print("RobotFighter: Attacked for ", damage, " damage with melee")
            
            Sound.play_attack()
            
            if combat_view:
                combat_view.show_combat_effect("melee_attack", self)
                combat_view.show_damage_number(damage, target)
                
    elif attack_type == "range":
        Sound.play_range_attack()
        
        if combat_view:
            print("RobotFighter: Fired a projectile for ", damage, " damage")
            combat_view.show_combat_effect("range_attack", self)
            combat_view.fire_projectile(self, target.global_position, damage, attack_range)
    
    # Cycle to next attack type
    current_attack_index = (current_attack_index + 1) % attack_types.size()
    
    # Generate heat from attacking
    add_heat(1)

# Health and resource management
func take_damage(amount: int):
    var actual_damage = max(0, amount - armor)
    energy -= actual_damage
    energy = max(0, energy)
    
    update_bars()
    print("RobotFighter: Took ", actual_damage, " damage (", amount, " - ", armor, " armor)")
    
    # Show shield indicator if armor reduced damage significantly
    if armor > 0 and amount > actual_damage and combat_view:
        combat_view.show_combat_effect("shield", self)
    
    # Play hit animation
    if robot_visuals and actual_damage > 0:
        robot_visuals.play_hit()
    
    if energy <= 0:
        emit_signal("robot_defeated")

func heal(amount: int):
    energy = min(energy + amount, max_energy)
    update_bars()
    
    # Show healing indicator
    if amount > 0 and combat_view:
        combat_view.show_combat_effect("heal", self)

func add_heat(amount: int):
    heat = min(heat + amount, max_heat)
    update_bars()
    
    if heat >= max_heat:
        emit_signal("robot_overheated")
        # Show overheat indicator
        if combat_view:
            combat_view.show_combat_effect("overheat", self)
        # Overheating penalties could be applied here
    elif heat >= 8 and heat < max_heat:
        # High heat warning
        if combat_view:
            combat_view.show_combat_effect("overheat", self)

func reduce_heat(amount: int):
    var previous_heat = heat
    heat = max(0, heat - amount)
    update_bars()
    
    # Show cooldown indicator when significant heat reduction happens
    if previous_heat > 5 and amount >= 2 and combat_view:
        combat_view.show_combat_effect("cooldown", self)

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

# No longer needed with RobotVisuals system
func set_placeholder_sprite(_emoji: String):
    # This is kept for backwards compatibility
    pass
