extends Node2D
class_name RobotVisuals

signal animation_completed

# References to sprite nodes
@onready var head_sprite: Sprite2D = %HeadSprite
@onready var core_sprite: Sprite2D = %CoreSprite
@onready var legs_sprite: Sprite2D = %LegsSprite
@onready var left_arm_sprite: Sprite2D = %Left_ArmSprite
@onready var right_arm_sprite: Sprite2D = %Right_ArmSprite

# Parts data for animation and behavior
var head_data = null
var core_data = null
var left_arm_data = null
var right_arm_data = null
var legs_data = null
var utility_data = null

# Define joint points for each body part
var joint_points = {
    "core": {
        "head": Vector2(0, -15),       # Where head connects to core (top)
        "left_arm": Vector2(-30, 0),   # Where left arm connects to core (left side)
        "right_arm": Vector2(30, 0),   # Where right arm connects to core (right side)
        "legs": Vector2(0, 30)         # Where legs connect to core (bottom)
    }
}

# Offset values for each sprite to position them correctly at their joints
var sprite_offsets = {
    "head": Vector2(0, 89.2),       # Offset for head (adjusted from scene position)
    "core": Vector2.ZERO,           # Core is the reference point
    "left_arm": Vector2(58.2, 1.8), # Offset for left arm (derived from scene)
    "right_arm": Vector2(-63.8, 1.8),# Offset for right arm (derived from scene)
    "legs": Vector2(0, -46)         # Offset for legs (adjusted from scene position)
}

# Animation variables
var anim_time: float = 0.0
var is_walking: bool = false
var is_attacking: bool = false
var is_hit: bool = false
var attack_direction: int = 1  # 1 = right, -1 = left

# Frame index mapping for each part type (synced with RobotFrame)
static var FRAME_INDEX_LEGS = 0
static var FRAME_INDEX_RIGHT_ARM = 10
static var FRAME_INDEX_LEFT_ARM = 20
static var FRAME_INDEX_HEAD = 30
static var FRAME_INDEX_CORE = 40
static var FRAME_INDEX_UTILITY = 50
static var LEFT_TO_RIGHT_OFFSET = 10
var left_to_right_offset = LEFT_TO_RIGHT_OFFSET

# Sprite frame data
var head_frames = 1   # Number of frames in head sprite
var core_frames = 1   # Number of frames in core sprite
var legs_frames = 1   # Number of frames in legs sprite
var arm_frames = 1    # Number of frames in arm sprites

# Current frame indices for animation
var head_frame = 0
var core_frame = 0
var legs_frame = 0
var left_arm_frame = 0
var right_arm_frame = 0

func _ready():
    
    # Set up base appearance with default positions
    set_default_positions()
    
    # Default sprite settings
    core_sprite.centered = true
    head_sprite.centered = true
    legs_sprite.centered = true
    left_arm_sprite.centered = true
    right_arm_sprite.centered = true
    
    # Initialize with default frames
    head_sprite.frame = FRAME_INDEX_HEAD
    core_sprite.frame = FRAME_INDEX_CORE
    left_arm_sprite.frame = FRAME_INDEX_LEFT_ARM
    right_arm_sprite.frame = FRAME_INDEX_RIGHT_ARM
    legs_sprite.frame = FRAME_INDEX_LEGS

# Set the default positions for all sprites
func set_default_positions():
    # Core is our reference point
    core_sprite.position = Vector2.ZERO
    
    # Position each part based on where it connects to the core
    head_sprite.position = joint_points.core.head - sprite_offsets.head
    left_arm_sprite.position = joint_points.core.left_arm - sprite_offsets.left_arm
    right_arm_sprite.position = joint_points.core.right_arm - sprite_offsets.right_arm
    legs_sprite.position = joint_points.core.legs - sprite_offsets.legs
    
    # Reset rotations
    head_sprite.rotation_degrees = 0
    core_sprite.rotation_degrees = 0
    left_arm_sprite.rotation_degrees = 0
    right_arm_sprite.rotation_degrees = 0
    legs_sprite.rotation_degrees = 0

# Function to position a part with respect to its parent part
func update_part_position(part_sprite: Sprite2D, parent_part: String, 
                         joint_name: String, rotation_degrees: float = 0, 
                         additional_offset: Vector2 = Vector2.ZERO):
    var part_name = part_sprite.name.replace("Sprite", "").to_lower()
    
    # Get the joint position on the parent
    var joint_pos = joint_points[parent_part][joint_name]
    
    # Calculate the new position with rotation
    var offset = sprite_offsets[part_name]
    
    if rotation_degrees != 0:
        # Apply rotation to the offset
        var rad = deg_to_rad(rotation_degrees)
        offset = offset.rotated(rad)
    
    # Set the final position
    part_sprite.position = joint_pos - offset + additional_offset
    part_sprite.rotation_degrees = rotation_degrees

# Helper for arm swinging animation
func swing_arm(arm_sprite: Sprite2D, angle: float, parent: String = "core"):
    var arm_type = "left_arm" if "Left" in arm_sprite.name else "right_arm"
    update_part_position(arm_sprite, parent, arm_type, angle)

# Helper for rotating a sprite with constraints
func rotate_constrained(sprite: Sprite2D, target_angle: float, min_angle: float, max_angle: float):
    var clamped_angle = clamp(target_angle, min_angle, max_angle)
    sprite.rotation_degrees = clamped_angle
    
# Clear all parts and reset to default
func clear_parts():
    # Clear part data
    head_data = null
    core_data = null
    left_arm_data = null
    right_arm_data = null
    legs_data = null
    utility_data = null
    
    # Reset frames to defaults
    head_sprite.frame = FRAME_INDEX_HEAD
    core_sprite.frame = FRAME_INDEX_CORE
    left_arm_sprite.frame = FRAME_INDEX_LEFT_ARM
    right_arm_sprite.frame = FRAME_INDEX_RIGHT_ARM
    legs_sprite.frame = FRAME_INDEX_LEGS
    
    # Reset animation frames
    set_animation_frames()

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
func set_part_sprites(head_frame_index = -1, core_frame_index = -1, legs_frame_index = -1,
                     left_arm_frame_index = -1, right_arm_frame_index = -1):
    # Set textures for each part if provided
        # Set frame if specified, otherwise use default
    if head_frame_index >= 0:
        head_sprite.frame = head_frame_index
    else:
        head_sprite.frame = FRAME_INDEX_HEAD


    if core_frame_index >= 0:
        core_sprite.frame = core_frame_index
    else:
        core_sprite.frame = FRAME_INDEX_CORE

    if legs_frame_index >= 0:
        legs_sprite.frame = legs_frame_index
    else:
        legs_sprite.frame = FRAME_INDEX_LEGS

    if left_arm_frame_index >= 0:
        left_arm_sprite.frame = left_arm_frame_index
    else:
        left_arm_sprite.frame = FRAME_INDEX_LEFT_ARM

    if right_arm_frame_index >= 0:
        right_arm_sprite.frame = right_arm_frame_index
    else:
        right_arm_sprite.frame = FRAME_INDEX_RIGHT_ARM


# Set animation frames data for each sprite
func set_animation_frames(head_frame_count = 1, core_frame_count = 1, legs_frame_count = 1, arm_frame_count = 1):
    print("RobotVisuals: Setting animation frames")
    head_frames = max(1, head_frame_count)
    core_frames = max(1, core_frame_count)
    legs_frames = max(1, legs_frame_count)
    arm_frames = max(1, arm_frame_count)
    
    # Don't reset current frames to preserve assigned frame indices
    # Just ensure they're within valid range
    head_frame = min(head_frame, head_frames - 1)
    core_frame = min(core_frame, core_frames - 1)
    legs_frame = min(legs_frame, legs_frames - 1)
    left_arm_frame = min(left_arm_frame, arm_frames - 1)
    right_arm_frame = min(right_arm_frame, arm_frames - 1)
    
    print("  Animation frames set - head: ", head_frames, ", core: ", core_frames, 
          ", legs: ", legs_frames, ", arms: ", arm_frames)
    
# Update animation frames from part data
func update_animation_frames():
    print("RobotVisuals: Updating animation frames")
    # Set animation frames based on part data
    var head_frame_count = head_data.get("frames", 1) if head_data else 1
    var core_frame_count = core_data.get("frames", 1) if core_data else 1
    var legs_frame_count = legs_data.get("frames", 1) if legs_data else 1
    
    # For arms, use the max frame count between left and right
    var left_arm_frame_count = left_arm_data.get("frames", 1) if left_arm_data else 1
    var right_arm_frame_count = right_arm_data.get("frames", 1) if right_arm_data else 1
    var arm_frame_count = max(left_arm_frame_count, right_arm_frame_count)
    
    print("  Frame counts - head: ", head_frame_count, ", core: ", core_frame_count, 
          ", legs: ", legs_frame_count, ", arms: ", arm_frame_count)
          
    # Remember current frame indices before setting animation frames
    var current_head_frame = head_sprite.frame
    var current_core_frame = core_sprite.frame
    var current_legs_frame = legs_sprite.frame
    var current_left_arm_frame = left_arm_sprite.frame
    var current_right_arm_frame = right_arm_sprite.frame
    
    # Apply the frame counts
    set_animation_frames(head_frame_count, core_frame_count, legs_frame_count, arm_frame_count)
    
    # Restore frame indices (as set_animation_frames resets them to 0)
    print("  Restoring frame indices")
    head_sprite.frame = current_head_frame
    core_sprite.frame = current_core_frame
    legs_sprite.frame = current_legs_frame
    left_arm_sprite.frame = current_left_arm_frame
    right_arm_sprite.frame = current_right_arm_frame

# Update visuals from robot part data (similar to RobotFrame)
func update_from_part_data(parts_data: Dictionary):
    print("RobotVisuals: Updating from part data")
    # Parts data should contain head, core, left_arm, right_arm, legs
    if parts_data.has("head") and parts_data.head != null:
        head_data = parts_data.head
        var frame_index = head_data.get("frame_index", FRAME_INDEX_HEAD)
        print("  Head frame_index: ", frame_index, " (default: ", FRAME_INDEX_HEAD, ")")
        head_sprite.frame = frame_index
        
    if parts_data.has("core") and parts_data.core != null:
        core_data = parts_data.core
        var frame_index = core_data.get("frame_index", FRAME_INDEX_CORE)
        print("  Core frame_index: ", frame_index, " (default: ", FRAME_INDEX_CORE, ")")
        core_sprite.frame = frame_index
        
    if parts_data.has("left_arm") and parts_data.left_arm != null:
        left_arm_data = parts_data.left_arm
        var frame_index = left_arm_data.get("frame_index", FRAME_INDEX_LEFT_ARM)
        print("  Left arm frame_index: ", frame_index, " (default: ", FRAME_INDEX_LEFT_ARM, ")")
        left_arm_sprite.frame = frame_index
        
    if parts_data.has("right_arm") and parts_data.right_arm != null:
        right_arm_data = parts_data.right_arm
        var frame_index = right_arm_data.get("frame_index", FRAME_INDEX_RIGHT_ARM)
        print("  Right arm frame_index: ", frame_index, " (default: ", FRAME_INDEX_RIGHT_ARM, ")")
        right_arm_sprite.frame = frame_index
        
    if parts_data.has("legs") and parts_data.legs != null:
        legs_data = parts_data.legs
        var frame_index = legs_data.get("frame_index", FRAME_INDEX_LEGS)
        print("  Legs frame_index: ", frame_index, " (default: ", FRAME_INDEX_LEGS, ")")
        legs_sprite.frame = frame_index
        
    if parts_data.has("utility") and parts_data.utility != null:
        utility_data = parts_data.utility
    
    # Update animation frames if part data includes frame counts
    update_animation_frames()

# Update sprite positions with offsets for animations
func update_positions(head_offset: Vector2 = Vector2.ZERO, core_offset: Vector2 = Vector2.ZERO, 
                     legs_offset: Vector2 = Vector2.ZERO, left_arm_offset: Vector2 = Vector2.ZERO, 
                     right_arm_offset: Vector2 = Vector2.ZERO):
    # Core is our reference point (with possible offset)
    core_sprite.position = core_offset
    
    # Position each part based on joints and offsets
    head_sprite.position = joint_points.core.head - sprite_offsets.head + head_offset
    legs_sprite.position = joint_points.core.legs - sprite_offsets.legs + legs_offset
    left_arm_sprite.position = joint_points.core.left_arm - sprite_offsets.left_arm + left_arm_offset
    right_arm_sprite.position = joint_points.core.right_arm - sprite_offsets.right_arm + right_arm_offset

# Animation functions
func animate_idle(_delta):
    # Subtle floating motion for idle
    var head_bob = Vector2(0, sin(anim_time * 2) * 2)
    var core_bob = Vector2(0, sin(anim_time * 2 + 0.2) * 1.5)
    var legs_bob = Vector2(0, sin(anim_time * 2 + 0.4) * 1)
    var left_arm_bob = Vector2(sin(anim_time * 1.5) * 2, 0)
    var right_arm_bob = Vector2(sin(anim_time * 1.5 + PI) * 2, 0)
    
    update_positions(head_bob, core_bob, legs_bob, left_arm_bob, right_arm_bob)
    
    # Animate frame if multiple frames exist
    if fmod(anim_time, 1.0) < 0.5:
        advance_frames(0)  # Idle animation - first frame

func animate_walking(_delta):
    # Walking animation
    var head_bob = Vector2(sin(anim_time * 7) * 2, sin(anim_time * 14) * 2)
    var core_bob = Vector2(sin(anim_time * 7) * 1.5, 0)
    var legs_bob = Vector2(0, abs(sin(anim_time * 14)) * 3)
    var left_arm_swing = Vector2(0, sin(anim_time * 7) * 5)
    var right_arm_swing = Vector2(0, sin(anim_time * 7 + PI) * 5)
    
    update_positions(head_bob, core_bob, legs_bob, left_arm_swing, right_arm_swing)
    
    # Animate walking frames (if any)
    if legs_frames > 1:
        legs_frame = int(fmod(anim_time * 10, legs_frames))
        update_frame(legs_sprite, legs_frame)
    
    # Animate arm frames (if any)
    if arm_frames > 1:
        left_arm_frame = int(fmod(anim_time * 5 + 2, arm_frames))
        right_arm_frame = int(fmod(anim_time * 5, arm_frames))
        update_frame(left_arm_sprite, left_arm_frame)
        update_frame(right_arm_sprite, right_arm_frame)

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

# Helper function to advance all frames
func advance_frames(amount: int):
    # Remember current base frames from sprite
    var head_base_frame = head_sprite.frame - head_frame
    var core_base_frame = core_sprite.frame - core_frame
    var legs_base_frame = legs_sprite.frame - legs_frame
    var left_arm_base_frame = left_arm_sprite.frame - left_arm_frame
    var right_arm_base_frame = right_arm_sprite.frame - right_arm_frame
    
    # Update frame counters (animation offsets)
    head_frame = (head_frame + amount) % max(1, head_frames)
    core_frame = (core_frame + amount) % max(1, core_frames)
    legs_frame = (legs_frame + amount) % max(1, legs_frames)
    left_arm_frame = (left_arm_frame + amount) % max(1, arm_frames)
    right_arm_frame = (right_arm_frame + amount) % max(1, arm_frames)
    
    # Update sprite frames, preserving the base frame index
    head_sprite.frame = head_base_frame + head_frame
    core_sprite.frame = core_base_frame + core_frame
    legs_sprite.frame = legs_base_frame + legs_frame
    left_arm_sprite.frame = left_arm_base_frame + left_arm_frame
    right_arm_sprite.frame = right_arm_base_frame + right_arm_frame
    
# Apply RobotFrame data directly to our visuals
func apply_robot_frame_data(robot_frame: RobotFrame):
    if not is_instance_valid(robot_frame):
        return
        
    var part_data = robot_frame.get_all_part_data()
    update_from_part_data(part_data)
    
    # Sync frame indices from RobotFrame to ensure consistency
    FRAME_INDEX_LEGS = robot_frame.FRAME_INDEX_LEGS
    FRAME_INDEX_RIGHT_ARM = robot_frame.FRAME_INDEX_RIGHT_ARM
    FRAME_INDEX_LEFT_ARM = robot_frame.FRAME_INDEX_LEFT_ARM
    FRAME_INDEX_HEAD = robot_frame.FRAME_INDEX_HEAD
    FRAME_INDEX_CORE = robot_frame.FRAME_INDEX_CORE
    FRAME_INDEX_UTILITY = robot_frame.FRAME_INDEX_UTILITY
    left_to_right_offset = robot_frame.left_to_right_offset
    
# Initialize from PlayerRobot parts data
func initialize_from_robot_parts(robot_parts: Dictionary):
    # Convert PlayerRobot parts to the format RobotVisuals needs
    var visual_parts = {}
    
    # Process each part type and convert to visual format
    if robot_parts.has("head") and robot_parts.head != null:
        visual_parts["head"] = convert_to_visual_part(robot_parts.head, "head")
    
    if robot_parts.has("core") and robot_parts.core != null:
        visual_parts["core"] = convert_to_visual_part(robot_parts.core, "core")
    
    if robot_parts.has("left_arm") and robot_parts.left_arm != null:
        visual_parts["left_arm"] = convert_to_visual_part(robot_parts.left_arm, "left_arm")
    
    if robot_parts.has("right_arm") and robot_parts.right_arm != null:
        visual_parts["right_arm"] = convert_to_visual_part(robot_parts.right_arm, "right_arm")
    
    if robot_parts.has("legs") and robot_parts.legs != null:
        visual_parts["legs"] = convert_to_visual_part(robot_parts.legs, "legs")
    
    if robot_parts.has("utility") and robot_parts.utility != null:
        visual_parts["utility"] = convert_to_visual_part(robot_parts.utility, "utility")
    
    # Update visuals with the converted parts
    update_from_part_data(visual_parts)

# Convert a robot part to a visual part
func convert_to_visual_part(part_data, part_type: String):
    if part_data == null:
        return null
    
    print("Converting part for ", part_type, ": ", part_data.get("name", "unnamed"))
        
    # Create a copy of the part data
    var visual_part = part_data.duplicate()
    
    # Debug part data
    print("  Part data keys: ", visual_part.keys())
    
    # Add frame index if not present
    if not visual_part.has("frame_index"):
        print("  No frame_index found, adding default based on part type")
        match part_type:
            "head":
                visual_part["frame_index"] = FRAME_INDEX_HEAD
                print("  Set head frame_index to ", FRAME_INDEX_HEAD)
            "core":
                visual_part["frame_index"] = FRAME_INDEX_CORE
                print("  Set core frame_index to ", FRAME_INDEX_CORE)
            "left_arm":
                visual_part["frame_index"] = FRAME_INDEX_LEFT_ARM
                print("  Set left_arm frame_index to ", FRAME_INDEX_LEFT_ARM)
            "right_arm":
                visual_part["frame_index"] = FRAME_INDEX_RIGHT_ARM
                print("  Set right_arm frame_index to ", FRAME_INDEX_RIGHT_ARM)
            "legs":
                visual_part["frame_index"] = FRAME_INDEX_LEGS
                print("  Set legs frame_index to ", FRAME_INDEX_LEGS)
            "utility":
                visual_part["frame_index"] = FRAME_INDEX_UTILITY
                print("  Set utility frame_index to ", FRAME_INDEX_UTILITY)
    else:
        print("  Found existing frame_index: ", visual_part.get("frame_index", 0))
    
    return visual_part

# Helper function to update a sprite's region or frame
func update_frame(sprite: Sprite2D, frame: int):
    if not sprite.texture:
        return
    
    if sprite.has_method("set_frame"):
        # If sprite has a frame property (AnimatedSprite2D, Sprite2D with sprite sheets)
        sprite.frame = frame
    else:
        # Fall back to region-based animation for regular Sprite2D
        var texture_width = sprite.texture.get_width()
        var frame_width = texture_width / max(1, head_frames)
        
        # Update region rect
        var region = Rect2(frame * frame_width, 0, frame_width, sprite.texture.get_height())
        sprite.region_enabled = true
        sprite.region_rect = region

# Animation triggers
func start_walking():
    is_walking = true
    is_attacking = false
    is_hit = false

func stop_walking():
    is_walking = false

func play_attack():
    is_attacking = true
    is_walking = false
    is_hit = false
    
    # Advance frames for attacking if available
    if arm_frames > 1:
        if attack_direction > 0:
            # Right arm attack
            right_arm_frame = (right_arm_frame + 1) % arm_frames
            update_frame(right_arm_sprite, right_arm_frame)
        else:
            # Left arm attack
            left_arm_frame = (left_arm_frame + 1) % arm_frames
            update_frame(left_arm_sprite, left_arm_frame)

func play_hit():
    is_hit = true
    is_attacking = false
    # Keep walking if already walking
    
    # Flash sprites red
    head_sprite.modulate = Color(1, 0.5, 0.5)
    core_sprite.modulate = Color(1, 0.5, 0.5)
    legs_sprite.modulate = Color(1, 0.5, 0.5)
    left_arm_sprite.modulate = Color(1, 0.5, 0.5)
    right_arm_sprite.modulate = Color(1, 0.5, 0.5)
    
    # Reset color after a short delay
    var timer = get_tree().create_timer(0.1)
    await timer.timeout
    
    head_sprite.modulate = Color(1, 1, 1)
    core_sprite.modulate = Color(1, 1, 1)
    legs_sprite.modulate = Color(1, 1, 1)
    left_arm_sprite.modulate = Color(1, 1, 1)
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
    
# Death animation where the robot falls on its back and flattens
func play_death_animation():
    # Stop other animations
    is_walking = false
    is_attacking = false
    is_hit = false
    
    # Create tween for smooth animation
    var tween = create_tween()
    
    # Falling backwards
    # First move everything slightly up
    tween.tween_property(head_sprite, "position:y", head_sprite.position.y - 10, 0.2)
    tween.parallel().tween_property(core_sprite, "position:y", core_sprite.position.y - 5, 0.2)
    tween.parallel().tween_property(legs_sprite, "position:y", legs_sprite.position.y - 5, 0.2)
    tween.parallel().tween_property(left_arm_sprite, "position:y", left_arm_sprite.position.y - 5, 0.2)
    tween.parallel().tween_property(right_arm_sprite, "position:y", right_arm_sprite.position.y - 5, 0.2)
    
    # Then rotate and fall back
    tween.tween_property(self, "rotation_degrees", 90, 0.3)
    
    # Move to final position
    tween.tween_property(self, "position:y", position.y + 20, 0.3)
    
    # Flatten by scaling vertically
    tween.tween_property(self, "scale:y", 0.2, 0.5)
    
    # Fade out
    tween.tween_property(self, "modulate:a", 0.5, 0.3)
    
    # Connect to tween's finished signal to emit our own signal
    tween.finished.connect(func(): emit_signal("animation_completed"))
    
    return tween
