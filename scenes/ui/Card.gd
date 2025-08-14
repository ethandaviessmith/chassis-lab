extends Control
class_name Card

signal drop_attempted(card, drop_position, target)

# Card data
var data: Dictionary = {}
var target_position = Vector2.ZERO

# Card state - affects scaling behavior
enum State { HAND, CHASSIS_SLOT, DRAGGING }
var state: State = State.HAND

# References to UI elements
@onready var name_label = $NameLabel
@onready var type_label = $TypeLabel
@onready var cost_label = $CostLabel
@onready var heat_label = $StatsContainer/HeatLabel
@onready var durability_label = $StatsContainer/DurabilityLabel
@onready var effects_label = $EffectsLabel
@onready var image = $Image
@onready var background = $Background
@onready var background2 = $Background2
@onready var highlight = $Highlight
@onready var drag_drop = $DragDrop

func _ready():
    if highlight:
        highlight.visible = false

    # Configure the DragDrop component
    if drag_drop:
        drag_drop.drag_started.connect(_on_drag_started)
        drag_drop.drag_ended.connect(_on_drag_ended)
        drag_drop.drop_attempted.connect(_on_drop_attempted)
    
    # Connect mouse enter/exit signals
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    
    # Make sure only the card itself receives input, not its background
    # Configure children to pass input to the card
    for child in get_children():
        if child is Control and not child is DragDrop:
            child.mouse_filter = Control.MOUSE_FILTER_PASS

# Centralized scale management that respects card state
func set_card_scale(scale_factor: float, scale_type: String = "normal"):
    var base_scale = Vector2(1.0, 1.0)
    
    # Adjust base scale based on card state
    match state:
        State.HAND:
            base_scale = Vector2(1.0, 1.0)
        State.CHASSIS_SLOT:
            base_scale = Vector2(0.5, 0.5)  # Smaller when in chassis
        State.DRAGGING:
            base_scale = Vector2(1.0, 1.0)  # Normal size when dragging
    
    # Apply the scale factor to the base scale
    var final_scale = base_scale * scale_factor
    scale = final_scale
    
    print("Card ", data.get("name", "Unknown"), " scale set to ", final_scale, " (state: ", State.keys()[state], ", factor: ", scale_factor, ", type: ", scale_type, ")")

# Set the card's state and update scale accordingly
func set_card_state(new_state: State):
    if state != new_state:
        print("Card ", data.get("name", "Unknown"), " state changed from ", State.keys()[state], " to ", State.keys()[new_state])
        state = new_state
        set_card_scale(1.0, "state_change")

# Handle mouse hover
func _on_mouse_entered():
    # Apply hover effect (slight scale up or highlight)
    if not drag_drop or not drag_drop.is_currently_dragging():
        set_card_scale(1.05, "hover")
        z_index = 1  # Bring card to front

# Handle mouse exit
func _on_mouse_exited():
    # Remove hover effect if not being dragged
    if not drag_drop or not drag_drop.is_currently_dragging():
        set_card_scale(1.0, "unhover")
        z_index = 0  # Reset z-index

func initialize(card_data: Dictionary):
    data = card_data
    
    # Set up UI elements
    name_label.text = data.name
    type_label.text = data.type
    cost_label.text = str(int(data.cost))
    heat_label.text = str(int(data.heat))
    durability_label.text = str(int(data.durability))
    
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
    background2.modulate = bg_color

func _process(delta):
    # If not being dragged and not attached to chassis, animate toward target position if set
    if not drag_drop or not drag_drop.is_currently_dragging():
        # Don't animate if card is attached to a chassis slot
        if has_meta("attached_to_chassis"):
            return
            
        if target_position != Vector2.ZERO:
            # Only animate if we're not already at the target
            if global_position.distance_to(target_position) > 1.0:
                # Use delta for frame-rate independent movement with increased speed (15.0)
                global_position = global_position.lerp(target_position, delta * 15.0)
                
                # If very far off (either at origin or far away), just snap to position
                if global_position == Vector2.ZERO or global_position.distance_to(target_position) > 500:
                    global_position = target_position

# DragDrop event handlers
func _on_drag_started(_draggable):
    # Card is being dragged, emit signal to notify listeners
    set_card_state(State.DRAGGING)
    z_index = 100
    set_card_scale(1.05, "drag_start")

func _on_drag_ended(_draggable):
    # Card drag has ended - state will be set by BuildView when dropped
    z_index = 0
    set_card_scale(1.0, "drag_end")
    
    # Remove all highlights
    set_highlight(false)

func _on_drop_attempted(_draggable, target):
    # Get the drop position
    var mouse_pos = get_viewport().get_mouse_position()
    # Let external systems handle the drop attempt
    emit_signal("drop_attempted", self, mouse_pos, target)

# This has been replaced by the DragDrop component
# _input functionality is now handled by DragDrop

# Helper function to find ChassisSlot nodes
func _find_chassis_slots(node, result_array):
    # Check if the node has the class_name we're looking for
    if node.get_class() == "Control" and node.get("slot_type") != null:
        # This is likely a ChassisSlot
        result_array.append(node)
    
    for child in node.get_children():
        _find_chassis_slots(child, result_array)

func is_being_dragged() -> bool:
    return drag_drop and drag_drop.is_currently_dragging()

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

# Input handling is now managed by the DragDrop component

func set_highlight(enabled: bool, is_compatible: bool = true):
    highlight.visible = enabled
    
    # Set highlight color based on compatibility
    if enabled:
        if is_compatible:
            highlight.modulate = Color(1.0, 1.0, 0.3)  # Yellow highlight for compatible slots
            
            # Create a subtle pulsing effect for valid slot highlighting
            # Kill any existing tween first
            if highlight.has_meta("active_tween"):
                var old_tween = highlight.get_meta("active_tween")
                if old_tween and old_tween.is_valid() and old_tween.is_running():
                    old_tween.kill()
            
            # Create new tween and store a reference to it
            var tween = create_tween()
            tween.tween_property(highlight, "modulate:a", 0.4, 0.5)
            tween.tween_property(highlight, "modulate:a", 0.8, 0.5)
            tween.set_loops()
            
            # Store reference to the tween on the highlight node
            highlight.set_meta("active_tween", tween)
            
            # Add a slight scale effect using centralized system
            set_card_scale(1.05, "highlight")
        else:
            highlight.modulate = Color(1.0, 0.3, 0.3)  # Red highlight for incompatible slots
            set_card_scale(1.0, "highlight_invalid")
    else:
        # Stop any running tweens that might be affecting our highlight
        # In Godot 4.4, we need to track our tweens manually instead of using get_tweens()
        if highlight and highlight.has_meta("active_tween"):
            var tween = highlight.get_meta("active_tween")
            if tween and tween.is_valid() and tween.is_running():
                tween.kill()
            highlight.remove_meta("active_tween")
        
        # Reset scale if not dragging
        if not drag_drop or not drag_drop.is_currently_dragging():
            scale = Vector2(1.0, 1.0)

# These methods are replaced by the DragDrop component and 
# our new handlers: _on_drag_started and _on_drag_ended

func get_card_type() -> String:
    return data.type

# Update visual state based on available energy
func update_affordability(available_energy: int):
    if not cost_label:
        return
    
    var card_cost = int(data.get("cost", 0))
    
    if card_cost > available_energy:
        # Card is too expensive - grey it out
        cost_label.modulate = Color.RED
        modulate = Color(0.7, 0.7, 0.7, 1.0)  # Grey out the entire card
    else:
        # Card is affordable - normal colors
        cost_label.modulate = Color.WHITE
        modulate = Color(1.0, 1.0, 1.0, 1.0)  # Normal color

func reset_position():
    # Ask parent container for proper position
    var parent = get_parent()
    
    # Make sure drag operations are ended
    if drag_drop and drag_drop.is_currently_dragging():
        drag_drop.force_end_drag()
    
    # Handle differently based on parent
    if parent and parent is HandContainer:
        # Make sure we're in the hand container's children list
        if not parent.cards.has(self):
            parent.cards.append(self)
        
        # Get the global position from the hand container
        var new_pos = parent.get_original_position(self)
        
        # Set target position for smooth animation
        target_position = new_pos
        
        # If card position is at origin or very far from target, set it directly
        if global_position.distance_to(Vector2.ZERO) < 10 or global_position.distance_to(new_pos) > 500:
            global_position = new_pos
        
        # Trigger a reposition in the parent container
        if parent.has_method("_reposition_cards"):
            parent._reposition_cards()
        
        # Ensure we're visible and can receive input again
        modulate.a = 1.0
    elif parent:
        # We're in a different container (like a chassis slot)
        
        # If we were dragged from a slot and not dropped on another slot,
        # we need to be returned to the hand
        var hand_container = get_tree().root.find_node("HandContainer", true, false)
        if hand_container and hand_container is HandContainer:
            # Remove from current parent
            parent.remove_child(self)
            
            # Add to hand container
            hand_container.add_child(self)
            
            # Let hand container reposition
            hand_container._reposition_cards()
    else:
        # No parent at all
        
        # Try to find hand container
        var hand_container = get_tree().root.find_node("HandContainer", true, false)
        if hand_container and hand_container is HandContainer:
            hand_container.add_child(self)
            hand_container._reposition_cards()
    
    # Reset scale and z-index
    scale = Vector2(1.0, 1.0)
    z_index = 0
    
    # Clear any highlights
    set_highlight(false)
    
    # Make sure we're on top of whatever container we're in
    parent = get_parent()
    if parent:
        parent.move_child(self, parent.get_child_count() - 1)
