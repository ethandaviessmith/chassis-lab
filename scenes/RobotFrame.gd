extends Node2D
class_name RobotFrame

signal robot_frame_updated
signal part_attached(part_data, slot_name)
signal part_removed(slot_name)
signal part_clicked(slot_name)

# Configuration options
@export var show_durability: bool = false  # Set to true in combat view

# Visual references for robot parts
@onready var head_sprite = $HeadSprite
@onready var core_sprite = $CoreSprite
@onready var left_arm_sprite = $LeftArmSprite
@onready var right_arm_sprite = $RightArmSprite
@onready var legs_sprite = $LegsSprite
@onready var utility_sprite = $UtilitySprite

# Durability indicator references (optional)
@onready var head_durability = $HeadDurability if has_node("HeadDurability") else null
@onready var core_durability = $CoreDurability if has_node("CoreDurability") else null
@onready var left_arm_durability = $LeftArmDurability if has_node("LeftArmDurability") else null
@onready var right_arm_durability = $RightArmDurability if has_node("RightArmDurability") else null
@onready var legs_durability = $LegsDurability if has_node("LegsDurability") else null
@onready var utility_durability = $UtilityDurability if has_node("UtilityDurability") else null

# Frame index mapping for AsepriteWizard sprites
# Base indices for each part type
var FRAME_INDEX_LEGS = 0
var FRAME_INDEX_RIGHT_ARM = 10
var FRAME_INDEX_LEFT_ARM = 20
var FRAME_INDEX_HEAD = 30
var FRAME_INDEX_CORE = 40
var FRAME_INDEX_UTILITY = 50
static var LEFT_RIGHT_OFFSET = 10

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
        if head_durability:
            head_durability.gui_input.connect(_on_part_input.bind("head"))
    if core_sprite:
        core_sprite.frame = FRAME_INDEX_CORE
        if core_durability:
            core_durability.gui_input.connect(_on_part_input.bind("core"))
    if left_arm_sprite:
        left_arm_sprite.frame = FRAME_INDEX_LEFT_ARM
        if left_arm_durability:
            left_arm_durability.gui_input.connect(_on_part_input.bind("left_arm"))
    if right_arm_sprite:
        right_arm_sprite.frame = FRAME_INDEX_RIGHT_ARM
        if right_arm_durability:
            right_arm_durability.gui_input.connect(_on_part_input.bind("right_arm"))
    if legs_sprite:
        legs_sprite.frame = FRAME_INDEX_LEGS
        if legs_durability:
            legs_durability.gui_input.connect(_on_part_input.bind("legs"))
    if utility_sprite:
        utility_sprite.frame = FRAME_INDEX_UTILITY
        if utility_durability:
            utility_durability.gui_input.connect(_on_part_input.bind("utility"))

    update_visuals()

# Create a part object from card data
func create_part_from_card(card_data: Part, is_right: bool = false):
    # Create a new Part instance
    var part = Part.new()
    
    # Copy properties from card_data to the new Part
    part.id = card_data.id
    part.part_name = card_data.part_name
    part.type = card_data.type
    part.cost = card_data.cost
    part.heat = card_data.heat
    part.durability = card_data.durability
    part.max_durability = card_data.max_durability
    part.description = card_data.description
    part.manufacturer = card_data.manufacturer
    part.rarity = card_data.rarity
    
    # Copy effects (if they exist and are accessible)
    if card_data.get("effects") != null:
        # Assuming effects are handled appropriately within Part class
        part.effects = card_data.effects.duplicate() if card_data.effects is Array else []
    
    # Get frame index from card data
    if card_data.frame:
        part.frame = card_data.frame
        if card_data.type.to_lower() == "arm" and !is_right:
            part.frame += LEFT_RIGHT_OFFSET
    
    return part

# Attach a part to a specific slot (visual only)
func attach_part_visual(part_data, slot: String):
    var part_name = ""
    var frame_value = 0
    
    # Handle different types for logging and frame access
    if part_data is Part:
        part_name = part_data.part_name
        frame_value = part_data.frame
    else:
        part_name = part_data.name if part_data.has("name") else "Unknown"
        frame_value = part_data.frame_index if part_data.has("frame_index") else (part_data.frame if part_data.has("frame") else 0)
    
    Log.pr("Attaching part ", part_name, " to ", slot, " frame:", frame_value)
    
    match slot:
        "scrapper":
            scrapper_data = part_data
            # Scrapper parts don't have sprites but we store the data
        "head":
            head_data = part_data
            if head_sprite:
                head_sprite.frame = frame_value
            if show_durability and head_durability:
                setup_durability_pips(head_durability, part_data)
        "core":
            core_data = part_data
            if core_sprite:
                core_sprite.frame = frame_value
            if show_durability and core_durability:
                setup_durability_pips(core_durability, part_data)
        "left_arm":
            left_arm_data = part_data
            if left_arm_sprite:
                left_arm_sprite.frame = frame_value
            if show_durability and left_arm_durability:
                setup_durability_pips(left_arm_durability, part_data)
        "right_arm":
            right_arm_data = part_data
            if right_arm_sprite:
                right_arm_sprite.frame = frame_value
            if show_durability and right_arm_durability:
                setup_durability_pips(right_arm_durability, part_data)
        "legs":
            legs_data = part_data
            if legs_sprite:
                legs_sprite.frame = frame_value
            if show_durability and legs_durability:
                setup_durability_pips(legs_durability, part_data)
        "utility":
            utility_data = part_data
            if utility_sprite:
                utility_sprite.frame = frame_value
            if show_durability and utility_durability:
                setup_durability_pips(utility_durability, part_data)
    
    print("RobotFrame: Attached ", part_name, " to ", slot)
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
            if show_durability and head_durability:
                clear_durability_pips(head_durability)
        "core":
            removed_data = core_data
            core_data = null
            if core_sprite:
                core_sprite.frame = FRAME_INDEX_CORE  # Show empty core frame
            if show_durability and core_durability:
                clear_durability_pips(core_durability)
        "left_arm":
            removed_data = left_arm_data
            left_arm_data = null
            if left_arm_sprite:
                left_arm_sprite.frame = FRAME_INDEX_LEFT_ARM  # Show empty left arm frame
            if show_durability and left_arm_durability:
                clear_durability_pips(left_arm_durability)
        "right_arm":
            removed_data = right_arm_data
            right_arm_data = null
            if right_arm_sprite:
                right_arm_sprite.frame = FRAME_INDEX_RIGHT_ARM  # Show empty right arm frame
            if show_durability and right_arm_durability:
                clear_durability_pips(right_arm_durability)
        "legs":
            removed_data = legs_data
            legs_data = null
            if legs_sprite:
                legs_sprite.frame = FRAME_INDEX_LEGS  # Show empty legs frame
            if show_durability and legs_durability:
                clear_durability_pips(legs_durability)
        "utility":
            removed_data = utility_data
            utility_data = null
            if utility_sprite:
                utility_sprite.frame = FRAME_INDEX_UTILITY  # Show empty utility frame
            if show_durability and utility_durability:
                clear_durability_pips(utility_durability)
    
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

# Setup durability pips based on part's max durability
func setup_durability_pips(durability_container: Control, part_data):
    # Clear existing pips
    clear_durability_pips(durability_container)
    
    if not show_durability or not part_data:
        return
    
    var max_durability = 0
    var current_durability = 0
    
    # Handle different types
    if part_data is Part:
        current_durability = part_data.durability
        max_durability = part_data.max_durability
    else:
        # Legacy dictionary format
        max_durability = part_data.get("durability", 0)
        current_durability = part_data.get("current_durability", max_durability)
    
    # Define styling constants
    const PIP_SIZE = Vector2(6, 6)  # Width, Height of each pip
    const PIP_SPACING = 1  # Horizontal spacing between pips
    const PIP_OUTLINE = 1  # Outline thickness (set to 0 for no outline)
    const PIP_COLOR = Color(0.2, 0.8, 0.2)  # Green for filled pips
    
    # Create a container for the pips with proper spacing
    var pip_row = HBoxContainer.new()
    pip_row.add_theme_constant_override("separation", PIP_SPACING)
    durability_container.add_child(pip_row)
    
    # Create pips for durability
    for i in range(max_durability):
        # Create a container for the pip if we want an outline
        var pip_container
        if PIP_OUTLINE > 0:
            pip_container = Control.new()
            pip_container.custom_minimum_size = PIP_SIZE + Vector2(PIP_OUTLINE * 2, PIP_OUTLINE * 2)
            
            # Create border as a dark outline
            var border = ColorRect.new()
            border.color = Color(0.1, 0.1, 0.1, 1.0)  # Dark outline
            border.size = pip_container.custom_minimum_size
            border.position = Vector2.ZERO
            pip_container.add_child(border)
        else:
            # If no outline, just use a container
            pip_container = Control.new()
            pip_container.custom_minimum_size = PIP_SIZE
        
        # Create the actual pip (background)
        var pip = ColorRect.new()
        pip.custom_minimum_size = PIP_SIZE
        pip.size = PIP_SIZE
        pip.color = PIP_COLOR.darkened(0.7)  # Start with darkened/faded color
        
        # For outlined pips, position properly
        if PIP_OUTLINE > 0:
            pip.position = Vector2(PIP_OUTLINE, PIP_OUTLINE)
            pip_container.add_child(pip)
        else:
            pip_container = pip  # If no outline, the pip is the container
        
        # Store a filled part reference in each pip for later updates
        var filled_part = ColorRect.new()
        filled_part.name = "FilledPart"
        filled_part.color = PIP_COLOR
        
        # Set filled state based on current durability
        if i < current_durability:
            # Fully filled pip
            filled_part.size = Vector2(PIP_SIZE.x, PIP_SIZE.y)
            filled_part.position = Vector2(0, 0)
        else:
            # Empty pip
            filled_part.size = Vector2(PIP_SIZE.x, 0)
            filled_part.position = Vector2(0, PIP_SIZE.y)
        
        pip.add_child(filled_part)
        
        # Add to container
        pip_row.add_child(pip_container)
    
    # Add an animation for the pips (optional)
    var tween = create_tween()
    tween.set_parallel(true)
    for i in range(min(current_durability, pip_row.get_child_count())):
        var pip_container = pip_row.get_child(i)
        tween.tween_property(pip_container, "modulate", Color(1.2, 1.2, 1.2), 0.2)
        tween.tween_property(pip_container, "modulate", Color(1, 1, 1), 0.3)

# Clear all durability pips from a container
func clear_durability_pips(durability_container: Control):
    if not durability_container:
        return
        
    for child in durability_container.get_children():
        child.queue_free()

# Update durability display for a specific part
func update_part_durability(slot_name: String, current_durability: int):
    if not show_durability:
        return
        
    var part_data = null
    var durability_container = null
    
    match slot_name:
        "head":
            part_data = head_data
            durability_container = head_durability
        "core":
            part_data = core_data
            durability_container = core_durability
        "left_arm":
            part_data = left_arm_data
            durability_container = left_arm_durability
        "right_arm":
            part_data = right_arm_data
            durability_container = right_arm_durability
        "legs":
            part_data = legs_data
            durability_container = legs_durability
        "utility":
            part_data = utility_data
            durability_container = utility_durability
    
    if part_data and durability_container:
        part_data.current_durability = current_durability
        setup_durability_pips(durability_container, part_data)

# Flash effect for when a part is used in combat
func flash_part(slot_name: String, color: Color = Color(1, 1, 0.5)):
    var sprite = null
    
    match slot_name:
        "head": sprite = head_sprite
        "core": sprite = core_sprite
        "left_arm": sprite = left_arm_sprite
        "right_arm": sprite = right_arm_sprite
        "legs": sprite = legs_sprite
        "utility": sprite = utility_sprite
    
    if sprite:
        # Create a tween for the flash effect
        var tween = create_tween()
        tween.tween_property(sprite, "modulate", color, 0.1)
        tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.2)

# Show damage effect on a part
func show_part_damage(slot_name: String):
    flash_part(slot_name, Color(1, 0.3, 0.3))  # Red flash

# Show part usage effect
func show_part_usage(slot_name: String):
    flash_part(slot_name, Color(0.3, 0.7, 1))  # Blue flash

# Show part overheating effect
func show_part_overheat(slot_name: String):
    flash_part(slot_name, Color(1, 0.5, 0))  # Orange flash
    
# Handle part input events (clicking)
func _on_part_input(event: InputEvent, slot_name: String):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        var part_data = null
        match slot_name:
            "head": part_data = head_data
            "core": part_data = core_data
            "left_arm": part_data = left_arm_data
            "right_arm": part_data = right_arm_data
            "legs": part_data = legs_data
            "utility": part_data = utility_data
            
        if part_data:
            emit_signal("part_clicked", slot_name)

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
