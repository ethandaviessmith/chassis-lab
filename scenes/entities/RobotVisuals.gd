extends RobotFrame
class_name RobotVisuals

signal animation_completed

@onready var head_marker: Marker2D = $HeadMarker
@onready var core_marker: Marker2D = $CoreMarker
@onready var left_arm_marker: Marker2D = $LeftArmMarker
@onready var right_arm_marker: Marker2D = $RightArmMarker
@onready var legs_marker: Marker2D = $LegsMarker

# Store distances between sprite positions and their markers
var part_to_marker_distances = {
    "head": Vector2.ZERO,
    "core": Vector2.ZERO,
    "left_arm": Vector2.ZERO,
    "right_arm": Vector2.ZERO,
    "legs": Vector2.ZERO
}

# Animation variables
var anim_time: float = 0.0
var is_walking: bool = false
var is_attacking: bool = false
var is_hit: bool = false
var attack_direction: int = 1  # 1 = right, -1 = left

func _ready():
    # Calculate distances between sprites and their markers
    calculate_marker_distances()
    
    # Set up base appearance with default positions
    set_default_positions()
    
    # Default sprite settings - use parent's frame indices
    if head_sprite:
        head_sprite.centered = true
        head_sprite.frame = FRAME_INDEX_HEAD
    if core_sprite:
        core_sprite.centered = true
        core_sprite.frame = FRAME_INDEX_CORE
    if legs_sprite:
        legs_sprite.centered = true
        legs_sprite.frame = FRAME_INDEX_LEGS
    if left_arm_sprite:
        left_arm_sprite.centered = true
        left_arm_sprite.frame = FRAME_INDEX_LEFT_ARM
    if right_arm_sprite:
        right_arm_sprite.centered = true
        right_arm_sprite.frame = FRAME_INDEX_RIGHT_ARM
        
# Calculate the distances between each sprite and its marker
func calculate_marker_distances():
    if head_sprite and head_marker:
        part_to_marker_distances["head"] = head_sprite.position - head_marker.position
    if core_sprite and core_marker:
        part_to_marker_distances["core"] = core_sprite.position - core_marker.position
    if left_arm_sprite and left_arm_marker:
        part_to_marker_distances["left_arm"] = left_arm_sprite.position - left_arm_marker.position
    if right_arm_sprite and right_arm_marker:
        part_to_marker_distances["right_arm"] = right_arm_sprite.position - right_arm_marker.position
    if legs_sprite and legs_marker:
        part_to_marker_distances["legs"] = legs_sprite.position - legs_marker.position
        
    print("Calculated marker distances: ", part_to_marker_distances)


# Set the default positions for all sprites
func set_default_positions():
    # Position each sprite based on its marker
    if core_sprite and core_marker:
        core_sprite.position = core_marker.position + part_to_marker_distances["core"]
        core_sprite.rotation_degrees = 0
    
    if head_sprite and head_marker:
        head_sprite.position = head_marker.position + part_to_marker_distances["head"]
        head_sprite.rotation_degrees = 0
        
    if left_arm_sprite and left_arm_marker:
        left_arm_sprite.position = left_arm_marker.position + part_to_marker_distances["left_arm"]
        left_arm_sprite.rotation_degrees = 0
        
    if right_arm_sprite and right_arm_marker:
        right_arm_sprite.position = right_arm_marker.position + part_to_marker_distances["right_arm"]
        right_arm_sprite.rotation_degrees = 0
        
    if legs_sprite and legs_marker:
        legs_sprite.position = legs_marker.position + part_to_marker_distances["legs"]
        legs_sprite.rotation_degrees = 0

# Function to position a part with respect to its marker
func update_part_position(part_sprite: Sprite2D, part_marker: Marker2D, 
                         angle: float = 0, 
                         additional_offset: Vector2 = Vector2.ZERO):
    var part_name = part_sprite.name.replace("Sprite", "").to_lower()
    
    # Get the distance from sprite to marker
    var distance = part_to_marker_distances[part_name]
    
    if angle != 0:
        # Apply rotation to the distance
        var rad = deg_to_rad(angle)
        distance = distance.rotated(rad)
    
    # Set the final position
    part_sprite.position = part_marker.position + distance + additional_offset
    part_sprite.rotation_degrees = angle

# Helper for arm swinging animation
func swing_arm(arm_sprite: Sprite2D, angle: float):
    var arm_marker
    if "Left" in arm_sprite.name:
        arm_marker = left_arm_marker
    else:
        arm_marker = right_arm_marker
        
    update_part_position(arm_sprite, arm_marker, angle)

# Helper for rotating a sprite with constraints
func rotate_constrained(sprite: Sprite2D, target_angle: float, min_angle: float, max_angle: float):
    var clamped_angle = clamp(target_angle, min_angle, max_angle)
    sprite.rotation_degrees = clamped_angle
    
# Clear all parts and reset to default
func clear_parts():
    Log.pr("[RobotVisuals] clear_parts called - resetting sprites")
    # Use the parent class's clear_all_parts method
    clear_all_parts()
    
    # Additional visual-specific reset logic can go here
    set_default_positions()

func _process(delta):
    anim_time += delta
    
    if is_walking:
        animate_walking(delta)
    elif is_attacking:
        animate_attack(delta)
    elif is_hit:
        animate_hit(delta)
    else:
        animate_idle(delta)

# Set sprite textures and frames based on equipped parts
# This function is kept in RobotVisuals since it deals with animation-specific frames
func set_part_sprites(head_frame_index = -1, core_frame_index = -1, legs_frame_index = -1,
                     left_arm_frame_index = -1, right_arm_frame_index = -1):
    Log.pr("[RobotVisuals] set_part_sprites called - setting frames:", {
        "head": head_frame_index,
        "core": core_frame_index, 
        "legs": legs_frame_index,
        "left_arm": left_arm_frame_index, 
        "right_arm": right_arm_frame_index
    })
    print("RobotVisuals: Setting part frames - Head:", head_frame_index, 
          " Core:", core_frame_index, " Legs:", legs_frame_index,
          " LeftArm:", left_arm_frame_index, " RightArm:", right_arm_frame_index)
    
    # Set frame if specified, otherwise keep current frame
    if head_frame_index >= 0 and head_sprite:
        head_sprite.frame = head_frame_index
        
    if core_frame_index >= 0 and core_sprite:
        core_sprite.frame = core_frame_index
        
    if legs_frame_index >= 0 and legs_sprite:
        legs_sprite.frame = legs_frame_index
        
    if left_arm_frame_index >= 0 and left_arm_sprite:
        left_arm_sprite.frame = left_arm_frame_index
        
    if right_arm_frame_index >= 0 and right_arm_sprite:
        right_arm_sprite.frame = right_arm_frame_index

# Update visuals from robot part data, reusing RobotFrame functionality
func update_from_part_data(parts_data: Dictionary):
    print("RobotVisuals: Updating from part data")
    Log.pr("[RobotVisuals] update_from_part_data called with parts: ", parts_data.keys())
    
    # Use parent class functionality to handle the part data
    for part_type in parts_data:
        var part = parts_data[part_type]
        if part != null:
            attach_part_visual(part, part_type)
            Log.pr("[RobotVisuals] Attached ", part_type, " part with frame: ", 
                  part.frame if part is Part else (part.frame if part.has("frame") else part.get("frame_index", 0)))


# Update sprite positions with offsets for animations
func update_positions(head_offset: Vector2 = Vector2.ZERO, core_offset: Vector2 = Vector2.ZERO, 
                     legs_offset: Vector2 = Vector2.ZERO, left_arm_offset: Vector2 = Vector2.ZERO, 
                     right_arm_offset: Vector2 = Vector2.ZERO):
    # Update each part's position using their marker and distance
    if core_sprite and core_marker:
        core_sprite.position = core_marker.position + part_to_marker_distances["core"] + core_offset
    
    if head_sprite and head_marker:
        head_sprite.position = head_marker.position + part_to_marker_distances["head"] + head_offset
        
    if legs_sprite and legs_marker:
        legs_sprite.position = legs_marker.position + part_to_marker_distances["legs"] + legs_offset
        
    if left_arm_sprite and left_arm_marker:
        left_arm_sprite.position = left_arm_marker.position + part_to_marker_distances["left_arm"] + left_arm_offset
        
    if right_arm_sprite and right_arm_marker:
        right_arm_sprite.position = right_arm_marker.position + part_to_marker_distances["right_arm"] + right_arm_offset

# Animation functions
func animate_idle(_delta):
    # Subtle floating motion for idle
    var head_bob = Vector2(0, sin(anim_time * 2) * 2)
    var core_bob = Vector2(0, sin(anim_time * 2 + 0.2) * 1.5)
    var legs_bob = Vector2(0, sin(anim_time * 2 + 0.4) * 1)
    var left_arm_bob = Vector2(sin(anim_time * 1.5) * 2, 0)
    var right_arm_bob = Vector2(sin(anim_time * 1.5 + PI) * 2, 0)
    
    update_positions(head_bob, core_bob, legs_bob, left_arm_bob, right_arm_bob)


func animate_walking(_delta):
    # Walking animation
    var head_bob = Vector2(sin(anim_time * 7) * 2, sin(anim_time * 14) * 2)
    var core_bob = Vector2(sin(anim_time * 7) * 1.5, 0)
    var legs_bob = Vector2(0, abs(sin(anim_time * 14)) * 3)
    var left_arm_swing = Vector2(0, sin(anim_time * 7) * 5)
    var right_arm_swing = Vector2(0, sin(anim_time * 7 + PI) * 5)
    
    update_positions(head_bob, core_bob, legs_bob, left_arm_swing, right_arm_swing)

func animate_attack(_delta):
    # Attack animation - punch or weapon swing
    var head_offset = Vector2(attack_direction * 2, 0)
    var core_offset = Vector2(attack_direction * 1, 0)
    var legs_offset = Vector2.ZERO
    
    # Determine which arm is attacking (alternate)
    var left_arm_offset
    var right_arm_offset
    
    if attack_direction > 0:
        # Right arm attack
        right_arm_offset = Vector2(10, -5)
        left_arm_offset = Vector2(-2, 2)
    else:
        # Left arm attack
        left_arm_offset = Vector2(-10, -5)
        right_arm_offset = Vector2(2, 2)
    
    update_positions(head_offset, core_offset, legs_offset, left_arm_offset, right_arm_offset)
    
    # End attack animation after a short duration
    if is_attacking:
        is_attacking = false
        await get_tree().create_timer(0.3).timeout
        
        # Alternate attack direction for next time
        attack_direction *= -1
        

func animate_hit(_delta):
    # Hit reaction animation - shake and squish
    var shake_intensity = 5.0
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    
    var head_shake = Vector2(rng.randf_range(-shake_intensity, shake_intensity), 
                           rng.randf_range(-shake_intensity, shake_intensity))
    var core_shake = Vector2(rng.randf_range(-shake_intensity * 0.5, shake_intensity * 0.5), 
                           rng.randf_range(-shake_intensity * 0.5, shake_intensity * 0.5))
    var legs_shake = Vector2(rng.randf_range(-shake_intensity * 0.5, shake_intensity * 0.5), 
                          rng.randf_range(-shake_intensity * 0.5, shake_intensity * 0.5))
    var left_arm_shake = Vector2(rng.randf_range(-shake_intensity * 0.8, shake_intensity * 0.8), 
                               rng.randf_range(-shake_intensity * 0.8, shake_intensity * 0.8))
    var right_arm_shake = Vector2(rng.randf_range(-shake_intensity * 0.8, shake_intensity * 0.8), 
                                rng.randf_range(-shake_intensity * 0.8, shake_intensity * 0.8))
    
    update_positions(head_shake, core_shake, legs_shake, left_arm_shake, right_arm_shake)
    
    # End hit animation after a short duration
    if is_hit:
        is_hit = false
        await get_tree().create_timer(0.2).timeout
        
# Apply RobotFrame data directly to our visuals
func apply_robot_frame_data(robot_frame: RobotFrame):
    Log.pr("[RobotVisuals] apply_robot_frame_data called with:", robot_frame)
    if not is_instance_valid(robot_frame):
        Log.pr("[RobotVisuals] Invalid robot_frame provided")
        return
        
    var part_data = robot_frame.get_all_part_data()
    update_from_part_data(part_data)


func initialize_from_robot_parts(robot_parts: Dictionary):
    Log.pr("[RobotVisuals] initialize_from_robot_parts called")
    # Convert PlayerRobot parts to the format RobotVisuals needs
    var visual_parts = {}
    
    # Process each part type and convert to visual format
    for part_type in ["head", "core", "left_arm", "right_arm", "legs", "utility"]:
        if robot_parts.has(part_type) and robot_parts[part_type] != null:
            var part = robot_parts[part_type]
            # Check if already a Part, otherwise convert
            if part is Part:
                visual_parts[part_type] = part
            else:
                visual_parts[part_type] = convert_to_visual_part(part, part_type)
    
    # Update visuals with the converted parts
    update_from_part_data(visual_parts)
    

# Convert a robot part to a visual part
func convert_to_visual_part(part_data, part_type: String):
    if part_data == null:
        return null
        
    var part_name = ""
    var visual_part
    
    # Handle both Part objects and dictionaries
    if part_data is Part:
        part_name = part_data.part_name
        # Create new Part instance
        visual_part = Part.new()
        visual_part.id = part_data.id
        visual_part.part_name = part_data.part_name
        visual_part.type = part_data.type
        visual_part.cost = part_data.cost
        visual_part.heat = part_data.heat
        visual_part.durability = part_data.durability
        visual_part.frame = part_data.frame
        visual_part.description = part_data.description
    else:
        # Handle legacy dictionary format
        part_name = part_data.name if part_data.has("name") else "Unknown"
        print("Converting part for ", part_type, ": ", part_name)
        visual_part = part_data.duplicate()
    
    # Add frame index if not present
    if not (visual_part is Part and visual_part.frame > 0) and not (visual_part is Dictionary and visual_part.has("frame") and visual_part.frame):
        print("  No frame_index found, adding default based on part type")
        match part_type:
            "head":
                if visual_part is Part:
                    visual_part.frame = FRAME_INDEX_HEAD
                else:
                    visual_part["frame"] = FRAME_INDEX_HEAD
                print("  Set head frame_index to ", FRAME_INDEX_HEAD)
            "core":
                if visual_part is Part:
                    visual_part.frame = FRAME_INDEX_CORE
                else:
                    visual_part["frame"] = FRAME_INDEX_CORE
                print("  Set core frame_index to ", FRAME_INDEX_CORE)
            "left_arm":
                if visual_part is Part:
                    visual_part.frame = FRAME_INDEX_LEFT_ARM
                else:
                    visual_part["frame"] = FRAME_INDEX_LEFT_ARM
                print("  Set left_arm frame_index to ", FRAME_INDEX_LEFT_ARM)
            "right_arm":
                if visual_part is Part:
                    visual_part.frame = FRAME_INDEX_RIGHT_ARM
                else:
                    visual_part["frame"] = FRAME_INDEX_RIGHT_ARM
                print("  Set right_arm frame_index to ", FRAME_INDEX_RIGHT_ARM)
            "legs":
                if visual_part is Part:
                    visual_part.frame = FRAME_INDEX_LEGS
                else:
                    visual_part["frame"] = FRAME_INDEX_LEGS
                print("  Set legs frame_index to ", FRAME_INDEX_LEGS)
            "utility":
                if visual_part is Part:
                    visual_part.frame = FRAME_INDEX_UTILITY
                else:
                    visual_part["frame"] = FRAME_INDEX_UTILITY
                print("  Set utility frame_index to ", FRAME_INDEX_UTILITY)
    else:
        # Get current frame, accounting for object type
        var current_frame
        var part_type_value
        
        if visual_part is Part:
            current_frame = visual_part.frame
            part_type_value = visual_part.type
            print("  Found existing frame for Part: ", current_frame)
        else:
            current_frame = visual_part.frame if visual_part.has("frame") else 0
            part_type_value = visual_part.type if visual_part.has("type") else ""
            print("  Found existing frame for Dictionary: ", current_frame)
            
        # For left arms that use the arm type, apply LEFT_RIGHT_OFFSET
        if part_type == "left_arm" and part_type_value.to_lower() == "arm":
            var base_frame = current_frame
            # Only apply offset if it hasn't been applied already
            if base_frame < FRAME_INDEX_LEFT_ARM:
                if visual_part is Part:
                    visual_part.frame = base_frame + LEFT_RIGHT_OFFSET
                else:
                    visual_part["frame"] = base_frame + LEFT_RIGHT_OFFSET
                print("  Applying LEFT_RIGHT_OFFSET. New frame: ", 
                      visual_part.frame if visual_part is Part else visual_part.frame)

    return visual_part

# Animation triggers
func start_walking():
    is_walking = true
    is_attacking = false
    is_hit = false

func stop_walking():
    is_walking = false

func play_attack():
    Log.pr("[RobotVisuals] play_attack called - current frames:",
        {
            "head": head_sprite.frame if head_sprite else -1,
            "core": core_sprite.frame if core_sprite else -1,
            "left_arm": left_arm_sprite.frame if left_arm_sprite else -1,
            "right_arm": right_arm_sprite.frame if right_arm_sprite else -1,
            "legs": legs_sprite.frame if legs_sprite else -1
        })
    is_attacking = true
    is_walking = false
    is_hit = false
    
    # Schedule restoration of frames after animation completes
    var timer = get_tree().create_timer(0.3)
    await timer.timeout
    Log.pr("[RobotVisuals] play_attack animation completed")

func play_hit():
    is_hit = true
    is_attacking = false
    # Keep walking if already walking
    
    # Flash sprites red
    if head_sprite:
        head_sprite.modulate = Color(1, 0.5, 0.5)
    if core_sprite:
        core_sprite.modulate = Color(1, 0.5, 0.5)
    if legs_sprite:
        legs_sprite.modulate = Color(1, 0.5, 0.5)
    if left_arm_sprite:
        left_arm_sprite.modulate = Color(1, 0.5, 0.5)
    if right_arm_sprite:
        right_arm_sprite.modulate = Color(1, 0.5, 0.5)

    # Reset color after a short delay
    var timer = get_tree().create_timer(0.1)
    await timer.timeout

    if head_sprite:
        head_sprite.modulate = Color(1, 1, 1)
    if core_sprite:
        core_sprite.modulate = Color(1, 1, 1)
    if legs_sprite:
        legs_sprite.modulate = Color(1, 1, 1)
    if left_arm_sprite:
        left_arm_sprite.modulate = Color(1, 1, 1)
    if right_arm_sprite:
        right_arm_sprite.modulate = Color(1, 1, 1)
    is_hit = false
    
func play_heal_effect():
    # Flash sprites green for healing effect
    head_sprite.modulate = Color(0.7, 1, 0.7)
    core_sprite.modulate = Color(0.7, 1, 0.7)
    legs_sprite.modulate = Color(0.7, 1, 0.7)
    left_arm_sprite.modulate = Color(0.7, 1, 0.7)
    right_arm_sprite.modulate = Color(0.7, 1, 0.7)
    
    # Create a subtle upward movement
    var original_position = global_position
    var tween = create_tween()
    tween.tween_property(self, "global_position", original_position + Vector2(0, -5), 0.2)
    tween.tween_property(self, "global_position", original_position, 0.2)
    
    # Reset color after a short delay
    var timer = get_tree().create_timer(0.3)
    await timer.timeout
    
    head_sprite.modulate = Color(1, 1, 1)
    core_sprite.modulate = Color(1, 1, 1)
    legs_sprite.modulate = Color(1, 1, 1)
    left_arm_sprite.modulate = Color(1, 1, 1)
    right_arm_sprite.modulate = Color(1, 1, 1)
    
# Death animation where the arms break off and the robot collapses backwards with proper rotation origins
func play_death_animation():
    # Stop other animations
    is_walking = false
    is_attacking = false
    is_hit = false
    
    # Store initial positions for reference and calculate rotation origins
    var initial_positions = {}
    
    if head_sprite: initial_positions["head"] = head_sprite.position
    if core_sprite: initial_positions["core"] = core_sprite.position
    if legs_sprite: 
        initial_positions["legs"] = legs_sprite.position
    if left_arm_sprite: initial_positions["left_arm"] = left_arm_sprite.position
    if right_arm_sprite: initial_positions["right_arm"] = right_arm_sprite.position
    
    # We'll use existing positions and offsets to simulate proper pivot rotation
    
    # Create randomness for variation in timing
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    
    # Create tween for smooth animation
    var tween = create_tween()
    
    # Log start of death animation
    Log.pr("[RobotVisuals] Starting death animation sequence with adjusted rotation origins")
    
    # Phase 1: Arms breaking off with slight shake
    if left_arm_sprite:
        # Small initial shake
        tween.tween_property(left_arm_sprite, "position", left_arm_sprite.position + Vector2(rng.randf_range(-3, 3), rng.randf_range(-2, 2)), 0.1)
        # Break off with rotation
        tween.tween_property(left_arm_sprite, "rotation_degrees", -40, 0.2)
        # Fall to ground (y=0) with slight x offset
        var left_arm_delay = rng.randf_range(0.1, 0.3)
        tween.tween_property(left_arm_sprite, "position", Vector2(left_arm_sprite.position.x - 15, 0), 0.4 + left_arm_delay)
        tween.parallel().tween_property(left_arm_sprite, "rotation_degrees", -120, 0.4 + left_arm_delay)
    
    if right_arm_sprite:
        # Small initial shake (slightly delayed from left arm)
        tween.tween_property(right_arm_sprite, "position", right_arm_sprite.position + Vector2(rng.randf_range(-3, 3), rng.randf_range(-2, 2)), 0.15)
        # Break off with rotation
        tween.tween_property(right_arm_sprite, "rotation_degrees", 40, 0.25)
        # Fall to ground (y=0) with slight x offset
        var right_arm_delay = rng.randf_range(0.1, 0.3)
        tween.tween_property(right_arm_sprite, "position", Vector2(right_arm_sprite.position.x + 15, 0), 0.35 + right_arm_delay)
        tween.parallel().tween_property(right_arm_sprite, "rotation_degrees", 120, 0.35 + right_arm_delay)
    
    # Phase 2: Prepare for rotation by setting up pivot points
    
    # Update core pivot to be at legs origin
    if core_sprite and legs_sprite:
        # Set rotation origin to legs position and begin rotation
        tween.tween_property(core_sprite, "position", legs_sprite.position, 0.01)  # Move pivot point
        tween.tween_property(core_sprite, "rotation_degrees", 20, 0.4)  # Rotate around new pivot
        # Adjust position to account for rotation around legs
        tween.parallel().tween_property(core_sprite, "position:x", legs_sprite.position.x - 5, 0.4)
        tween.parallel().tween_property(core_sprite, "position:y", legs_sprite.position.y - 10, 0.4)
    
    # Head rotates with forehead as origin
    if head_sprite:
        # Begin rotation at forehead pivot
        tween.tween_property(head_sprite, "rotation_degrees", 30, 0.45)
        # Adjust position to maintain forehead-based rotation
        tween.parallel().tween_property(head_sprite, "position:x", head_sprite.position.x + 5, 0.45) 
        tween.parallel().tween_property(head_sprite, "position:y", head_sprite.position.y + 8, 0.45)
    
    # Phase 3: Main body rotation around legs base
    
    # Legs stay in place but shrink slightly
    if legs_sprite:
        tween.tween_property(legs_sprite, "scale:y", 0.8, 0.5)
    
    # Instead of rotating the entire robot, we're keeping the legs as the base
    # and rotating core and head backwards
    
    # Core continues rotating around legs pivot point
    if core_sprite:
        tween.tween_property(core_sprite, "rotation_degrees", 45, 0.6)  # More rotation
        tween.parallel().tween_property(core_sprite, "position:y", legs_sprite.position.y - 15, 0.6) # Adjust position as it rotates
    
    # Head follows through with even more rotation
    if head_sprite:
        tween.parallel().tween_property(head_sprite, "rotation_degrees", 60, 0.6)  # Further head rotation
        tween.parallel().tween_property(head_sprite, "position:y", head_sprite.position.y + 15, 0.6)  # Adjust position
    
    # Phase 4: Final collapse - continue the rotation around legs
    
    # Core makes final rotation movement
    if core_sprite:
        tween.tween_property(core_sprite, "rotation_degrees", 75, 0.4)  # Final rotation around legs
        tween.parallel().tween_property(core_sprite, "position:y", legs_sprite.position.y - 12, 0.4) # Final position adjustment
    
    # Head makes final rotation
    if head_sprite:
        tween.parallel().tween_property(head_sprite, "rotation_degrees", 90, 0.4)  # Final head rotation
        tween.parallel().tween_property(head_sprite, "position:x", head_sprite.position.x + 5, 0.4) # X adjustment from rotation
    
    # Legs shrink a bit more for final effect
    if legs_sprite:
        tween.parallel().tween_property(legs_sprite, "scale:y", 0.7, 0.4)
    
    # Fade out with a slightly longer duration
    tween.tween_property(self, "modulate:a", 0.5, 0.5)
    
    # Connect to tween's finished signal to emit our own signal and restore frames
    tween.finished.connect(func(): 
        Log.pr("[RobotVisuals] Death animation completed with adjusted rotation origins")
        emit_signal("animation_completed")
    )
    
    return tween
