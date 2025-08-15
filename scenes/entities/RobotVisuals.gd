extends Node2D
class_name RobotVisuals

# References to Labels for each body part
var head_label: Label
var body_label: Label
var left_arm_label: Label
var right_arm_label: Label

# Part visuals
var head_emoji: String = "💻"
var body_emoji: String = "🚧" 
var arm_emoji: String = "🗡️"

# Animation variables
var anim_time: float = 0.0
var is_walking: bool = false
var is_attacking: bool = false
var is_hit: bool = false
var attack_direction: int = 1  # 1 = right, -1 = left

# Available emojis for randomization
var head_options = ["🤖","💻", "🪖", "📸", "🚨", "👑", "⚪", "🟢", "🔵", "🔴"]
var arm_options = ["🎥", "🗡️", "📌", "🛡️", "🔪", "📢", "🦯", "🧹", "🪄", "🪓"]
var body_options = ["🚧", "🔒", "💎", "⚠️", "📅", "⬜", "🟥", "🟪", "🟦", "🟩", "🟨", "🟧"]

func _ready():
    # Create labels for each part
    head_label = Label.new()
    body_label = Label.new()
    left_arm_label = Label.new()
    right_arm_label = Label.new()
    
    # Add to scene - arms first so they're behind the body
    add_child(left_arm_label)
    add_child(right_arm_label)
    add_child(body_label)
    add_child(head_label)
    
    # Set up base appearance
    set_font_sizes()
    randomize_appearance()
    update_positions()

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

func set_font_sizes():
    # Set font sizes for each part
    var font_size = 32
    var arm_font_size = 28
    
    head_label.add_theme_font_size_override("font_size", font_size)
    body_label.add_theme_font_size_override("font_size", font_size)
    left_arm_label.add_theme_font_size_override("font_size", arm_font_size)
    right_arm_label.add_theme_font_size_override("font_size", arm_font_size)
    
    # Center align text
    head_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    left_arm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    right_arm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func randomize_appearance():
    # Randomly select emojis for each part
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    
    head_emoji = head_options[rng.randi() % head_options.size()]
    body_emoji = body_options[rng.randi() % body_options.size()]
    arm_emoji = arm_options[rng.randi() % arm_options.size()]
    
    # Apply the selected emojis
    head_label.text = head_emoji
    body_label.text = body_emoji
    left_arm_label.text = arm_emoji
    right_arm_label.text = arm_emoji
    
    # Mirror the right arm horizontally by flipping the scale
    right_arm_label.scale.x = -1

func update_positions(head_offset: Vector2 = Vector2.ZERO, body_offset: Vector2 = Vector2.ZERO, 
                     left_arm_offset: Vector2 = Vector2.ZERO, right_arm_offset: Vector2 = Vector2.ZERO):
    # Base positions
    var base_head_pos = Vector2(0, -30)
    var base_body_pos = Vector2(0, 0) 
    var base_left_arm_pos = Vector2(-35, 0)
    var base_right_arm_pos = Vector2(75, 0)
    
    # Apply positions with offsets
    head_label.position = base_head_pos + head_offset
    body_label.position = base_body_pos + body_offset
    left_arm_label.position = base_left_arm_pos + left_arm_offset
    right_arm_label.position = base_right_arm_pos + right_arm_offset

# Animation functions
func animate_idle(_delta):
    # Subtle floating motion for idle
    var head_bob = Vector2(0, sin(anim_time * 2) * 2)
    var body_bob = Vector2(0, sin(anim_time * 2 + 0.2) * 1.5)
    var left_arm_bob = Vector2(sin(anim_time * 1.5) * 2, 0)
    var right_arm_bob = Vector2(sin(anim_time * 1.5 + PI) * 2, 0)
    
    update_positions(head_bob, body_bob, left_arm_bob, right_arm_bob)

func animate_walking(_delta):
    # Walking animation
    var head_bob = Vector2(sin(anim_time * 7) * 2, sin(anim_time * 14) * 2)
    var body_bob = Vector2(sin(anim_time * 7) * 1.5, 0)
    var left_arm_swing = Vector2(0, sin(anim_time * 7) * 5)
    var right_arm_swing = Vector2(0, sin(anim_time * 7 + PI) * 5)
    
    update_positions(head_bob, body_bob, left_arm_swing, right_arm_swing)

func animate_attack(_delta):
    # Attack animation - punch or weapon swing
    var head_offset = Vector2(attack_direction * 2, 0)
    var body_offset = Vector2(attack_direction * 1, 0)
    
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
    
    update_positions(head_offset, body_offset, left_arm_offset, right_arm_offset)
    
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
    var body_shake = Vector2(rng.randf_range(-shake_intensity * 0.5, shake_intensity * 0.5), 
                           rng.randf_range(-shake_intensity * 0.5, shake_intensity * 0.5))
    var left_arm_shake = Vector2(rng.randf_range(-shake_intensity * 0.8, shake_intensity * 0.8), 
                               rng.randf_range(-shake_intensity * 0.8, shake_intensity * 0.8))
    var right_arm_shake = Vector2(rng.randf_range(-shake_intensity * 0.8, shake_intensity * 0.8), 
                                rng.randf_range(-shake_intensity * 0.8, shake_intensity * 0.8))
    
    update_positions(head_shake, body_shake, left_arm_shake, right_arm_shake)
    
    # End hit animation after a short duration
    if is_hit:
        is_hit = false
        await get_tree().create_timer(0.2).timeout

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

func play_hit():
    is_hit = true
    is_attacking = false
    # Keep walking if already walking
    
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
    tween.tween_property(head_label, "position:y", head_label.position.y - 10, 0.2)
    tween.parallel().tween_property(body_label, "position:y", body_label.position.y - 5, 0.2)
    tween.parallel().tween_property(left_arm_label, "position:y", left_arm_label.position.y - 5, 0.2)
    tween.parallel().tween_property(right_arm_label, "position:y", right_arm_label.position.y - 5, 0.2)
    
    # Then rotate and fall back
    tween.tween_property(self, "rotation_degrees", 90, 0.3)
    
    # Move to final position
    tween.tween_property(self, "position:y", position.y + 20, 0.3)
    
    # Flatten by scaling vertically
    tween.tween_property(self, "scale:y", 0.2, 0.5)
    
    # Fade out
    tween.tween_property(self, "modulate:a", 0.5, 0.3)
    
    return tween
