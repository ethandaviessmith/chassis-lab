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
@onready var utility_sprite = $UtilitySprite

# Frame index mapping for AsepriteWizard sprites
# Base indices for each part type
var FRAME_INDEX_LEGS = 0
var FRAME_INDEX_RIGHT_ARM = 10
var FRAME_INDEX_LEFT_ARM = 20
var FRAME_INDEX_HEAD = 30
var FRAME_INDEX_CORE = 40
var FRAME_INDEX_UTILITY = 50
var left_to_right_offset = 10

# Parts data for visual representation
var scrapper_data = null
var head_data = null
var core_data = null
var left_arm_data = null
var right_arm_data = null
var legs_data = null
var utility_data = null

func _ready():
    # Initialize all sprites to show empty frames
    if head_sprite:
        head_sprite.frame = FRAME_INDEX_HEAD
    if core_sprite:
        core_sprite.frame = FRAME_INDEX_CORE
    if left_arm_sprite:
        left_arm_sprite.frame = FRAME_INDEX_LEFT_ARM
    if right_arm_sprite:
        right_arm_sprite.frame = FRAME_INDEX_RIGHT_ARM
    if legs_sprite:
        legs_sprite.frame = FRAME_INDEX_LEGS
    if utility_sprite:
        utility_sprite.frame = FRAME_INDEX_UTILITY
    
    update_visuals()

# Create a part object from card data
func create_part_from_card(card_data: Part, is_right: bool = false):
    # Convert card data to a part object that can be used for visuals
    var part = {
        "name": card_data.name,
        "type": card_data.type,
        "cost": card_data.cost,
        "heat": card_data.heat,
        "durability": card_data.durability,
        "effects": card_data.effects,
        "frame_index": 0
    }
    
    # Get frame index from card data
    if card_data.frame:
        part.frame_index = card_data.frame
        if card_data.type.to_lower() == "arm" and !is_right:
            part.frame_index += left_to_right_offset
    return part

# Attach a part to a specific slot (visual only)
func attach_part_visual(part_data, slot: String):
    Log.pr("Attaching part ", part_data.name, " to ", slot, " ", part_data.frame_index)
    match slot:
        "scrapper":
            scrapper_data = part_data
            # Scrapper parts don't have sprites but we store the data
        "head":
            head_data = part_data
            if head_sprite and part_data.frame_index:
                head_sprite.frame = part_data.frame_index
        "core":
            core_data = part_data
            if core_sprite and part_data.frame_index:
                core_sprite.frame = part_data.frame_index
        "left_arm":
            left_arm_data = part_data
            if left_arm_sprite and part_data.frame_index:
                left_arm_sprite.frame = part_data.frame_index
        "right_arm":
            right_arm_data = part_data
            if right_arm_sprite and part_data.frame_index:
                right_arm_sprite.frame = part_data.frame_index
        "legs":
            legs_data = part_data
            if legs_sprite and part_data.frame_index:
                legs_sprite.frame = part_data.frame_index
        "utility":
            utility_data = part_data
            if utility_sprite and part_data.frame_index:
                utility_sprite.frame = part_data.frame_index
    
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
                head_sprite.frame = FRAME_INDEX_HEAD  # Show empty head frame
        "core":
            removed_data = core_data
            core_data = null
            if core_sprite:
                core_sprite.frame = FRAME_INDEX_CORE  # Show empty core frame
        "left_arm":
            removed_data = left_arm_data
            left_arm_data = null
            if left_arm_sprite:
                left_arm_sprite.frame = FRAME_INDEX_LEFT_ARM  # Show empty left arm frame
        "right_arm":
            removed_data = right_arm_data
            right_arm_data = null
            if right_arm_sprite:
                right_arm_sprite.frame = FRAME_INDEX_RIGHT_ARM  # Show empty right arm frame
        "legs":
            removed_data = legs_data
            legs_data = null
            if legs_sprite:
                legs_sprite.frame = FRAME_INDEX_LEGS  # Show empty legs frame
        "utility":
            removed_data = utility_data
            utility_data = null
            if utility_sprite:
                utility_sprite.frame = FRAME_INDEX_UTILITY  # Show empty utility frame
    
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
    
    # Set sprites to their empty frames
    if head_sprite:
        head_sprite.frame = FRAME_INDEX_HEAD
    if core_sprite:
        core_sprite.frame = FRAME_INDEX_CORE
    if left_arm_sprite:
        left_arm_sprite.frame = FRAME_INDEX_LEFT_ARM
    if right_arm_sprite:
        right_arm_sprite.frame = FRAME_INDEX_RIGHT_ARM
    if legs_sprite:
        legs_sprite.frame = FRAME_INDEX_LEGS
    if utility_sprite:
        utility_sprite.frame = FRAME_INDEX_UTILITY
    
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
            if card is Card and card.data:
                print("  - Adding visual for ", slot_name, ": ", card.data.name, card.data.frame)
                
                # Convert slot names to robot part names and determine if it's a right arm
                var robot_slot = slot_name
                var is_right_arm = false
                if slot_name == "arm_left":
                    robot_slot = "left_arm"
                    is_right_arm = false
                elif slot_name == "arm_right":
                    robot_slot = "right_arm"
                    is_right_arm = true
                
                # Create a part object from card data and attach visually
                var part_data = create_part_from_card(card.data, is_right_arm)
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
