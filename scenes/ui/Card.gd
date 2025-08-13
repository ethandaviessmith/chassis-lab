extends Control
class_name Card

signal card_dragged(card)
signal card_dropped(card, drop_position)

# Card data
var data: Dictionary = {}
var draggable = true
var is_being_dragged = false # Main drag state variable
var drag_offset = Vector2.ZERO
var original_position = Vector2.ZERO
var target_position = Vector2.ZERO

# References to UI elements
@onready var name_label = $NameLabel
@onready var type_label = $TypeLabel
@onready var cost_label = $StatsContainer/CostLabel
@onready var heat_label = $StatsContainer/HeatLabel
@onready var durability_label = $StatsContainer/DurabilityLabel
@onready var effects_label = $EffectsLabel
@onready var image = $Image
@onready var background = $Background
@onready var highlight = $Highlight

func _ready():
    highlight.visible = false

func initialize(card_data: Dictionary):
    data = card_data
    
    # Set up UI elements
    name_label.text = data.name
    type_label.text = data.type
    cost_label.text = str(data.cost)
    heat_label.text = str(data.heat)
    durability_label.text = str(data.durability)
    
    # Format effects
    var effects_text = ""
    for effect in data.effects:
        if effects_text != "":
            effects_text += "\n"
        effects_text += effect.description
    
    effects_label.text = effects_text
    
    # Set image if available
    if "image" in data and data.image != "":
        var texture = load(data.image)
        if texture:
            image.texture = texture
            
    # Set background based on rarity
    var bg_color = Color(0.3, 0.3, 0.3)
    match data.rarity.to_lower():
        "common":
            bg_color = Color(0.4, 0.4, 0.4)
        "uncommon":
            bg_color = Color(0.2, 0.5, 0.2)
        "rare":
            bg_color = Color(0.2, 0.2, 0.7)
        "epic":
            bg_color = Color(0.6, 0.2, 0.6)
    
    background.modulate = bg_color

func _process(delta):
    # If not being dragged, animate toward target position if set
    if not is_being_dragged and target_position != Vector2.ZERO:
        # Only animate if we're not already at the target
        if global_position.distance_to(target_position) > 1.0:
            # Use delta for frame-rate independent movement
            global_position = global_position.lerp(target_position, delta * 10.0)
            
            # Debug positioning
            if global_position.distance_to(target_position) > 100:
                print("Card moving: current=", global_position, " target=", target_position)
                # If very far off, just snap to position
                if global_position.distance_to(target_position) > 500:
                    global_position = target_position

func _input(event):
    if not draggable or not is_being_dragged:
        return
        
    if event is InputEventMouseMotion:
        # Move card with mouse
        global_position = event.global_position - drag_offset
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
        # End drag
        is_being_dragged = false
        var drop_position = get_global_mouse_position()
        emit_signal("card_dropped", self, drop_position)
        
        # HandContainer will handle returning card to position

func _get_drop_target():
    # Raycast to find potential drop targets
    # This is a placeholder - actual implementation depends on physics setup
    var space_state = get_world_2d().direct_space_state
    var query = PhysicsPointQueryParameters2D.new()
    query.position = get_global_mouse_position()
    query.collision_mask = 2  # Assuming drop targets are on layer 2
    
    var result = space_state.intersect_point(query, 1)
    if result.size() > 0:
        return result[0].collider
    return null

func _on_gui_input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed and draggable:
            # Start drag
            is_being_dragged = true
            original_position = global_position
            drag_offset = get_local_mouse_position()
            emit_signal("card_dragged", self)
            # Move card to top of draw order
            get_parent().move_child(self, get_parent().get_child_count() - 1)

func set_highlight(enabled: bool, is_compatible: bool = true):
    highlight.visible = enabled
    
    # Set highlight color based on compatibility
    if enabled:
        if is_compatible:
            highlight.modulate = Color(1.0, 1.0, 0.3)  # Yellow highlight for compatible slots
        else:
            highlight.modulate = Color(1.0, 0.3, 0.3)  # Red highlight for incompatible slots

func get_card_type() -> String:
    return data.type

func reset_position():
    # Ask parent container for proper position if it's a HandContainer
    var parent = get_parent()
    if parent and parent is HandContainer:
        # Get the global position from the hand container
        var new_pos = parent.get_original_position(self)
        
        # Set target position for smooth animation
        target_position = new_pos
        
        # Print debug info
        print("Resetting card position to global: ", new_pos)
        print("Current card position: ", global_position)
        
        # If card position is at origin (0,0), set it directly to avoid animation from wrong position
        if global_position.distance_to(Vector2.ZERO) < 10:
            global_position = new_pos
        
        # Ensure we're visible and can receive input again
        modulate.a = 1.0
        mouse_filter = Control.MOUSE_FILTER_STOP
    else:
        # Fallback to stored original position
        if original_position != Vector2.ZERO:
            global_position = original_position
        else:
            print("WARNING: No original position saved for card")
    
    # Reset dragging state
    is_being_dragged = false
    
    # Make sure we're on top of the hand
    if parent:
        parent.move_child(self, parent.get_child_count() - 1)
