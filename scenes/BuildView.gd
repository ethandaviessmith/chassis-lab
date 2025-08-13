extends Control
class_name BuildView

signal combat_requested()
signal chassis_updated(attached_parts)

# References to managers - set these in the editor
@export var game_manager: GameManager
@export var deck_manager: DeckManager
@export var turn_manager: TurnManager

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
@export var scrapper_slot: Control
@export var utility_slot: Control

# Exported card scene
@export var card_scene: PackedScene

# Dictionary to map slot names to controls
var chassis_slots_map = {}

# Dictionary to track attached parts
var attached_parts = {}

# Called when the node enters the scene tree for the first time
func _ready():
    # Add diagnostic logs
    Log.pr("[BuildView] Initializing...")
    
    # Log about drag-drop controls
    _log_drag_drop_components()

    # Get manager references
    Log.pr("[BuildView] GameManager: ", "Set" if game_manager else "Not set")
    Log.pr("[BuildView] DeckManager: ", "Set" if deck_manager else "Not set")
    Log.pr("[BuildView] TurnManager: ", "Set" if turn_manager else "Not set")
    
    # Connect TurnManager to energy label if both exist
    if turn_manager and energy_label:
        turn_manager.set_energy_label(energy_label)
        turn_manager.energy_changed.connect(_on_energy_changed)
    
    # Setup UI elements and slots
    setup_ui()
    
    # Initialize the build phase
    start_build_phase()
    
    Log.pr("[BuildView] Initialization complete")

# Helper function to log info about drag-drop components
func _log_drag_drop_components():
    Log.pr("[BuildView] Checking for DragDrop components...")
    
    # Check direct children first
    for child in get_children():
        if child is Control:
            Log.pr("[BuildView] Found Control child: " + child.name)
            
            # Check if this control has a DragDrop component
            var has_drag_drop = false
            for component in child.get_children():
                if component is DragDrop:
                    has_drag_drop = true
                    Log.pr("[BuildView]   - Has DragDrop component")
                    Log.pr("[BuildView]     - Enabled: " + str(component.enabled))
                    Log.pr("[BuildView]     - Drag Handle: " + str(component.drag_handle))
                    
            if not has_drag_drop:
                Log.pr("[BuildView]   - No DragDrop component found")
        
            # Log the control's mouse filter
            Log.pr("[BuildView]   - Mouse filter: " + _get_mouse_filter_name(child.mouse_filter))
            
            # Log any ColorRect children
            for subchild in child.get_children():
                if subchild is ColorRect:
                    Log.pr("[BuildView]   - Has ColorRect child: " + subchild.name)
                    Log.pr("[BuildView]     - Mouse filter: " + _get_mouse_filter_name(subchild.mouse_filter))

# Helper to convert mouse_filter enum to string for debugging
func _get_mouse_filter_name(filter_value: int) -> String:
    match filter_value:
        Control.MOUSE_FILTER_STOP: return "MOUSE_FILTER_STOP"
        Control.MOUSE_FILTER_PASS: return "MOUSE_FILTER_PASS"
        Control.MOUSE_FILTER_IGNORE: return "MOUSE_FILTER_IGNORE"
        _: return "UNKNOWN (" + str(filter_value) + ")"
        
# Set up the UI elements and map the chassis slots
func setup_ui():
    # Initialize the chassis slot map
    chassis_slots_map = {
        "scrapper": scrapper_slot,
        "head": head_slot,
        "core": core_slot,
        "arm_left": arm_left_slot,
        "arm_right": arm_right_slot,
        "legs": legs_slot,
        "utility": utility_slot
    }
    
    # Debug all slots
    for slot_name in chassis_slots_map:
        var slot = chassis_slots_map[slot_name]
        if slot:
            # Print detailed debug info for each slot
            print("SLOT DEBUG - ", slot_name)
            print("  Global pos: ", slot.global_position)
            if slot.has_method("get_global_rect"):
                print("  Global rect: ", slot.get_global_rect())
            print("  Position: ", slot.position)
            print("  Size: ", slot.size)
            var parent = slot.get_parent()
            print("  Parent: ", parent.name if parent else "none")
            print("  Mouse filter: ", slot.mouse_filter)
    
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
    # Initialize turn manager for energy
    if turn_manager:
        turn_manager.initialize()
        Log.pr("[BuildView] TurnManager initialized")
    
    # Draw initial hand
    if deck_manager:
        draw_starting_hand()
    else:
        # Fallback if DeckManager not available - create test cards
        Log.pr("[BuildView] No DeckManager, using test cards")
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
    Log.pr("[BuildView] Drawn hand size: ", hand.size())
    
    # If hand is empty, try to reload the deck
    if hand.size() == 0:
        Log.pr("[BuildView] Hand is empty, trying to reload deck...")
        if deck_manager.has_method("reload_deck"):
            deck_manager.reload_deck()
            hand = deck_manager.draw_hand()
            Log.pr("[BuildView] After reload, hand size: ", hand.size())
    
    # If still empty, fall back to test cards
    if hand.size() == 0:
        Log.pr("[BuildView] Still no cards, using fallback test cards")
        create_test_cards()
        return
    
    # Create card sprites for each card in hand
    for i in range(hand.size()):
        create_card_sprite(hand[i], i)
    Log.pr("[BuildView] Created ", hand.size(), " card sprites")

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
        {"name": "Tracked Legs", "type": "Legs", "cost": 1, "heat": 0, "durability": 4},
        {"name": "Salvage Claw", "type": "Scrapper", "cost": 1, "heat": 0, "durability": 2, "effects": [{"description": "Gain materials from destroyed enemies"}]},
        {"name": "Shield Generator", "type": "Utility", "cost": 2, "heat": 1, "durability": 3, "effects": [{"description": "+2 armor at start of combat"}]}
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
        
        # Add to tracking array - do this before initialize to ensure it's tracked properly
        cards_in_hand.append(card)
        
        # Initialize the card data
        if card.has_method("initialize"):
            card.initialize(prepared_data)
            
            # Set initial card state to hand
            if card.has_method("set_card_state"):
                card.set_card_state(Card.State.HAND)
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
    if card.has_signal("drop_attempted") and not card.drop_attempted.is_connected(func(dropped_card, drop_pos, target): _handle_card_drop(dropped_card, drop_pos, target)):
        card.drop_attempted.connect(func(dropped_card, drop_pos, target): _handle_card_drop(dropped_card, drop_pos, target))
    
    # Connect to DragDrop component signals if available
    if card.drag_drop:
        # Register all chassis slots as valid drop targets
        for slot_name in chassis_slots_map:
            var slot = chassis_slots_map[slot_name]
            var valid_types = []
            if slot and slot.has_method("get_valid_part_types"):
                valid_types = slot.get_valid_part_types()
            card.drag_drop.register_drop_target(slot, valid_types)
        
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
    if turn_manager:
        # TurnManager now handles energy display directly via energy_label
        if heat_label:
            heat_label.text = "Heat: 0/10"  # Placeholder for now
    else:
        if energy_label:
            energy_label.text = "Energy: 4/4"
        if heat_label:
            heat_label.text = "Heat: 0/10"

# Handle energy changes from TurnManager
func _on_energy_changed(current: int, maximum: int):
    # TurnManager updates the label directly, but we can do additional UI updates here
    Log.pr("[BuildView] Energy changed: " + str(current) + "/" + str(maximum))

# Handle button press to end the build phase
func _on_end_phase_button_pressed():
    # Build robot and start combat through TurnManager
    if turn_manager and turn_manager.has_method("build_robot_and_start_combat"):
        turn_manager.build_robot_and_start_combat(self, game_manager)
    else:
        # Fallback to old behavior
        emit_signal("combat_requested")

# Process input events for card dragging
# Input handling has been moved to the DragDrop component
# This function is no longer needed
func _input(_event):
    pass

# Check if a card was clicked
# This function is no longer needed - card press detection is handled by DragDrop component
func _check_card_press(_click_pos):
    pass

# Update position of dragged card
# This function is no longer needed - card movement is handled by DragDrop component
func _update_dragged_card(_mouse_pos):
    pass

# This function is no longer needed - card release is handled by DragDrop component
func _release_dragged_card(_drop_pos):
    pass

# Check if position is over a card
func _is_position_over_card(mouse_pos, card):
    # Use global_position if available, position otherwise
    var pos = card.global_position if card.has_method("get_global_position") else card.position
    var card_size = card.size
    
    var is_over = (mouse_pos.x >= pos.x and 
                  mouse_pos.x <= pos.x + card_size.x and
                  mouse_pos.y >= pos.y and
                  mouse_pos.y <= pos.y + card_size.y)
    
    Log.pr("[BuildView] Position check: " +
           "mouse=" + str(mouse_pos) +
           ", card pos=" + str(pos) +
           ", card size=" + str(card_size) +
           ", result=" + str(is_over))
           
    return is_over

# Get slot name at position, or empty string if none
func _get_slot_at_position(check_pos):
    # Debug the incoming position
    print("GET SLOT - Check position: ", check_pos)
    
    # Direct hit test first - get viewport rect to debug screen coordinates
    var viewport_rect = get_viewport_rect()
    print("GET SLOT - Viewport rect: ", viewport_rect)
    
    # For each slot, print detailed coordinates and test direct hits
    for slot_name in chassis_slots_map:
        var slot = chassis_slots_map[slot_name]
        if slot:
            # Log everything we know about the slot's position
            print("GET SLOT - Slot: ", slot_name)
            print("  Global pos: ", slot.global_position)
            print("  Rect pos: ", slot.get_global_rect().position)
            print("  Size: ", slot.size)
            print("  Parent: ", slot.get_parent().name if slot.get_parent() else "none")
            
            # Try different approaches to get the slot rect
            var slot_rect1 = Rect2(slot.global_position, slot.size)
            var slot_rect2 = slot.get_global_rect()
            
            # Debug both approaches
            print("  Approach 1 rect: ", slot_rect1)
            print("  Approach 2 rect: ", slot_rect2)
            print("  Point inside rect1: ", slot_rect1.has_point(check_pos))
            print("  Point inside rect2: ", slot_rect2.has_point(check_pos))
            
            # Use both approaches - if either one hits, count it as a match
            if slot_rect1.has_point(check_pos) or slot_rect2.has_point(check_pos):
                print("  DIRECT HIT FOUND")
                return slot_name
                
    # No direct hit - try proximity detection
    var closest_slot = ""
    var closest_distance = 1000000  # Large initial value
    
    for slot_name in chassis_slots_map:
        var slot = chassis_slots_map[slot_name]
        if slot:
            var slot_center = slot.global_position + (slot.size / 2)
            
            # Calculate distance to slot center
            var distance = slot_center.distance_to(check_pos)
            print("GET SLOT - Distance to ", slot_name, " center: ", distance)
            
            # Keep track of closest slot
            if distance < closest_distance and distance < 150:  # Within reasonable range
                closest_distance = distance
                closest_slot = slot_name
    
    # If we found a reasonably close slot and no exact match
    if closest_slot != "" and closest_distance < 100:
        print("Using closest slot: ", closest_slot, " at distance: ", closest_distance)
        return closest_slot
        
    # Direct manual detection attempt as last resort
    # We know the exact positions and sizes of slots, so let's try absolute positioning
    
    # Check which quadrant of the screen we're in
    var viewport_size = get_viewport_rect().size
    
    # Top area is likely head
    if check_pos.y < viewport_size.y * 0.3:
        print("  QUADRANT HIT - Top area (head)")
        return "head"
    
    # Center area is likely core
    if check_pos.y < viewport_size.y * 0.6 and check_pos.y > viewport_size.y * 0.3:
        if check_pos.x > viewport_size.x * 0.3 and check_pos.x < viewport_size.x * 0.7:
            print("  QUADRANT HIT - Center area (core)")
            return "core"
    
    # Left side is left arm
    if check_pos.x < viewport_size.x * 0.4 and check_pos.y > viewport_size.y * 0.3:
        print("  QUADRANT HIT - Left side (arm_left)")
        return "arm_left"
    
    # Right side is right arm
    if check_pos.x > viewport_size.x * 0.6 and check_pos.y > viewport_size.y * 0.3:
        print("  QUADRANT HIT - Right side (arm_right)")
        return "arm_right"
    
    # Bottom center is legs
    if check_pos.y > viewport_size.y * 0.7 and check_pos.x > viewport_size.x * 0.3 and check_pos.x < viewport_size.x * 0.7:
        print("  QUADRANT HIT - Bottom area (legs)")
        return "legs"
        
    print("No slot found at position after all attempts")
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
                        "Scrapper":
                            is_compatible = (slot_name == "scrapper")
                        "Utility":
                            is_compatible = (slot_name == "utility")
                
                # Highlight the slot if compatible
                if is_compatible:
                    slot.highlight(true)  # Pass true for valid highlight
                else:
                    slot.highlight(false)  # Pass false for invalid highlight
                
                # Since the DragDrop component handles highlighting the card,
# We no longer need to handle it here directly

# Handle card drop event
func _handle_card_drop(card, drop_pos, target = null):
    print("BUILD VIEW - Card dropped event received - card: ", card, " at pos: ", drop_pos)
    
    # Reset all slot highlights
    _reset_slot_highlights()
    
    # Reset card highlight
    if card is Card and card.has_method("set_highlight"):
        card.set_highlight(false)
    
    # Check if dropped on HandContainer or its Area2D
    if target != null:
        # Check if target is HandContainer or its Area2D
        if target is HandContainer or (target is Area2D and target.get_parent() is HandContainer):
            print("Card dropped on HandContainer area - returning to hand")
            _return_card_to_hand(card)
            return
        
        # Check if it's one of our chassis slots
        for slot_name in chassis_slots_map:
            if chassis_slots_map[slot_name] == target:
                print("Direct slot target found: ", slot_name)
                if _attach_part_to_slot(card, slot_name):
                    return
    
    # Try several approaches to find the slot
    var slot_name = ""
    
    # First try exact position check
    slot_name = _get_slot_at_position(drop_pos)
    print("Exact position check result: ", slot_name)
    
    # If that didn't work, try the card's global position
    if slot_name == "" and card is Card:
        var card_center = card.global_position + (card.size / 2)
        slot_name = _get_slot_at_position(card_center)
        print("Card center position check result: ", slot_name)
        
    # If still nothing, try a larger area around the drop position
    if slot_name == "":
        # Check a larger radius around drop position
        for radius in [20, 50, 100]:
            for offset_x in [-radius, 0, radius]:
                for offset_y in [-radius, 0, radius]:
                    var check_pos = drop_pos + Vector2(offset_x, offset_y)
                    var result = _get_slot_at_position(check_pos)
                    if result != "":
                        slot_name = result
                        print("Found slot with expanded search: ", slot_name, " at offset: ", Vector2(offset_x, offset_y))
                        break
                if slot_name != "":
                    break
            if slot_name != "":
                break
    
    if slot_name != "":
        # Attach to slot (method handles replacing existing parts)
        _attach_part_to_slot(card, slot_name)
    else:
        # Debug drop position
        print("Card dropped at: ", drop_pos, " - not on a slot")
        
        # Check if this card was attached to a chassis slot
        var was_attached = false
        var previous_slot = ""
        
        # Find if this card was in a slot before
        for existing_slot in attached_parts:
            if attached_parts[existing_slot] == card:
                was_attached = true
                previous_slot = existing_slot
                break
        
        # If card was previously attached, remove from that slot
        if was_attached:
            print("Removing card from " + previous_slot + " and returning to hand")
            # Remove from previous slot tracking
            attached_parts.erase(previous_slot)
            
            # Clear the previous slot's part reference
            var prev_slot_control = chassis_slots_map[previous_slot]
            if prev_slot_control and prev_slot_control is ChassisSlot:
                prev_slot_control.clear_part()
            
            # Remove from slot parent and add back to hand
            if card.get_parent() != hand_container:
                # Capture the card's current global position before reparenting
                var card_global_pos = card.global_position
                
                if card.get_parent():
                    card.get_parent().remove_child(card)
                if hand_container:
                    hand_container.add_child(card)
                    
                    # Restore the card's global position after reparenting
                    card.global_position = card_global_pos
            
            # Remove the attached flag
            if card.has_meta("attached_to_chassis"):
                card.remove_meta("attached_to_chassis")
            
            # Reset card properties for hand
            card.modulate = Color(1, 1, 1, 1)  # Reset transparency
            card.mouse_filter = Control.MOUSE_FILTER_STOP
            
            # Set card state to hand (this will handle scaling automatically)
            if card.has_method("set_card_state"):
                card.set_card_state(Card.State.HAND)
        
        # Make sure the card is properly tracked in hand
        if card is Card and not cards_in_hand.has(card):
            cards_in_hand.append(card)
            print("Added card back to hand tracking")
        
        # Reposition cards in hand container
        if hand_container and hand_container.has_method("_reposition_cards"):
            hand_container._reposition_cards()
        elif card.has_method("reset_position"):
            # Fallback if no hand container repositioning
            card.reset_position()
            
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
        "Leg", "Legs":
            valid_slot = (slot_name == "legs")
        "Utility":
            valid_slot = (slot_name == "utility")
        "Scrapper":
            valid_slot = (slot_name == "scrapper")
        # todo update scrapped to accept all, not use energy cost and instead lower card durability by 1
    
    if valid_slot:
        var card_cost = card_data.get("cost", 0)
        var card_current_slot = ""
        
        # Check if this card is already attached somewhere else
        for existing_slot in attached_parts:
            if attached_parts[existing_slot] == card:
                card_current_slot = existing_slot
                break
        
        # Handle energy for card replacement/swapping
        var previous_card_cost = 0
        var existing_card_in_slot = null
        if attached_parts.has(slot_name) and is_instance_valid(attached_parts[slot_name]) and attached_parts[slot_name] != card:
            existing_card_in_slot = attached_parts[slot_name]
            if existing_card_in_slot is Card:
                previous_card_cost = existing_card_in_slot.data.get("cost", 0)
        
        # Calculate net energy change
        var energy_change = 0
        
        # For moves between slots (not new attachments), no energy cost
        if card_current_slot != "":
            energy_change = 0
            print("Moving card between slots - no energy change")
        else:
            # Calculate net energy requirement: cost of new card minus refund from old card
            energy_change = card_cost - previous_card_cost
            
            # Check if we have enough energy for the net cost
            if energy_change > 0 and turn_manager:
                if turn_manager.current_energy < energy_change:
                    print("Not enough energy to attach ", card_data.name, "! Need: ", energy_change, " net energy (", card_cost, " cost - ", previous_card_cost, " refund), Have: ", turn_manager.current_energy)
                    return false
        
        # If the card is moving from one slot to another, clean up the old slot first
        if card_current_slot != "" and card_current_slot != slot_name:
            print("Moving card from " + card_current_slot + " to " + slot_name)
            attached_parts.erase(card_current_slot)
            
            # Clear the old slot's part reference
            var old_slot_control = chassis_slots_map[card_current_slot]
            if old_slot_control and old_slot_control is ChassisSlot:
                old_slot_control.clear_part()
        
        # Handle previous part in this slot if any (different card)
        var previous_card = null
        if attached_parts.has(slot_name) and is_instance_valid(attached_parts[slot_name]) and attached_parts[slot_name] != card:
            previous_card = attached_parts[slot_name]
            
            # Only return to hand if it's a Card (not a placeholder sprite)
            if previous_card is Card:
                print("Returning previous card to hand: ", previous_card.data.name)
                
                # Remove from the chassis slot first
                var previous_slot = chassis_slots_map[slot_name]
                if previous_slot and previous_slot is ChassisSlot:
                    previous_slot.clear_part()
                
                # Capture the card's current global position before reparenting
                var card_global_pos = previous_card.global_position
                
                # Remove from current parent (the slot)
                if previous_card.get_parent():
                    previous_card.get_parent().remove_child(previous_card)
                
                # Add to hand container (use the exported hand_container)
                if hand_container:
                    hand_container.add_child(previous_card)
                    
                    # Set the card's global position to where it was before reparenting
                    previous_card.global_position = card_global_pos
                    
                    # Add back to hand tracking
                    if not cards_in_hand.has(previous_card):
                        cards_in_hand.append(previous_card)
                    
                    # Reset card properties for hand
                    previous_card.mouse_filter = Control.MOUSE_FILTER_STOP
                    previous_card.modulate = Color(1, 1, 1, 1)  # Reset transparency
                    
                    # Set card state to hand (this will handle scaling automatically)
                    if previous_card.has_method("set_card_state"):
                        previous_card.set_card_state(Card.State.HAND)
                    
                    # Remove chassis attachment flag
                    if previous_card.has_meta("attached_to_chassis"):
                        previous_card.remove_meta("attached_to_chassis")
                    
                    # Now trigger repositioning which will animate to proper hand position
                    if hand_container.has_method("_reposition_cards"):
                        hand_container._reposition_cards()
                else:
                    # If we can't return to hand, just remove it
                    previous_card.queue_free()
            else:
                # Not a proper card, just remove
                previous_card.queue_free()
        
        # Get the target slot
        var target_slot = chassis_slots_map[slot_name]
        
        # Move card to slot position (center in slot)
        if target_slot:
            if card is Card:
                # Remove the card from hand tracking first
                cards_in_hand.erase(card)
                print("BuildView: Removed card from cards_in_hand tracking")
                
                # Remove from current parent (likely hand_container)
                var old_parent = card.get_parent()
                if old_parent:
                    print("BuildView: Removing card from parent: " + old_parent.name)
                    old_parent.remove_child(card)
                
                # Add the card as a child of the slot
                print("BuildView: Adding card to slot: " + slot_name)
                target_slot.add_child(card)
                
                # Position it properly within the slot (centered)
                var slot_center_x = target_slot.size.x / 2 - card.size.x / 2
                var slot_center_y = target_slot.size.y / 2 - card.size.y / 2
                card.position = Vector2(slot_center_x, slot_center_y)
                print("BuildView: Positioned card at local position: " + str(card.position) + " within slot size: " + str(target_slot.size))
                
                # Clear any target_position that HandContainer might have set
                if card.has_method("clear_target_position") or "target_position" in card:
                    card.target_position = Vector2.ZERO
                
                # Update the DragDrop component's original position to the new slot position
                if card.drag_drop:
                    # Use global position since DragDrop works in global coordinates
                    card.drag_drop.original_position = card.global_position
                    print("BuildView: Updated DragDrop original_position to: " + str(card.drag_drop.original_position))
                
                # Clear any highlight effects
                if card.has_method("set_highlight"):
                    card.set_highlight(false)
                
                # Set card state to chassis slot (this will handle scaling automatically)
                if card.has_method("set_card_state"):
                    card.set_card_state(Card.State.CHASSIS_SLOT)
                
                # Keep the card interactive for dragging
                card.mouse_filter = Control.MOUSE_FILTER_STOP
                
                # Mark as attached to chassis
                card.set_meta("attached_to_chassis", slot_name)
                
                # Clear any target position to prevent HandContainer animation
                card.target_position = Vector2.ZERO
                
                print("Positioned card in slot: " + slot_name + " at local pos: " + str(card.position))
            else:
                # Handle non-Card objects (legacy fallback)
                var center_pos = target_slot.global_position + (target_slot.size / 2.0)
                var card_size = card.size if "size" in card else Vector2(100, 150)
                var target_pos = center_pos - (card_size / 2.0)
                card.global_position = target_pos
            
            # If the slot is a ChassisSlot, tell it that it has a part now
            if target_slot is ChassisSlot and target_slot.has_method("set_part"):
                target_slot.set_part(card)
        
        # Store as attached part
        attached_parts[slot_name] = card
        
        # Apply net energy change for new attachments or swaps (not moves between slots)
        if card_current_slot == "" and turn_manager:
            if energy_change > 0:
                # Need to spend energy
                if not turn_manager.spend_energy(energy_change):
                    # This shouldn't happen since we checked above, but safety first
                    print("Failed to spend energy for card attachment!")
                    return false
            elif energy_change < 0:
                # Gain energy (cheaper replacement)
                turn_manager.gain_energy(-energy_change)
            # If energy_change == 0, no energy transaction needed
        
        # If using a HandContainer, tell it to reposition remaining cards
        if hand_container and hand_container.has_method("_reposition_cards"):
            hand_container._reposition_cards()
        
        # Apply part effects (would call to Robot/GameManager in full implementation)
        var energy_message = ""
        if card_current_slot == "":
            if previous_card_cost > 0:
                if energy_change > 0:
                    energy_message = " (swapped for net " + str(energy_change) + " energy)"
                elif energy_change < 0:
                    energy_message = " (swapped, gained " + str(-energy_change) + " energy)"
                else:
                    energy_message = " (swapped, no energy change)"
            else:
                energy_message = " for " + str(card_cost) + " energy"
        else:
            energy_message = " (moved)"
        
        print("Attached " + card_data.name + " to " + slot_name + energy_message)
        
        # Emit signal to update robot visuals in real-time
        emit_signal("chassis_updated", attached_parts)
        
        return true
    else:
        # Not a valid slot - return to original position
        print("Invalid slot for card type: " + card_data.type + " can't go in " + slot_name)
        
        # Return the card to hand
        if card.get_parent() != hand_container:
            # Capture the card's current global position before reparenting
            var card_global_pos = card.global_position
            
            if card.get_parent():
                card.get_parent().remove_child(card)
            if hand_container:
                hand_container.add_child(card)
                
                # Restore the card's global position after reparenting
                card.global_position = card_global_pos
        
        # Reset card properties
        card.modulate = Color(1, 1, 1, 1)
        
        # Set card state to hand (this will handle scaling automatically)
        if card.has_method("set_card_state"):
            card.set_card_state(Card.State.HAND)
        
        # Make sure it's tracked in hand
        if not cards_in_hand.has(card):
            cards_in_hand.append(card)
        
        # Reposition hand cards
        if hand_container and hand_container.has_method("_reposition_cards"):
            hand_container._reposition_cards()
        elif card.has_method("reset_position"):
            card.reset_position()
        
        return false

# Helper function to return a card to hand (used for HandContainer Area2D drops)
func _return_card_to_hand(card):
    print("Returning card to hand: ", card.data.get("name", "Unknown") if card is Card else str(card))
    
    # Check if this card was attached to a chassis slot
    var was_attached = false
    var previous_slot = ""
    
    # Find if this card was in a slot before
    for slot_name in attached_parts:
        if attached_parts[slot_name] == card:
            was_attached = true
            previous_slot = slot_name
            break
    
    # If card was previously attached, remove from that slot
    if was_attached:
        print("Removing card from " + previous_slot + " and returning to hand")
        # Remove from previous slot tracking
        attached_parts.erase(previous_slot)
        
        # Clear the previous slot's part reference
        var prev_slot_control = chassis_slots_map[previous_slot]
        if prev_slot_control and prev_slot_control is ChassisSlot:
            prev_slot_control.clear_part()
    
    # Remove from slot parent and add back to hand
    if card.get_parent() != hand_container:
        # Capture the card's current global position before reparenting
        var card_global_pos = card.global_position
        
        if card.get_parent():
            card.get_parent().remove_child(card)
        if hand_container:
            hand_container.add_child(card)
            
            # Restore the card's global position after reparenting
            card.global_position = card_global_pos
    
    # Remove the attached flag
    if card.has_meta("attached_to_chassis"):
        card.remove_meta("attached_to_chassis")
    
    # Reset card properties for hand
    card.modulate = Color(1, 1, 1, 1)  # Reset transparency
    card.mouse_filter = Control.MOUSE_FILTER_STOP
    
    # Set card state to hand (this will handle scaling automatically)
    if card.has_method("set_card_state"):
        card.set_card_state(Card.State.HAND)
    
    # Make sure the card is properly tracked in hand
    if card is Card and not cards_in_hand.has(card):
        cards_in_hand.append(card)
        print("Added card back to hand tracking")
    
    # Reposition cards in hand container
    if hand_container and hand_container.has_method("_reposition_cards"):
        hand_container._reposition_cards()
    
    # Emit signal to update robot visuals after card removal
    emit_signal("chassis_updated", attached_parts)
