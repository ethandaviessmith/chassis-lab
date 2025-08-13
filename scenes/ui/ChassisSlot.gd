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
    if not card_data or not card_data.has("type"):
        return false
        
    match slot_type:
        "Head":
            return card_data.type == "Head"
        "Core":
            return card_data.type == "Core"
        "Arm":
            return card_data.type == "Arm"
        "Legs":
            return card_data.type == "Legs"
        "Scrapper":
            return card_data.type == "Scrapper"
        "Utility":
            return card_data.type == "Utility"
        _:
            return false

# Highlight the slot (for when valid card is being dragged over)
func highlight(is_valid: bool = true):
    if is_valid:
        background.color = highlight_color
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

# Remove highlight
func unhighlight():
    # Stop any running tweens - using stored reference
    if background.has_meta("active_tween"):
        var tween = background.get_meta("active_tween")
        if tween and tween.is_valid() and tween.is_running():
            tween.kill()
        background.remove_meta("active_tween")
            
    background.color = normal_color
    is_highlighted = false
    
    # Reset modulate
    modulate = Color(1.0, 1.0, 1.0, 1.0)

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
        
        # Make sure the part is a child of this slot
        if part.get_parent() != self:
            if part.get_parent():
                part.get_parent().remove_child(part)
            add_child(part)
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
