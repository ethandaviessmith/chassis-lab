extends Control
class_name BuildView

signal combat_requested()

# References to managers
var game_manager
var deck_manager

# UI elements
@export var energy_label: Label
@export var heat_label: Label
@export var end_phase_button: Button

# Card container
@export var hand_container: Container
var hand_spacing = 120
var cards_in_hand = []

# Chassis slots
@export var head_slot: Control
@export var core_slot: Control
@export var arm_left_slot: Control
@export var arm_right_slot: Control
@export var legs_slot: Control

# Exported card scene
@export var card_scene: PackedScene

# Dictionary to map slot names to controls
var chassis_slots_map = {}

# Dictionary to track attached parts
var attached_parts = {}

# Called when the node enters the scene tree for the first time
func _ready():
    # Get manager references
    game_manager = get_node("/root/GameManager")
    deck_manager = get_node("/root/DeckManager") if has_node("/root/DeckManager") else null
    
    # Setup UI elements and slots
    setup_ui()
    
    # Initialize the build phase
    start_build_phase()

# Set up the UI elements and map the chassis slots
func setup_ui():
    # Initialize the chassis slot map
    chassis_slots_map = {
        "head": head_slot,
        "core": core_slot,
        "arm_left": arm_left_slot,
        "arm_right": arm_right_slot,
        "legs": legs_slot
    }
    
    # Connect button if needed
    if end_phase_button and not end_phase_button.pressed.is_connected(Callable(self, "_on_end_phase_button_pressed")):
        end_phase_button.pressed.connect(Callable(self, "_on_end_phase_button_pressed"))
    
    # Initialize UI labels with default values
    if energy_label:
        energy_label.text = "Energy: 0/0"
    
    if heat_label:
        heat_label.text = "Heat: 0/0"

# Initialize the build phase
func start_build_phase():
    # Draw initial hand
    if deck_manager:
        draw_starting_hand()
    else:
        # Fallback if DeckManager not available - create test cards
        create_test_cards()
    
    # Update UI
    update_ui()
    
    # Draw chassis slots
    draw_chassis_slots()

# Draw the initial hand of cards
func draw_starting_hand():
    # Reset existing cards
    for card in cards_in_hand:
        card.queue_free()
    cards_in_hand.clear()
    
    # Draw new cards
    var hand = deck_manager.draw_hand()
    for i in range(hand.size()):
        create_card_sprite(hand[i], i)

# Create test cards when no DeckManager available
func create_test_cards():
    # Reset existing cards
    for card in cards_in_hand:
        card.queue_free()
    cards_in_hand.clear()
    
    # Create sample cards
    var sample_cards = [
        {"name": "Scope Visor", "type": "Head", "cost": 1, "heat": 0, "durability": 3},
        {"name": "Fusion Core", "type": "Core", "cost": 2, "heat": 1, "durability": 5},
        {"name": "Rail Arm", "type": "Arm", "cost": 2, "heat": 1, "durability": 3},
        {"name": "Saw Arm", "type": "Arm", "cost": 1, "heat": 1, "durability": 4},
        {"name": "Tracked Legs", "type": "Legs", "cost": 1, "heat": 0, "durability": 4}
    ]
    
    for i in range(sample_cards.size()):
        create_card_sprite(sample_cards[i], i)

# Create a visual representation of a card using Card.tscn
func create_card_sprite(card_data, index):
    # Create a simpler fallback card if loading the scene fails
    var card
    
    # Use the exported card scene or try to load it if not set
    var scene_to_use = card_scene if card_scene != null else load("res://scenes/ui/Card.tscn")
    
    if scene_to_use:
        card = scene_to_use.instantiate()
        
        # If we have a hand container, let it handle positioning
        if hand_container:
            # Add to container which will handle positioning
            hand_container.add_child(card)
        else:
            # Fallback positioning if no container
            var center_x = 400
            var center_y = 500
            card.position = Vector2(center_x + (index - cards_in_hand.size()/2.0) * hand_spacing, center_y)
            # Add to scene if not using container
            add_child(card)
        
        # Ensure the card's internal nodes are ready
        if Engine.is_editor_hint() == false:
            await get_tree().process_frame
        
        # Prepare the card data properly
        var prepared_data = card_data.duplicate()
        
        # Add required fields if missing
        if not "effects" in prepared_data:
            prepared_data["effects"] = [{"description": "Basic effect"}]
        
        if not "description" in prepared_data:
            prepared_data["description"] = ""
            
        if not "rarity" in prepared_data:
            prepared_data["rarity"] = "Common"
            
        if not "image" in prepared_data:
            prepared_data["image"] = ""
        
        # Connect card signals first
        if card.has_signal("card_dragged"):
            # Disconnect previous connection to avoid duplicates
            if card.card_dragged.is_connected(func(dragged_card): _handle_card_drag(dragged_card)):
                card.card_dragged.disconnect(func(dragged_card): _handle_card_drag(dragged_card))
            card.card_dragged.connect(func(dragged_card): _handle_card_drag(dragged_card))
                
        if card.has_signal("card_dropped"):
            # Disconnect previous connection to avoid duplicates
            if card.card_dropped.is_connected(func(dropped_card, drop_pos): _handle_card_drop(dropped_card, drop_pos)):
                card.card_dropped.disconnect(func(dropped_card, drop_pos): _handle_card_drop(dropped_card, drop_pos))
            card.card_dropped.connect(func(dropped_card, drop_pos): _handle_card_drop(dropped_card, drop_pos))
        
        # Add to tracking array - do this before initialize to ensure it's tracked properly
        cards_in_hand.append(card)
        
        # Make sure GUI input is connected for drag/drop
        if card.has_method("_on_gui_input"):
            if not card.gui_input.is_connected(card._on_gui_input):
                card.gui_input.connect(card._on_gui_input)
        
        # Initialize the card data
        if card.has_method("initialize"):
            card.initialize(prepared_data)
        else:
            print("ERROR: Card scene is missing initialize method!")
    else:
        # Fallback to a simple card if scene loading fails
        print("ERROR: Failed to load Card scene, using fallback")
        card = ColorRect.new()
        card.color = get_card_color(card_data.type)
        card.size = Vector2(100, 150)
        
        # Position the card based on index
        var center_x = 400
        var center_y = 500
        card.position = Vector2(center_x + (index - cards_in_hand.size()/2.0) * hand_spacing, center_y)
        
        card.set_meta("card_data", card_data)
        
        # Add card name label
        var name_label = Label.new()
        name_label.text = card_data.name
        name_label.position = Vector2(10, 10)
        card.add_child(name_label)
        
        # Setup card for dragging
        setup_card_dragging(card)
        
        # Add to scene and tracking array
        add_child(card)
        cards_in_hand.append(card)
    
    # Connect card signals if they weren't already connected in the main creation block
    if card.has_signal("card_dragged") and not card.card_dragged.is_connected(func(dragged_card): _handle_card_drag(dragged_card)):
        card.card_dragged.connect(func(dragged_card): _handle_card_drag(dragged_card))
    if card.has_signal("card_dropped") and not card.card_dropped.is_connected(func(dropped_card, drop_pos): _handle_card_drop(dropped_card, drop_pos)):
        card.card_dropped.connect(func(dropped_card, drop_pos): _handle_card_drop(dropped_card, drop_pos))
        
    # Note: Card is already added to cards_in_hand above

# Get a color based on card type
func get_card_color(type):
    match type:
        "Head": return Color(0.2, 0.6, 1.0, 0.7)  # Blue
        "Core": return Color(1.0, 0.8, 0.2, 0.7)  # Yellow
        "Arm": return Color(1.0, 0.3, 0.3, 0.7)   # Red
        "Legs": return Color(0.3, 0.8, 0.3, 0.7)   # Green
        "Utility": return Color(0.8, 0.4, 0.8, 0.7) # Purple
        _: return Color(0.7, 0.7, 0.7, 0.7)       # Gray

# Setup card dragging functionality (for legacy ColorRect cards)
func setup_card_dragging(card):
    # Add metadata to handle dragging
    card.set_meta("dragging", false)
    card.set_meta("original_position", card.position)
    
    # Note: This function is only used for legacy cards created as ColorRect
    # For Card.tscn instances, the dragging is handled by the Card script

# Set up visual indicators for chassis slots
func draw_chassis_slots():
    # We don't need to create slots since they're now exported controls
    # Just add some visual indicators if needed
    for slot_name in chassis_slots_map:
        var slot = chassis_slots_map[slot_name]
        if slot:
            # We could add additional visual indicators here if needed
            # For example, highlight available slots based on cards in hand
            pass

# Update UI elements
func update_ui():
    if deck_manager:
        energy_label.text = "Energy: " + str(deck_manager.current_energy) + "/" + str(deck_manager.max_energy)
        heat_label.text = "Heat: " + str(deck_manager.current_heat) + "/" + str(deck_manager.max_heat)
    else:
        energy_label.text = "Energy: 10/10"
        heat_label.text = "Heat: 0/10"

# Handle button press to end the build phase
func _on_end_phase_button_pressed():
    emit_signal("combat_requested")

# Process input events for card dragging
func _input(event):
    # Check for mouse button press/release
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                # Check for card under cursor
                _check_card_press(event.position)
            else:
                # Release any dragged card
                _release_dragged_card(event.position)
    
    # Check for mouse movement while dragging
    elif event is InputEventMouseMotion:
        # Move any dragged card
        _update_dragged_card(event.position)

# Check if a card was clicked
func _check_card_press(click_pos):
    # In a full implementation, find the card under the cursor
    # and mark it as being dragged
    for card in cards_in_hand:
        if _is_position_over_card(click_pos, card):
            card.set_meta("dragging", true)
            card.z_index = 100  # Bring to front

# Update position of dragged card
func _update_dragged_card(mouse_pos):
    for card in cards_in_hand:
        if card.get_meta("dragging"):
            card.position = mouse_pos - Vector2(50, 75)  # Center the card on cursor

# Release a dragged card
func _release_dragged_card(drop_pos):
    for card in cards_in_hand:
        if card.get_meta("dragging"):
            # Check if dropped on a valid chassis slot
            var slot_name = _get_slot_at_position(drop_pos)
            
            if slot_name != "":
                _attach_part_to_slot(card, slot_name)
            else:
                # Return to original position
                card.position = card.original_position
            
            card.set_meta("dragging", false)
            card.z_index = 0  # Reset z-index

# Check if position is over a card
func _is_position_over_card(mouse_pos, card):
    return (mouse_pos.x >= card.position.x and 
            mouse_pos.x <= card.position.x + card.size.x and
            mouse_pos.y >= card.position.y and
            mouse_pos.y <= card.position.y + card.size.y)

# Get slot name at position, or empty string if none
func _get_slot_at_position(check_pos):
    for slot_name in chassis_slots_map:
        var slot = chassis_slots_map[slot_name]
        if slot:
            var slot_rect = Rect2(slot.global_position, slot.size)
            if slot_rect.has_point(check_pos):
                return slot_name
    return ""

# Handle card drag event
func _handle_card_drag(card):
    # Highlight valid drop targets for the dragged card
    var card_data = card.data if card is Card else card.get_meta("card_data")
    if card_data:
        for slot_name in chassis_slots_map:
            var slot = chassis_slots_map[slot_name]
            if slot and slot is ChassisSlot:
                # Use the slot's is_compatible_with_card method if available
                var is_compatible = false
                
                if slot.has_method("is_compatible_with_card"):
                    is_compatible = slot.is_compatible_with_card(card_data)
                else:
                    # Fallback compatibility check if slot doesn't have the method
                    match card_data.type:
                        "Head":
                            is_compatible = (slot_name == "head")
                        "Core":
                            is_compatible = (slot_name == "core")
                        "Arm":
                            is_compatible = (slot_name == "arm_left" or slot_name == "arm_right")
                        "Legs":
                            is_compatible = (slot_name == "legs")
                
                # Highlight the slot if compatible
                if is_compatible:
                    slot.highlight(true)  # Pass true for valid highlight
                else:
                    slot.highlight(false)  # Pass false for invalid highlight
                
                # Also highlight the card itself to indicate compatibility
                if card is Card and card.has_method("set_highlight"):
                    card.set_highlight(true, is_compatible)
            elif slot:
                # For non-ChassisSlot controls, use a visual effect
                if slot.has_method("set_self_modulate"):
                    slot.set_self_modulate(Color(1.0, 1.0, 0.5, 0.7))  # Yellow tint

# Handle card drop event
func _handle_card_drop(card, drop_pos):
    # Reset all slot highlights
    _reset_slot_highlights()
    
    # Reset card highlight
    if card is Card and card.has_method("set_highlight"):
        card.set_highlight(false)
    
    # Ensure card is marked as not being dragged
    if card is Card:
        card.is_being_dragged = false
    elif card.has_meta("dragging"):
        card.set_meta("dragging", false)
    
    # Check if dropped on a valid chassis slot
    var slot_name = _get_slot_at_position(drop_pos)
    
    if slot_name != "":
        _attach_part_to_slot(card, slot_name)
    else:
        # Debug drop position
        print("Card dropped at: ", drop_pos, " - not on a slot")
        
        # Return to original position
        if card.has_method("reset_position"):
            card.reset_position()
        
        # Make sure the card is properly tracked in hand
        if card is Card and not cards_in_hand.has(card):
            cards_in_hand.append(card)
            print("Added card back to hand tracking")
            
# Reset all slot highlights
func _reset_slot_highlights():
    for slot_name in chassis_slots_map:
        var slot = chassis_slots_map[slot_name]
        if slot and slot is ChassisSlot:
            slot.unhighlight()
        elif slot and slot.has_method("set_self_modulate"):
            slot.set_self_modulate(Color(1, 1, 1, 1))  # Reset tint

# Attach a card as a part to a chassis slot
func _attach_part_to_slot(card, slot_name):
    var card_data = card.data if card is Card else card.get_meta("card_data")
    
    # Check if card type matches slot type
    var valid_slot = false
    match card_data.type:
        "Head":
            valid_slot = (slot_name == "head")
        "Core":
            valid_slot = (slot_name == "core")
        "Arm":
            valid_slot = (slot_name == "arm_left" or slot_name == "arm_right")
        "Legs":
            valid_slot = (slot_name == "legs")
    if valid_slot:
        # Remove previous part in this slot if any
        if attached_parts.has(slot_name) and is_instance_valid(attached_parts[slot_name]):
            attached_parts[slot_name].queue_free()
        
        # Get the target slot
        var target_slot = chassis_slots_map[slot_name]
        
        # Move card to slot position (center in slot)
        if target_slot:
            # Calculate center position
            var center_pos = target_slot.global_position + (target_slot.size / 2.0)
            # Adjust for card size (assuming card.size exists or is 100x150)
            var card_size = card.size if "size" in card else Vector2(100, 150)
            card.global_position = center_pos - (card_size / 2.0)
            
            # Make sure the card stays visible when attached
            if card is Control:
                card.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Prevent card from capturing mouse events
            
            # If the slot is a ChassisSlot, tell it that it has a part now
            if target_slot is ChassisSlot:
                target_slot.set_part(card)
        
        # Store as attached part
        attached_parts[slot_name] = card
        
        # Remove from hand array
        cards_in_hand.erase(card)
        
        # Apply part effects (would call to Robot/GameManager in full implementation)
        print("Attached " + card_data.name + " to " + slot_name)
    else:
        # Return to original position
        if card is Card and card.has_method("reset_position"):
            card.reset_position()
        elif card.has_meta("original_position"):
            card.position = card.get_meta("original_position")
