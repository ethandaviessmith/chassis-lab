extends BaseFighter
class_name PlayerRobot

# We're using BaseFighter's process_combat_behavior
# No need to override unless we need specific behavioral changes
signal robot_overheated
signal part_used(slot_name)
signal part_damaged(slot_name, current_durability)

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
                var part_name = ""
                var frame_index = "None"
                
                if part is Part:
                    part_name = part.part_name
                    frame_index = str(part.frame) if part.frame != null else "None"
                else:
                    # Fallback for dictionary data
                    part_name = part.get("name", "unnamed")
                    frame_index = str(part.get("frame_index", "None"))
                
                print("  ", part_type, ": ", part_name, " frame_index: ", frame_index)
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
    if part is Part:
        # Direct property access for Part objects
        if part.frames != null:
            return part.frames
    elif part and part.has("frames"):
        # Dictionary-style access as fallback
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
            if card is Card and card.data:
                var part_name = ""
                if card.data is Part:
                    part_name = card.data.part_name
                else:
                    part_name = card.data.get("name", "Unknown")
                    
                print("  - Adding ", slot_name, ": ", part_name)
                
                # Convert slot names to robot part names
                var robot_slot = slot_name
                if slot_name == "arm_left":
                    robot_slot = "left_arm"
                elif slot_name == "arm_right":
                    robot_slot = "right_arm"
                
                # Attach the part to the robot
                attach_part(card.data, robot_slot)
    
    print("PlayerRobot: Build complete - Energy: ", energy, "/", max_energy, ", Heat: ", heat, "/", max_heat, ", Armor: ", armor)
    update_bars()
    update_visuals()  # Update visuals based on new parts
    emit_signal("robot_updated")

# Attach a part and apply its effects
func attach_part(part: Part, slot: String):
    match slot:
        "scrapper":
            scrapper = part
        "head":
            head = part
        "core":
            core = part
        "left_arm":
            left_arm = part
            # Always update attack capabilities when an arm is attached
            update_attack_capabilities()
        "right_arm":
            right_arm = part
            # Always update attack capabilities when an arm is attached
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
    
    # Process left arm
    if left_arm != null:
        var attack_type_arr = []
        var attack_range_arr = []
        
        # Get attack types and ranges based on arm data type
        if left_arm is Part:
            # Direct access for Part objects - always arrays in the new implementation
            attack_type_arr = left_arm.attack_type if left_arm.attack_type is Array else [left_arm.attack_type] if left_arm.attack_type != null else ["melee"]
            attack_range_arr = left_arm.attack_range if left_arm.attack_range is Array else [left_arm.attack_range] if left_arm.attack_range != null else [1.0]
        elif left_arm is Dictionary:
            # Dictionary-style access for backwards compatibility
            if left_arm.has("attack_type") and left_arm.has("attack_range"):
                attack_type_arr = left_arm.attack_type if left_arm.attack_type is Array else [left_arm.attack_type]
                attack_range_arr = left_arm.attack_range if left_arm.attack_range is Array else [left_arm.attack_range]
        
        # Add all attack types and ranges that aren't already in the list
        for i in range(attack_type_arr.size()):
            if i < attack_range_arr.size():
                var attack_type = attack_type_arr[i]
                var attack_range = attack_range_arr[i]
                
                # Add if not already present
                if not attack_type in attack_types:
                    attack_types.append(attack_type)
                    attack_ranges.append(attack_range)
    
    # Process right arm
    if right_arm != null:
        var attack_type_arr = []
        var attack_range_arr = []
        
        # Get attack types and ranges based on arm data type
        if right_arm is Part:
            # Direct access for Part objects - always arrays in the new implementation
            attack_type_arr = right_arm.attack_type if right_arm.attack_type is Array else [right_arm.attack_type] if right_arm.attack_type != null else ["melee"]
            attack_range_arr = right_arm.attack_range if right_arm.attack_range is Array else [right_arm.attack_range] if right_arm.attack_range != null else [1.0]
        elif right_arm is Dictionary:
            # Dictionary-style access for backwards compatibility
            if right_arm.has("attack_type") and right_arm.has("attack_range"):
                attack_type_arr = right_arm.attack_type if right_arm.attack_type is Array else [right_arm.attack_type]
                attack_range_arr = right_arm.attack_range if right_arm.attack_range is Array else [right_arm.attack_range]
        
        # Add all attack types and ranges that aren't already in the list
        for i in range(attack_type_arr.size()):
            if i < attack_range_arr.size():
                var attack_type = attack_type_arr[i]
                var attack_range = attack_range_arr[i]
                
                # Add if not already present
                if not attack_type in attack_types:
                    attack_types.append(attack_type)
                    attack_ranges.append(attack_range)
    
    print("PlayerRobot: Updated attack capabilities. Types: ", attack_types, ", Ranges: ", attack_ranges)

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
    
    # Use legs for movement (if available)
    if legs and randf() < 0.1:  # 10% chance per frame to emit signal (not every frame)
        emit_signal("part_used", "legs")
    
    # Use core for power management (if available)
    if core and randf() < 0.05:  # 5% chance per frame
        emit_signal("part_used", "core")
    
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
        if distance_to_target <= 80:  # Attack range
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
        emit_signal("part_used", "left_arm")
    if right_arm:
        base_damage += 2  # Example: right arm adds damage
        emit_signal("part_used", "right_arm")
    
    # Apply randomization to damage (±20%)
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    var damage_variation = rng.randf_range(0.8, 1.2)
    
    # Use head for targeting precision (if available)
    if head:
        damage_variation = rng.randf_range(0.9, 1.3)  # Better precision with head
        emit_signal("part_used", "head")
    
    # Use utility for bonus effects (if available)
    if utility and rng.randf() < 0.3:  # 30% chance to use utility
        damage_variation *= 1.2  # 20% damage boost from utility
        emit_signal("part_used", "utility")
    
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
    
    # If we took damage, reduce durability on a random part
    if actual_damage > 0:
        # Choose a random part to damage
        var damage_candidates = []
        if head and head.durability > 0: damage_candidates.append("head")
        if core and core.durability > 0: damage_candidates.append("core")
        if left_arm and left_arm.durability > 0: damage_candidates.append("left_arm")
        if right_arm and right_arm.durability > 0: damage_candidates.append("right_arm")
        if legs and legs.durability > 0: damage_candidates.append("legs")
        if utility and utility.durability > 0: damage_candidates.append("utility")
        
        if damage_candidates.size() > 0:
            var random_part = damage_candidates[randi() % damage_candidates.size()]
            var part = get(random_part)
            if part and part.durability:
                part.durability = max(0, part.durability - 1)
                emit_signal("part_damaged", random_part, part.durability)
                print("PlayerRobot: Part damaged: ", random_part, " now at ", part.durability, "/", part.max_durability)

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
