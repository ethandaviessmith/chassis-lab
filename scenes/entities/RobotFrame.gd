extends Node2D
class_name RobotFrame

signal robot_frame_updated
signal part_attached(part_data, slot_name)
signal part_removed(slot_name)

# Visual references for robot parts
@onready var head_sprite = $HeadSprite
@onready var core_sprite = $CoreSprite
@onready var left_arm_sprite = $LeftArmSprite
@onready var right_arm_sprite = $RightArmSprite
@onready var legs_sprite = $LegsSprite

# Parts data for visual representation
var scrapper_data = null
var head_data = null
var core_data = null
var left_arm_data = null
var right_arm_data = null
var legs_data = null
var utility_data = null

func _ready():
    update_visuals()

# Create a part object from card data
func create_part_from_card(card_data: Dictionary):
    # Convert card data to a part object that can be used for visuals
    var part = {
        "name": card_data.get("name", "Unknown Part"),
        "type": card_data.get("type", "Unknown"),
        "cost": card_data.get("cost", 0),
        "heat": card_data.get("heat", 0),
        "durability": card_data.get("durability", 1),
        "effects": card_data.get("effects", []),
        "sprite": null  # Will be set from image path if available
    }
    
    # Load sprite if image path is provided
    if card_data.has("image") and card_data.image != "":
        var texture = load(card_data.image)
        if texture:
            part.sprite = texture
    
    return part

# Attach a part to a specific slot (visual only)
func attach_part_visual(part_data, slot: String):
    match slot:
        "scrapper":
            scrapper_data = part_data
            # Scrapper parts don't have sprites but we store the data
        "head":
            head_data = part_data
            if head_sprite and part_data.has("sprite") and part_data.sprite:
                head_sprite.texture = part_data.sprite
                head_sprite.visible = true
        "core":
            core_data = part_data
            if core_sprite and part_data.has("sprite") and part_data.sprite:
                core_sprite.texture = part_data.sprite
                core_sprite.visible = true
        "left_arm":
            left_arm_data = part_data
            if left_arm_sprite and part_data.has("sprite") and part_data.sprite:
                left_arm_sprite.texture = part_data.sprite
                left_arm_sprite.visible = true
        "right_arm":
            right_arm_data = part_data
            if right_arm_sprite and part_data.has("sprite") and part_data.sprite:
                right_arm_sprite.texture = part_data.sprite
                right_arm_sprite.visible = true
        "legs":
            legs_data = part_data
            if legs_sprite and part_data.has("sprite") and part_data.sprite:
                legs_sprite.texture = part_data.sprite
                legs_sprite.visible = true
        "utility":
            utility_data = part_data
            # Utility parts don't have sprites but we store the data
    
    print("RobotFrame: Attached ", part_data.name, " to ", slot)
    emit_signal("part_attached", part_data, slot)
    emit_signal("robot_frame_updated")
    update_visuals()

# Remove a part from a specific slot (visual only)
func remove_part_visual(slot: String):
    var removed_data = null
    
    match slot:
        "scrapper":
            removed_data = scrapper_data
            scrapper_data = null
        "head":
            removed_data = head_data
            head_data = null
            if head_sprite:
                head_sprite.texture = null
                head_sprite.visible = false
        "core":
            removed_data = core_data
            core_data = null
            if core_sprite:
                core_sprite.texture = null
                core_sprite.visible = false
        "left_arm":
            removed_data = left_arm_data
            left_arm_data = null
            if left_arm_sprite:
                left_arm_sprite.texture = null
                left_arm_sprite.visible = false
        "right_arm":
            removed_data = right_arm_data
            right_arm_data = null
            if right_arm_sprite:
                right_arm_sprite.texture = null
                right_arm_sprite.visible = false
        "legs":
            removed_data = legs_data
            legs_data = null
            if legs_sprite:
                legs_sprite.texture = null
                legs_sprite.visible = false
        "utility":
            removed_data = utility_data
            utility_data = null
    
    if removed_data:
        print("RobotFrame: Removed ", removed_data.name, " from ", slot)
        emit_signal("part_removed", slot)
        emit_signal("robot_frame_updated")
    
    update_visuals()

# Clear all parts
func clear_all_parts():
    scrapper_data = null
    head_data = null
    core_data = null
    left_arm_data = null
    right_arm_data = null
    legs_data = null
    utility_data = null
    
    # Clear visual sprites
    if head_sprite:
        head_sprite.texture = null
        head_sprite.visible = false
    if core_sprite:
        core_sprite.texture = null
        core_sprite.visible = false
    if left_arm_sprite:
        left_arm_sprite.texture = null
        left_arm_sprite.visible = false
    if right_arm_sprite:
        right_arm_sprite.texture = null
        right_arm_sprite.visible = false
    if legs_sprite:
        legs_sprite.texture = null
        legs_sprite.visible = false
    
    emit_signal("robot_frame_updated")
    update_visuals()

# Build the visual robot from chassis slot data
func build_robot_visuals(attached_parts: Dictionary):
    # Clear existing parts
    clear_all_parts()
    
    # Process slots in specific order
    var slot_order = ["scrapper", "head", "core", "arm_left", "arm_right", "legs", "utility"]
    
    print("RobotFrame: Building robot visuals from chassis:")
    for slot_name in slot_order:
        if attached_parts.has(slot_name) and is_instance_valid(attached_parts[slot_name]):
            var card = attached_parts[slot_name]
            if card is Card and card.data.size() > 0:
                print("  - Adding visual for ", slot_name, ": ", card.data.name)
                
                # Convert slot names to robot part names
                var robot_slot = slot_name
                if slot_name == "arm_left":
                    robot_slot = "left_arm"
                elif slot_name == "arm_right":
                    robot_slot = "right_arm"
                
                # Create a part object from card data and attach visually
                var part_data = create_part_from_card(card.data)
                attach_part_visual(part_data, robot_slot)
    
    print("RobotFrame: Visual build complete")

# Update visual effects and animations
func update_visuals():
    # Handle visual updates, animations, etc.
    # This could include:
    # - Part glow effects
    # - Assembly animations
    # - Damage effects
    # - Heat effects
    pass

# Get all part data for export to RobotFighter
func get_all_part_data() -> Dictionary:
    return {
        "scrapper": scrapper_data,
        "head": head_data,
        "core": core_data,
        "left_arm": left_arm_data,
        "right_arm": right_arm_data,
        "legs": legs_data,
        "utility": utility_data
    }

# Play build animation (placeholder for future implementation)
func play_build_animation():
    # TODO: Implement robot assembly animation
    print("RobotFrame: Playing build animation")
    
    # Example animation sequence:
    # 1. Flash each part as it's "assembled"
    # 2. Play assembly sound effects
    # 3. Show energy charging effects
    # 4. Final ready pose
    
    # For now, just a simple tween effect
    if has_method("create_tween"):
        var tween = create_tween()
        tween.tween_property(self, "modulate:a", 0.5, 0.2)
        tween.tween_property(self, "modulate:a", 1.0, 0.2)
        tween.tween_property(self, "modulate:a", 0.5, 0.2)
        tween.tween_property(self, "modulate:a", 1.0, 0.2)

# Check if robot has minimum required parts for combat
func is_combat_ready() -> bool:
    # Robot needs at least a core to function
    return core_data != null

# Get visual representation info for UI
func get_build_summary() -> String:
    var parts = []
    if scrapper_data: parts.append("Scrapper: " + scrapper_data.name)
    if head_data: parts.append("Head: " + head_data.name)
    if core_data: parts.append("Core: " + core_data.name)
    if left_arm_data: parts.append("Left Arm: " + left_arm_data.name)
    if right_arm_data: parts.append("Right Arm: " + right_arm_data.name)
    if legs_data: parts.append("Legs: " + legs_data.name)
    if utility_data: parts.append("Utility: " + utility_data.name)
    
    if parts.size() == 0:
        return "Empty chassis"
    else:
        return "Robot with " + str(parts.size()) + " parts"
