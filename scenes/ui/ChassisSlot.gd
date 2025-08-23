@tool
extends Control
class_name ChassisSlot

# The type of part this slot accepts
@export var slot_type: String = "Head"  # Head, Core, Arm, Legs

# Visual properties
@export var normal_color: Color = Color(0.5, 0.5, 0.5, 0.3)
@export var highlight_color: Color = Color(0.9, 0.8, 0.2, 0.5)  # Yellow highlight
@export var invalid_color: Color = Color(0.8, 0.2, 0.2, 0.3)    # Red for invalid type

# Internal state
var is_highlighted: bool = false
var has_part: bool = false
var current_part = null

# UI Elements
var background: ColorRect
var label: Label


func _ready():
    # Look for existing Label in children
    for child in get_children():
        if child is Label:
            label = child
            break
    
    # Look for existing background in children
    for child in get_children():
        if child is ColorRect and child != background:
            background = child
            background.color = normal_color
            break
    
    # Create background if none exists
    if not background:
        background = ColorRect.new()
        background.color = normal_color
        background.size = size
        background.position = Vector2.ZERO
        background.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(background)
        # Move to back
        move_child(background, 0)
    
    # Create label if none exists
    if not label:
        label = Label.new()
        label.text = slot_type.capitalize()
        label.position = Vector2(10, 40)
        label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(label)
    
    # Make sure this control resizes properly
    resized.connect(_on_resized)

# Called when the slot is resized
func _on_resized():
    if background:
        background.size = size

# Check if a card is compatible with this slot
func is_compatible_with_card(card_data) -> bool:
    if not card_data:
        return false
    
    # Handle both Part objects and dictionary data
    var card_type = ""
    var card_heat = 0
    var card_name = "Unknown"
    
    if card_data is Part:
        card_type = card_data.type
        card_heat = card_data.heat
        card_name = card_data.part_name
    else:
        # Fall back to dictionary access
        card_type = card_data.get("type", "")
        card_heat = card_data.get("heat", 0)
        card_name = card_data.get("name", "Unknown")
    
    if not card_type:
        return false
    
    # Special case for scrapper - it accepts any card with heat > 0
    if slot_type == "Scrapper":
        if card_heat > 0:
            print("Card is compatible with Scrapper: ", card_name, " - Heat: ", card_heat)
            return true
        else:
            print("Card rejected by Scrapper (no heat): ", card_name)
            return false
            
    # Case insensitive comparison for better compatibility
    var card_type_lower = card_type.to_lower()
    var slot_type_lower = slot_type.to_lower()
    
    match slot_type_lower:
        "head":
            return card_type_lower == "head"
        "core":
            return card_type_lower == "core"
        "arm":
            return card_type_lower == "arm"
        "legs":
            return card_type_lower == "legs"
        "utility":
            return card_type_lower == "utility"
        _:
            return false

# Highlight the slot (for when valid card is being dragged over)
func highlight(is_valid: bool = true):
    if is_valid:
        background.color = highlight_color
        print("ChassisSlot.highlight called for: ", slot_type, " - valid: ", is_valid)
        # Make highlight more visible for valid slots
        modulate = Color(1.2, 1.2, 0.8, 1.0)  # Slightly brighter yellow
        
        # Kill any existing tween first
        if background.has_meta("active_tween"):
            var old_tween = background.get_meta("active_tween")
            if old_tween and old_tween.is_valid() and old_tween.is_running():
                old_tween.kill()
        
        # Add a subtle pulse animation
        var tween = create_tween()
        tween.tween_property(background, "color", highlight_color.lightened(0.3), 0.5)
        tween.tween_property(background, "color", highlight_color, 0.5)
        tween.set_loops()
        
        # Store reference to the tween
        background.set_meta("active_tween", tween)
    else:
        pass
        # background.color = invalid_color
        # # Make invalid slots have a red tint
        # modulate = Color(1.2, 0.8, 0.8, 1.0)  # Slightly reddish
        
    is_highlighted = true

# Set highlight state (compatible with DragDrop system)
func set_highlight(enabled: bool, is_compatible: bool = true):
    print("ChassisSlot.set_highlight called for: ", slot_type, " - enabled: ", enabled, ", compatible: ", is_compatible)
    if enabled:
        highlight(is_compatible)
    # else:
    #     unhighlight()

# Remove highlight
func unhighlight():
    print("ChassisSlot.unhighlight called for: ", slot_type)
    
    # Stop any running tweens - using stored reference
    if background and background.has_meta("active_tween"):
        var tween = background.get_meta("active_tween")
        if tween and tween.is_valid() and tween.is_running():
            tween.kill()
        background.remove_meta("active_tween")
    
    # Make sure we have a valid background reference
    if background:
        background.color = normal_color
    
    is_highlighted = false
    
    # Reset modulate
    modulate = Color(1.0, 1.0, 1.0, 1.0)
    
    # Cancel any pending highlights
    var active_tweens = get_tree().get_nodes_in_group("slot_highlight_tween")
    for tween in active_tweens:
        if tween.is_valid() and tween.is_running():
            tween.kill()

# Set the part in this slot
func set_part(part):
    # Clear any existing part first
    if current_part != null:
        clear_part()
    
    current_part = part
    has_part = part != null
    
    # Change appearance when filled
    if has_part:
        background.color = normal_color.darkened(0.2)
        print("Slot " + slot_type + " now has part: " + str(part))
        
        # Mark the card as attached to the chassis
        # This is important to prevent animation issues
        if part is Card:
            part.set_meta("attached_to_chassis", slot_type)
            
            # Ensure drag/drop still works
            if part.has_node("DragDrop"):
                var drag_drop = part.get_node("DragDrop")
                drag_drop.enabled = true # Make sure dragging is enabled
        
        # Make sure the part is a child of this slot
        if part.get_parent() != self:
            if part.get_parent():
                part.get_parent().remove_child(part)
            add_child(part)
            
            # Center the part in the slot
            if part is Card:
                # Calculate center position accounting for the card's scaled size
                var slot_center = size / 2
                var card_size = part.size
                
                # Account for the card's scale in chassis slot (0.5)
                var card_visual_size = card_size * 0.5
                
                # Position should be such that the visual center of the card
                # aligns with the center of the slot
                var centered_position = slot_center - (card_visual_size / 2)
                part.position = centered_position
                
                print("Centering part in slot " + slot_type + " at position: " + str(centered_position))
                
            print("Added part to slot " + slot_type)
    else:
        background.color = normal_color

# Clear the part from this slot
func clear_part():
    # Don't remove the part from the scene, just clear our reference
    # The BuildView will handle moving it elsewhere (like back to hand)
    current_part = null
    has_part = false
    background.color = normal_color
    print("Slot " + slot_type + " cleared")

# Returns card of part
func get_part() -> Node:
    return current_part
