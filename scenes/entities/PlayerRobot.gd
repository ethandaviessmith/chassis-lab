extends BaseFighter
class_name PlayerRobot

# We're using BaseFighter's process_combat_behavior
# No need to override unless we need specific behavioral changes
signal robot_overheated

# Robot-specific resources
# Note: heat and max_heat are inherited from BaseFighter

# Parts data
var scrapper = null
var head = null
var core = null
var left_arm = null
var right_arm = null
var legs = null
var utility = null

@onready var robot_visuals: RobotVisuals = $RobotVisuals

# Combat behavior variables
var last_attack_time = 0.0
var is_combat_active = false

func _ready():
    super._ready()  # Call BaseFighter's _ready function
    
    # Initialize robot
    update_bars()
    
    # Setup visuals with the sprite nodes
    update_visuals()
    
    # Find combat view for effects
    find_combat_view()

# Find reference to combat view
func find_combat_view():
    await get_tree().process_frame  # Wait for scene to be ready
    combat_view = get_tree().get_first_node_in_group("combat_view")

func _physics_process(delta):
    if is_combat_active:
        process_combat_behavior(delta)
        
# Update robot visuals with part sprites
func update_visuals():
    if robot_visuals:
        # Create a dictionary of all robot parts
        var robot_parts = {
            "head": head,
            "core": core,
            "left_arm": left_arm,
            "right_arm": right_arm,
            "legs": legs,
            "utility": utility
        }
        
        print("PlayerRobot: Updating visuals with parts:")
        # Debug the parts being sent to visuals
        for part_type in robot_parts.keys():
            var part = robot_parts[part_type]
            if part != null:
                print("  ", part_type, ": ", part.get("name", "unnamed"), 
                      " frame_index: ", part.get("frame_index", "None"))
            else:
                print("  ", part_type, ": None")
        
        # Initialize visuals from robot parts
        robot_visuals.initialize_from_robot_parts(robot_parts)
        
        # Ensure the correct frames are set based on the robot's state
        if velocity.length() > 10:
            robot_visuals.start_walking()
        else:
            robot_visuals.stop_walking()

# Helper method to get animation frame count from part data
func get_frames_from_part(part):
    if part and part.has("frames"):
        return part.frames
    return 1

# Override BaseFighter's process_combat_behavior
func process_combat_behavior(delta):
    if not target:
        target = find_target()
    
    if target and is_instance_valid(target):
        move_toward_target(target)
        try_attack(target, delta)
    else:
        # No valid target, stop moving
        velocity = Vector2.ZERO

# Build robot stats from chassis slot data
func build_from_chassis(attached_parts: Dictionary):
    # Clear existing parts
    clear_all_parts()
    
    # Reset base stats
    reset_to_base_stats()
    
    # Process slots in specific order for proper stat calculation
    var slot_order = ["scrapper", "head", "core", "arm_left", "arm_right", "legs", "utility"]
    
    print("PlayerRobot: Building robot from chassis:")
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
    
    print("PlayerRobot: Build complete - Energy: ", energy, "/", max_energy, ", Heat: ", heat, "/", max_heat, ", Armor: ", armor)
    update_bars()
    update_visuals()  # Update visuals based on new parts
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
        "effects": card_data.get("effects", []),
        "frames": card_data.get("frames", 1)  # Animation frame count, default to 1
    }
    
    # Add attack type and range if present (for arms)
    if card_data.has("attack_type"):
        part["attack_type"] = card_data.attack_type
    
    if card_data.has("attack_range"):
        part["attack_range"] = card_data.attack_range
    
    # Extract frame index if present (from RobotFrame)
    if card_data.has("frame"):
        var frame_index = card_data.frame
        var part_type = card_data.get("type", "").to_lower()
        
        # Handle different part types for frame indices
        part["frame_index"] = frame_index
        print("PlayerRobot: Setting frame_index for ", part.name, " to ", frame_index)
        
        # Special handling for left arm (add offset)
        if part_type == "arm" and part["name"].to_lower().begins_with("left"):
            part["frame_index"] += RobotVisuals.LEFT_TO_RIGHT_OFFSET
            print("  Adjusted left arm frame_index to ", part["frame_index"])
    else:
        # If no frame specified, set default based on part type
        var part_type = card_data.get("type", "").to_lower()
        
        print("PlayerRobot: No frame specified for ", part.name, ", setting default based on type: ", part_type)
        
        # Set default frame indices
        if part_type == "head":
            part["frame_index"] = RobotVisuals.FRAME_INDEX_HEAD
        elif part_type == "core":
            part["frame_index"] = RobotVisuals.FRAME_INDEX_CORE
        elif part_type == "arm":
            if part["name"].to_lower().begins_with("left"):
                part["frame_index"] = RobotVisuals.FRAME_INDEX_LEFT_ARM
            else:
                part["frame_index"] = RobotVisuals.FRAME_INDEX_RIGHT_ARM
        elif part_type == "legs":
            part["frame_index"] = RobotVisuals.FRAME_INDEX_LEGS
        elif part_type == "utility":
            part["frame_index"] = RobotVisuals.FRAME_INDEX_UTILITY
        
        print("  Set frame_index to ", part.get("frame_index", "None"))
        
    # Extract sprite/visual information if present
    if card_data.has("sprite_path"):
        part["sprite_path"] = card_data.sprite_path
    
    # Parse effects for stat modifications
    if card_data.has("effects"):
        var parsed_effects = []
        for effect in card_data.effects:
            if effect is Dictionary and effect.has("description"):
                # Parse effect description for stat bonuses
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

# Override move_toward_target to include robot visuals
func move_toward_target(target_node):
    var direction = (target_node.global_position - global_position).normalized()
    velocity = direction * move_speed
    
    # Apply modifiers from parts
    if heat >= 8:
        velocity *= 0.8  # Slow down when overheating
    
    # Update visuals based on movement
    if robot_visuals:
        if velocity.length() > 10:
            # Flip the robot visuals based on movement direction
            if direction.x < 0:
                # Moving left
                robot_visuals.scale.x = -1
            else:
                # Moving right
                robot_visuals.scale.x = 1
                
            robot_visuals.start_walking()
        else:
            robot_visuals.stop_walking()
    
    move_and_slide()

# Override try_attack for the robot's specific attack logic
func try_attack(target_node, _delta):
    # Check if robot is defeated (energy <= 0)
    if energy <= 0:
        return  # Don't attack if defeated
        
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
        var distance_to_target = global_position.distance_to(target_node.global_position)
        if distance_to_target <= 50:  # Attack range
            perform_attack(target_node)
            last_attack_time = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
            
            # Update visuals for attack animation
            if robot_visuals:
                robot_visuals.play_attack()

# Robot-specific attack implementation
func perform_attack(target_node):
    # Double check that robot is not defeated
    if energy <= 0:
        return  # Don't attack if defeated
        
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
        if target_node.has_method("take_damage"):
            target_node.take_damage(damage)
            print("PlayerRobot: Attacked for ", damage, " damage with melee")
            
            Sound.play_attack()
            
            if combat_view:
                combat_view.show_combat_effect("melee_attack", self)
                combat_view.show_damage_number(damage, target_node)
                
    elif attack_type == "range":
        Sound.play_range_attack()
        
        if combat_view:
            print("PlayerRobot: Fired a projectile for ", damage, " damage")
            combat_view.show_combat_effect("range_attack", self)
            combat_view.fire_projectile(self, target_node.global_position, damage, attack_range)
    
    # Cycle to next attack type
    current_attack_index = (current_attack_index + 1) % attack_types.size()
    
    # Generate heat from attacking
    add_heat(1)

# Override take_damage to include robot visuals
func take_damage(amount: int):
    var actual_damage = max(0, amount - armor)
    energy -= actual_damage
    energy = max(0, energy)
    
    update_bars()
    print("PlayerRobot: Took ", actual_damage, " damage (", amount, " - ", armor, " armor)")
    
    # Show shield indicator if armor reduced damage significantly
    if armor > 0 and amount > actual_damage and combat_view:
        combat_view.show_combat_effect("shield", self)
    
    # Play hit animation if actually damaged
    if robot_visuals and actual_damage > 0:
        robot_visuals.play_hit()
    
    if energy <= 0:
        # Play death animation before signaling defeat
        if robot_visuals:
            var tween = robot_visuals.play_death_animation()
            # Wait for animation to finish
            await tween.finished
        
        # Signal defeat
        emit_signal("fighter_defeated")

# Override add_heat to emit the robot-specific signal
func add_heat(amount: int):
    super.add_heat(amount)  # Call parent implementation first
    
    # Emit the robot-specific overheated signal if needed
    if heat >= max_heat:
        emit_signal("robot_overheated")

# Override heal to provide robot-specific visual feedback
func heal(amount: int):
    var previous_energy = energy
    energy = min(energy + amount, max_energy)
    update_bars()
    
    # Only show healing effect if actually healed
    if energy > previous_energy:
        # Show healing indicator
        if combat_view:
            combat_view.show_combat_effect("heal", self)
            
        # Visual feedback for healing
        if robot_visuals:
            robot_visuals.play_heal_effect()
    
    print("PlayerRobot: Healed for ", (energy - previous_energy), " energy (", energy, "/", max_energy, ")")

# Now using the base class implementation for reduce_heat

# Override update_bars to include heat bar
# func update_bars():
#     if health_bar:
#         health_bar.value = 100.0 * energy / max_energy
    
#     if heat_bar:
#         heat_bar.value = 100.0 * heat / max_heat
        
#         # Update heat bar color
#         if heat >= max_heat:
#             heat_bar.modulate = Color(1, 0, 0)  # Red for overheat
#         elif heat >= 8:
#             heat_bar.modulate = Color(1, 0.5, 0)  # Orange for high heat
#         else:
#             heat_bar.modulate = Color(1, 0.8, 0)  # Yellow-orange normal

# Status checks
func get_armor() -> int:
    return armor

# Combat state management
func start_combat():
    is_combat_active = true
    is_active = true
    add_to_group("player_robot")  # Make sure enemy can find us
    print("PlayerRobot: Combat started")

func end_combat():
    is_combat_active = false
    is_active = false
    target = null
    velocity = Vector2.ZERO
    print("PlayerRobot: Combat ended")

# Using base class implementations for status checks and summaries
