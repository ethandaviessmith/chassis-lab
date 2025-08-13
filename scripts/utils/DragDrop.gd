@tool
extends Node
class_name DragDrop

## A component that adds drag and drop functionality to its parent Control node.
## Add this as a child of any Control node to make it draggable.

signal drag_started(draggable)
signal drag_ended(draggable)
signal drop_attempted(draggable, target)
signal drop_succeeded(draggable, target)
signal drop_failed(draggable)

# Configuration properties
@export var enabled: bool = true
@export var keep_in_parent: bool = false  # If true, draggable will be constrained to parent bounds
@export var return_on_invalid_drop: bool = true  # If true, draggable returns to original position when not dropped on valid target
@export_enum("Top", "Center") var drag_handle: int = 0  # 0: Drag from anywhere, 1: Drag from center
@export var debug_mode: bool = false  # Enable detailed logging

# Internal state
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var original_parent = null
var valid_drop_targets: Array = []

# The parent node (the one this component is attached to)
var parent_control: Control = null

func _ready():
    # Find our parent control node
    if get_parent() is Control:
        parent_control = get_parent()
        
        if debug_mode:
            Log.pr("[DragDrop] Attached to: ", parent_control.name)
        
        # Connect to input events on parent
        if not parent_control.gui_input.is_connected(_on_parent_gui_input):
            parent_control.gui_input.connect(_on_parent_gui_input)
            
        # Store initial properties
        original_position = parent_control.global_position
        original_parent = parent_control.get_parent()
        
        # Configure child controls to pass mouse events to parent
        _configure_child_controls()
        
        # Ensure the parent control can receive input
        parent_control.mouse_filter = Control.MOUSE_FILTER_STOP
        
        # Make sure we're processing input and can take focus
        parent_control.focus_mode = Control.FOCUS_ALL
        
        # Enable global input processing
        set_process_input(true)
    else:
        Log.error("[DragDrop] Must be attached to a Control node, but parent is: ", get_parent().get_class())
        push_warning("DragDrop must be attached to a Control node to function properly")
        
# Helper to convert mouse_filter enum to string for debugging
func _get_mouse_filter_name(filter_value: int) -> String:
    match filter_value:
        Control.MOUSE_FILTER_STOP: return "MOUSE_FILTER_STOP"
        Control.MOUSE_FILTER_PASS: return "MOUSE_FILTER_PASS"
        Control.MOUSE_FILTER_IGNORE: return "MOUSE_FILTER_IGNORE"
        _: return "UNKNOWN (" + str(filter_value) + ")"
        
func _configure_child_controls():
    """Configure all child Controls to pass mouse events to parent"""
    if not parent_control:
        return
        
    if debug_mode:
        Log.pr("[DragDrop] Configuring child controls for ", parent_control.name)
    
    # Set mouse filter for all direct children that are Controls
    for child in parent_control.get_children():
        if child is Control and child != self:
            # Make child pass mouse events to parent
            child.mouse_filter = Control.MOUSE_FILTER_PASS
            
            # If this is a ColorRect, ensure it doesn't block input
            if child is ColorRect:
                child.mouse_filter = Control.MOUSE_FILTER_PASS

func register_drop_target(node: Node, valid_types: Array = []):
    # Store valid drop target with acceptable types
    valid_drop_targets.append({
        "node": node,
        "valid_types": valid_types
    })
    if debug_mode:
        print("Registered drop target: ", node.name, " for types: ", valid_types)

func _on_parent_gui_input(event):
    if not enabled or not parent_control:
        return
    
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if debug_mode:
            Log.pr("[DragDrop] Mouse button event on " + parent_control.name)
        
        if event.pressed and not is_dragging:
            # Start drag when mouse button is pressed
            start_drag(event.global_position)
            get_viewport().set_input_as_handled()
                
        elif not event.pressed and is_dragging:
            # End drag when mouse button is released
            end_drag()
            get_viewport().set_input_as_handled()
    
    # Handle global input to catch events that might be missed
func _input(event):
    if not enabled or not parent_control:
        return
        
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        # Check if the mouse position is over our parent control
        var parent_rect = parent_control.get_global_rect()
        var mouse_is_over_parent = parent_rect.has_point(event.global_position)
        
        # If mouse is over our parent control or we're already dragging
        if mouse_is_over_parent or is_dragging:
            if event.pressed and not is_dragging:
                # Start drag when mouse button is pressed
                start_drag(event.global_position)
                get_viewport().set_input_as_handled()
            elif not event.pressed and is_dragging:
                # End drag when mouse button is released
                end_drag()
                get_viewport().set_input_as_handled()

func _unhandled_input(event):
    if not enabled or not parent_control or not is_dragging:
        return
        
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
        # This catches mouse releases that might happen outside the control
        end_drag()

func start_drag(global_mouse_pos: Vector2):
    if is_dragging or not parent_control:
        return
    
    if debug_mode:
        Log.pr("[DragDrop] Starting drag of: " + parent_control.name)
    
    # Store the current state
    is_dragging = true
    original_position = parent_control.global_position
    
    # Calculate drag offset based on mouse position
    if drag_handle == 0:  # Top (use exact mouse position)
        drag_offset = global_mouse_pos - parent_control.global_position
    else:  # Center
        drag_offset = parent_control.size / 2
    
    # Bring to front
    var parent = parent_control.get_parent()
    if parent and parent.has_method("move_child"):
        parent.move_child(parent_control, parent.get_child_count() - 1)
    
    # Temporarily increase z_index to ensure it's drawn on top
    if "z_index" in parent_control:
        parent_control.z_index = 100
    
    # Signal that drag has started
    emit_signal("drag_started", parent_control)
    
    # Update drop targets to show valid ones
    highlight_valid_targets(true)
    
    # Make sure we get input events globally while dragging
    set_process_unhandled_input(true)

func end_drag():
    if not is_dragging or not parent_control:
        return
    
    if debug_mode:
        Log.pr("[DragDrop] Ending drag of: " + parent_control.name)
    
    # Find drop target under mouse
    var mouse_pos = parent_control.get_viewport().get_mouse_position()
    var drop_target = get_drop_target_at_position(mouse_pos)
    
    if drop_target:
        # Try to drop on target
        emit_signal("drop_attempted", parent_control, drop_target.node)
        
        # Check if drop is valid
        if is_valid_drop(parent_control, drop_target):
            emit_signal("drop_succeeded", parent_control, drop_target.node)
        else:
            # Invalid drop
            if return_on_invalid_drop:
                parent_control.global_position = original_position
            emit_signal("drop_failed", parent_control)
    else:
        # No target found, return to original position if configured to do so
        if return_on_invalid_drop:
            parent_control.global_position = original_position
        emit_signal("drop_failed", parent_control)
    
    # Update drop targets to hide highlights
    highlight_valid_targets(false)
    
    # Reset state
    emit_signal("drag_ended", parent_control)
    is_dragging = false
    
    # Reset z-index if we changed it
    if "z_index" in parent_control:
        parent_control.z_index = 0
        
    # Stop processing unhandled input
    set_process_unhandled_input(false)

func _process(_delta):
    if is_dragging and parent_control:
        # Get mouse position from viewport
        var mouse_pos = parent_control.get_viewport().get_mouse_position()
        
        # Move parent control with mouse
        var new_position = mouse_pos - drag_offset
        parent_control.global_position = new_position
        
        # Constrain to parent bounds if configured
        if keep_in_parent and original_parent is Control:
            var parent_rect = original_parent.get_global_rect()
            var control_size = parent_control.size
            
            # Clamp position to stay within parent bounds
            parent_control.global_position.x = clamp(
                parent_control.global_position.x,
                parent_rect.position.x,
                parent_rect.position.x + parent_rect.size.x - control_size.x
            )
            parent_control.global_position.y = clamp(
                parent_control.global_position.y,
                parent_rect.position.y,
                parent_rect.position.y + parent_rect.size.y - control_size.y
            )
            
        # Check if we need to update any highlighting as we move
        var targets_under_mouse = []
        for target in valid_drop_targets:
            if is_position_over_node(mouse_pos, target.node):
                targets_under_mouse.append(target)
        
        # If we're over a valid target, highlight it
        if not targets_under_mouse.is_empty():
            for target in targets_under_mouse:
                if target.node.has_method("set_highlight") and is_valid_drop(parent_control, target):
                    target.node.set_highlight(true)
        
        # Check if mouse button is released outside our control
        if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and is_dragging:
            end_drag()

func get_drop_target_at_position(position: Vector2):
    for target in valid_drop_targets:
        var node = target.node
        if is_position_over_node(position, node):
            return target
    return null

func is_position_over_node(position: Vector2, node: Node) -> bool:
    # Handle Area2D nodes with collision detection
    if node is Area2D:
        return _check_area2d_collision(position, node)
    # Handle Control nodes with rect bounds
    elif node is Control:
        return is_position_over_control(position, node)
    else:
        if debug_mode:
            Log.pr("[DragDrop] Unsupported drop target type: ", node.get_class())
        return false

func _check_area2d_collision(position: Vector2, area: Area2D) -> bool:
    # Use physics collision detection for Area2D
    var space_state = area.get_world_2d().direct_space_state
    var query = PhysicsPointQueryParameters2D.new()
    query.position = position
    query.collision_mask = area.collision_mask
    
    var results = space_state.intersect_point(query, 1)
    
    # Check if any collision shape belongs to our target area
    for result in results:
        if result.collider == area:
            if debug_mode:
                Log.pr("[DragDrop] Area2D collision detected with: ", area.name)
            return true
    
    return false

func is_position_over_control(position: Vector2, control: Control) -> bool:
    # Convert global position to control's local space
    var local_pos = control.get_global_transform_with_canvas().affine_inverse() * position
    
    # Check if point is within control bounds
    var rect = Rect2(Vector2.ZERO, control.size)
    return rect.has_point(local_pos)

func is_valid_drop(draggable, drop_target) -> bool:
    # Check if draggable type matches accepted types
    if drop_target.valid_types.size() == 0:
        # No type restrictions
        return true
        
    # Check if draggable has a method to get its type
    if draggable.has_method("get_card_type"):
        var type = draggable.get_card_type()
        return type in drop_target.valid_types
        
    return false

func highlight_valid_targets(highlight: bool):
    if not parent_control:
        return
        
    var draggable_type = ""
    if parent_control.has_method("get_card_type"):
        draggable_type = parent_control.get_card_type()
    elif parent_control.has_method("get_type"):
        draggable_type = parent_control.get_type()
    
    # Update highlights on drop targets
    for target in valid_drop_targets:
        var is_valid = target.valid_types.size() == 0 or draggable_type in target.valid_types
        
        # Set highlight if target has the method
        if target.node.has_method("set_highlight"):
            target.node.set_highlight(highlight and is_valid)

# Helper methods to control dragging programmatically

func enable_dragging():
    """Enable drag functionality"""
    enabled = true

func disable_dragging():
    """Disable drag functionality"""
    enabled = false
    
    # If currently dragging, end it
    if is_dragging:
        end_drag()

func force_end_drag():
    """Force end the current drag operation"""
    if is_dragging:
        end_drag()

func reset_to_original_position():
    """Reset the control to its original position"""
    if parent_control and original_position != Vector2.ZERO:
        parent_control.global_position = original_position

func get_draggable_type() -> String:
    """Get the draggable type of the parent control"""
    if parent_control:
        if parent_control.has_method("get_card_type"):
            return parent_control.get_card_type()
        elif parent_control.has_method("get_type"):
            return parent_control.get_type()
    return ""

func is_currently_dragging() -> bool:
    """Check if currently dragging"""
    return is_dragging

# Static helper method to quickly add drag-drop functionality to a control
static func add_to_control(control: Control) -> DragDrop:
    """Add drag-drop functionality to a control and return the component"""
    # Check if control already has a DragDrop component
    for child in control.get_children():
        if child is DragDrop:
            return child
    
    # Create and add new DragDrop component
    var drag_drop = DragDrop.new()
    control.add_child(drag_drop)
    return drag_drop
