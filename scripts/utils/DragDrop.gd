extends Node2D
class_name DragDrop

signal drag_started(draggable)
signal drag_ended(draggable)
signal drop_attempted(draggable, target)
signal drop_succeeded(draggable, target)
signal drop_failed(draggable)

var current_draggable = null
var drag_offset = Vector2.ZERO
var original_position = Vector2.ZERO
var valid_drop_targets = []

func register_draggable(node: Node):
	# Set up input for draggable object
	if not node.is_connected("gui_input", _on_draggable_input.bind(node)):
		node.gui_input.connect(_on_draggable_input.bind(node))

func register_drop_target(node: Node, valid_types: Array = []):
	# Store valid drop target with acceptable types
	valid_drop_targets.append({
		"node": node,
		"valid_types": valid_types
	})

func _on_draggable_input(event, draggable):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Start drag
			start_drag(draggable)
		elif current_draggable == draggable:
			# End drag
			end_drag()

func start_drag(draggable):
	if current_draggable:
		# Already dragging something
		return
	
	current_draggable = draggable
	original_position = draggable.global_position
	drag_offset = draggable.get_local_mouse_position()
	
	# Bring to front
	var parent = draggable.get_parent()
	parent.move_child(draggable, parent.get_child_count() - 1)
	
	emit_signal("drag_started", draggable)
	
	# Update drop targets to show valid ones
	highlight_valid_targets(true)

func end_drag():
	if not current_draggable:
		return
	
	# Find drop target under mouse
	var drop_target = get_drop_target_at_position(get_global_mouse_position())
	
	if drop_target:
		# Try to drop on target
		emit_signal("drop_attempted", current_draggable, drop_target.node)
		
		# Check if drop is valid
		if is_valid_drop(current_draggable, drop_target):
			emit_signal("drop_succeeded", current_draggable, drop_target.node)
		else:
			# Invalid drop
			current_draggable.global_position = original_position
			emit_signal("drop_failed", current_draggable)
	else:
		# No target found, return to original position
		current_draggable.global_position = original_position
		emit_signal("drop_failed", current_draggable)
	
	# Update drop targets to hide highlights
	highlight_valid_targets(false)
	
	# Reset state
	emit_signal("drag_ended", current_draggable)
	current_draggable = null

func _process(_delta):
	if current_draggable:
		# Move draggable with mouse
		current_draggable.global_position = get_global_mouse_position() - drag_offset

func get_drop_target_at_position(position: Vector2):
	for target in valid_drop_targets:
		var node = target.node
		if is_position_over_control(position, node):
			return target
	return null

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
	if not current_draggable:
		return
		
	var draggable_type = ""
	if current_draggable.has_method("get_card_type"):
		draggable_type = current_draggable.get_card_type()
	
	# Update highlights on drop targets
	for target in valid_drop_targets:
		var is_valid = target.valid_types.size() == 0 or draggable_type in target.valid_types
		
		# Set highlight if target has the method
		if target.node.has_method("set_highlight"):
			target.node.set_highlight(highlight and is_valid)
