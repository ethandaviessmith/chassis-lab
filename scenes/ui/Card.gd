extends Control
class_name Card

signal drop_attempted(card, drop_position, target)
signal drag_started(draggable)

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
        # Disconnect any existing connections first
        if drag_drop.drag_started.is_connected(_on_drag_started):
            drag_drop.drag_started.disconnect(_on_drag_started)
        if drag_drop.drag_ended.is_connected(_on_drag_ended):
            drag_drop.drag_ended.disconnect(_on_drag_ended)
        if drag_drop.drop_attempted.is_connected(_on_drop_attempted):
            drag_drop.drop_attempted.disconnect(_on_drop_attempted)
            
        # Connect the signals
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

var _hand_container: HandContainer = null

func get_hand_container() -> HandContainer:
    # If we already have a stored reference, return it
    if _hand_container and is_instance_valid(_hand_container):
        return _hand_container
        
    # Otherwise, try to find the HandContainer, but only check parent
    # to avoid deep recursion when scanning the scene
    var parent = get_parent()
    if parent and parent is HandContainer:
        # If we're directly parented to a HandContainer, use that
        _hand_container = parent
        print("Card found HandContainer as direct parent: ", parent.name)
    
    # Note: We removed the full scene scan to prevent recursion
    
    # Register it as a drop target if found
    if _hand_container and drag_drop:
        drag_drop.register_drop_target(_hand_container)
        
    return _hand_container

func set_hand_container(container: HandContainer):
    if not container or not is_instance_valid(container):
        return
        
    # Store reference to hand container
    _hand_container = container
    print("Card ", data.get("name", "Unknown"), " - Stored HandContainer reference: ", container.name)
        
    if not drag_drop:
        return
        
    print("Card ", data.get("name", "Unknown"), " - Setting HandContainer target: ", container.name)
    
    # Register the container as a drop target directly
    drag_drop.register_drop_target(container)
    
    # Also register any Area2D child that might be used for collision detection
    for child in container.get_children():
        if child is Area2D:
            print("Also registering HandContainer's Area2D as drop target")
            drag_drop.register_drop_target(child)
            break

func _process(delta):
    # If not being dragged, animate toward target position if set
    if not drag_drop or not drag_drop.is_currently_dragging():
        # For attached cards, we don't need to animate if we're already parented to the slot
        # But still allow for initial movement to the correct position
        if has_meta("attached_to_chassis") and get_parent() is ChassisSlot:
            # Still allow movement if not yet positioned correctly
            if target_position != Vector2.ZERO and global_position.distance_to(target_position) > 10.0:
                print("Card attached to chassis but needs positioning: ", target_position)
            else:
                return
            
        # If the card was just returned to hand from a slot, we need to make sure it gets repositioned
        var just_returned = has_meta("was_attached")
        
        if target_position != Vector2.ZERO:
            # Only animate if we're not already at the target
            if global_position.distance_to(target_position) > 1.0:
                # Debug for position tracking
                print("Card moving to target_position: current=", global_position, " target=", target_position)
                    
                # Use delta for frame-rate independent movement with increased speed
                # Use higher speed for cards just returned from slots
                var speed_factor = 30.0 if just_returned else 15.0
                global_position = global_position.lerp(target_position, delta * speed_factor)
                
                # If very far off (either at origin or far away), just snap to position
                if global_position == Vector2.ZERO or global_position.distance_to(target_position) > 500 or just_returned:
                    print("Card snapping to target_position: ", target_position)
                    global_position = target_position
                    
                    # Clear the was_attached flag after we've snapped to position
                    if has_meta("was_attached"):
                        remove_meta("was_attached")

# DragDrop event handlers
func _on_drag_started(_draggable):
    # Card is being dragged, emit signal to notify listeners
    emit_signal("drag_started", self)
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
    
    # Check if we're already handling this card in another part of the code
    if has_meta("being_returned_to_hand") or has_meta("handling_drop") or has_meta("being_processed_by_buildview"):
        print("Card: Preventing recursive drop handling in _on_drop_attempted")
        return
    
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
    
# Support part durability functionality
func reduce_durability(amount: int = 1):
    if data.has("durability"):
        data["durability"] = int(data["durability"]) - amount
        
        # Update the durability display
        if durability_label:
            durability_label.text = str(int(data["durability"]))
        
        # Visual feedback for damaged part
        if int(data["durability"]) <= 0:
            modulate = Color(0.7, 0.7, 0.7, 0.8)  # Grayed out
        elif int(data["durability"]) <= 2:
            modulate = Color(1.0, 0.7, 0.7, 1.0)  # Reddish for low durability
        
        print("Card durability reduced to: ", data["durability"])

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

        
# Helper to find all nodes in scene
func _find_all_nodes(node, result_array):
    result_array.append(node)
    for child in node.get_children():
        _find_all_nodes(child, result_array)


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
    
    # We should NOT call force_end_drag here as it causes recursion
    # Just reset positions and let drag end naturally
    
    # Handle differently based on parent
    if parent and parent is HandContainer:
        # Make sure we're in the hand container's children list
        if not parent.cards.has(self):
            parent.cards.append(self)
        
        # Get the global position from the hand container
        var new_pos = parent.get_original_position(self)
        
        print("Resetting card position to: ", new_pos)
        
        # Set target position for smooth animation
        target_position = new_pos
        
        # If card position is at origin, very far from target, or was previously attached to a slot
        # set it directly to avoid long animations when returning from slots
        if global_position.distance_to(Vector2.ZERO) < 10 or global_position.distance_to(new_pos) > 500 or has_meta("was_attached"):
            global_position = new_pos
            remove_meta("was_attached")
            print("Card position snap to: ", global_position)
        
        # Trigger a reposition in the parent container
        if parent.has_method("_reposition_cards"):
            parent._reposition_cards()
        
        # Ensure we're visible and can receive input again
        modulate.a = 1.0
    elif parent:
        # We're in a different container (like a chassis slot)
        
        # If we were dragged from a slot and not dropped on another slot,
        # we need to be returned to the hand - use our stored reference
        if _hand_container and _hand_container is HandContainer:
            # Remove from current parent
            parent.remove_child(self)
            
            # Add to hand container
            _hand_container.add_child(self)
            
            # Let hand container reposition
            if _hand_container.has_method("_reposition_cards"):
                _hand_container._reposition_cards()
    else:
        # No parent at all
        
        # Use our stored reference to hand container
        if _hand_container and _hand_container is HandContainer:
            _hand_container.add_child(self)
            if _hand_container.has_method("_reposition_cards"):
                _hand_container._reposition_cards()
    
    # Reset scale and z-index
    scale = Vector2(1.0, 1.0)
    z_index = 0
    
    # Clear any highlights
    set_highlight(false)
    
    # Make sure we're on top of whatever container we're in
    parent = get_parent()
    if parent:
        parent.move_child(self, parent.get_child_count() - 1)
