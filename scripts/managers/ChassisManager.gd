class_name ChassisManager
extends Node

signal chassis_updated(attached_parts)

# References to other managers
@export var turn_manager: TurnManager
@export var hand_manager: HandManager
@export var build_view: BuildView
@export var stat_manager: Node

@export var head_slot: Control
@export var core_slot: Control
@export var arm_left_slot: Control
@export var arm_right_slot: Control
@export var legs_slot: Control
@export var scrapper_slot: Control
@export var utility_slot: Control


# Dictionary to track attached parts
var attached_parts = {}

# Dictionary to map slot names to controls
var chassis_slots_map = {}

func _ready() -> void:
    # Initialize chassis slots map
    chassis_slots_map = {
        "scrapper": scrapper_slot,
        "head": head_slot,
        "core": core_slot,
        "arm_left": arm_left_slot,
        "arm_right": arm_right_slot,
        "legs": legs_slot,
        "utility": utility_slot
    }
    
    # Validate slots are assigned
    var missing_slots = []
    for slot_name in chassis_slots_map:
        if not chassis_slots_map[slot_name]:
            missing_slots.append(slot_name)
    
    if missing_slots.size() > 0:
        push_warning("ChassisManager: Missing slot assignments: " + str(missing_slots))

# Register chassis slots as valid drop targets for cards
func register_slots_as_drop_targets(card):
    print("=== DEBUG: register_slots_as_drop_targets called ===")
    
    if not card or not card.has_node("DragDrop"):
        print("ERROR: Card is null or has no DragDrop component")
        return
    
    var drag_drop = card.get_node("DragDrop")
    if drag_drop:
        # Clear existing targets first to avoid duplicates
        drag_drop.clear_drop_targets()
        
        var registered_count = 0
        # Register each chassis slot as a drop target
        for slot_name in chassis_slots_map:
            var slot = chassis_slots_map[slot_name]
            if slot:
                # Get the accepted card types for this slot
                var valid_types = _get_valid_types_for_slot(slot_name)
                # Register the slot as a drop target
                drag_drop.register_drop_target(slot, valid_types)
                registered_count += 1
        
        print("Registered ", registered_count, " drop targets for card type: ", 
              card.data.type if card.data and card.data.has("type") else "unknown")

# Get valid card types for each slot type
func _get_valid_types_for_slot(slot_name: String) -> Array:
    # Each slot only accepts certain card types
    match slot_name.to_lower():
        "head":
            return ["head"]
        "core":
            return ["core"]
        "arm_left", "arm_right":
            return ["arm"]
        "legs":
            return ["legs", "leg"]  # Accept both singular and plural
        "utility":
            return ["utility"]
        "scrapper":
            # Scrapper accepts all types as long as they have heat
            # Returning all types, but heat check is done in _attach_card_to_scrapper
            return ["head", "core", "arm", "legs", "leg", "utility"]
    
    return []

# Calculate heat from attached parts
func calculate_heat() -> Dictionary:
    var needed_heat = 0
    var scrapper_heat = 0
    
    # Calculate needed heat from non-scrapper slots
    for slot_name in ["head", "core", "arm_left", "arm_right", "legs", "utility"]:
        if slot_name in attached_parts:
            var slot_content = attached_parts[slot_name]
            if slot_content is Card:
                # Handle single card
                if "heat" in slot_content.data:
                    needed_heat += int(slot_content.data.heat)
            elif slot_content is Dictionary and "heat" in slot_content:
                # Handle legacy dictionary data
                needed_heat += int(slot_content.heat)
    
    # Calculate scrapper heat from scrapper slot
    if "scrapper" in attached_parts:
        var scrapper_content = attached_parts["scrapper"]
        if scrapper_content is Array:
            # Handle multiple cards in scrapper
            for card_item in scrapper_content:
                if is_instance_valid(card_item):
                    if card_item is Card and "heat" in card_item.data:
                        scrapper_heat += int(card_item.data.heat)
                    elif card_item is Dictionary and "heat" in card_item:
                        scrapper_heat += int(card_item.heat)
        elif scrapper_content is Card:
            # Handle single card in scrapper (fallback)
            if "heat" in scrapper_content.data:
                scrapper_heat += int(scrapper_content.data.heat)
        elif scrapper_content is Dictionary:
            # Handle legacy single card data
            if "heat" in scrapper_content:
                scrapper_heat += int(scrapper_content.heat)
    
    # Start with 2 base heat in the scrapper
    var base_scrapper_heat = 2
    var total_scrapper_heat = scrapper_heat + base_scrapper_heat
    var max_heat = max(10, needed_heat + total_scrapper_heat)  # Dynamic max based on content
    
    return {
        "needed_heat": needed_heat,
        "scrapper_heat": total_scrapper_heat, # Include base 2 heat
        "max_heat": max_heat,
        "total_needed": needed_heat,
        "total_available": total_scrapper_heat,
        "has_enough_heat": total_scrapper_heat >= needed_heat
    }

# Check if there's enough heat to build the robot
func has_enough_heat() -> bool:
    var heat_data = calculate_heat()
    return heat_data.scrapper_heat >= heat_data.needed_heat

# Attach a part to a specific slot
func attach_part_to_slot(card, slot_name) -> bool:
    var card_data = card.data if card is Card else card.get_meta("card_data")
    
    # Handle scrapper slot specially (accepts any card type and multiple cards)
    if slot_name == "scrapper":
        return _attach_card_to_scrapper(card)
    
    # Check if card type matches slot type for regular slots
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
            valid_slot = true #(slot_name == "scrapper")
    
    if not valid_slot:
        return false
    
    var card_cost = card_data.get("cost", 0)
    var card_current_slot = ""
    
    # Check if this card is already attached somewhere else
    for existing_slot in attached_parts:
        var slot_content = attached_parts[existing_slot]
        if slot_content is Array:
            # Handle scrapper slot with multiple cards
            var cards_array = slot_content as Array
            if cards_array.has(card):
                card_current_slot = existing_slot
                break
        elif slot_content == card:
            # Handle regular single-card slots
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
    
    # For moves between slots, scrapper, or already attached cards, no energy cost
    if card_current_slot != "" or slot_name == "scrapper":
        energy_change = 0
    else:
        # Calculate net energy requirement: cost of new card minus refund from old card
        energy_change = card_cost - previous_card_cost
        
        # Check if we have enough energy for the net cost
        if energy_change > 0 and turn_manager:
            if turn_manager.current_energy < energy_change:
                return false
    
    # If the card is moving from one slot to another, clean up the old slot first
    if card_current_slot != "" and card_current_slot != slot_name:
        # Handle differently based on the source slot type
        if card_current_slot == "scrapper" and attached_parts[card_current_slot] is Array:
            # For scrapper, just remove from the attached_parts array (not the scrapper slot's cards)
            var attached_scrapper_cards = attached_parts[card_current_slot] as Array
            if attached_scrapper_cards.has(card):
                attached_scrapper_cards.erase(card)
                
            # Also update the ScrapperSlot
            if card_current_slot == "scrapper" and chassis_slots_map[card_current_slot] is ScrapperSlot:
                chassis_slots_map[card_current_slot].remove_card(card)
        else:
            # For regular slots, remove the slot entirely
            attached_parts.erase(card_current_slot)
        
        # Clear the old slot's part reference
        var old_slot_control = chassis_slots_map[card_current_slot]
        if old_slot_control and old_slot_control is ChassisSlot:
            old_slot_control.clear_part()
    
    # Handle previous part in this slot if any (different card)
    var _previous_card = null
    if attached_parts.has(slot_name) and is_instance_valid(attached_parts[slot_name]) and attached_parts[slot_name] != card:
        _previous_card = attached_parts[slot_name]
        
        # For regular slots (not scrapper), we need to return the previous card to hand
        if slot_name != "scrapper" and hand_manager and _previous_card is Card:
            hand_manager.return_card_to_hand(_previous_card)
        
    # Apply energy cost if this is a new card from hand
    if energy_change > 0 and turn_manager:
        turn_manager.spend_energy(energy_change)
    
    # Update attached_parts dictionary - only replace for regular slots, scrapper is handled separately
    if slot_name != "scrapper":
        attached_parts[slot_name] = card
    
    # Get the target slot
    var target_slot = chassis_slots_map[slot_name]
    
    # Update the target slot with the part
    if target_slot and target_slot is ChassisSlot:
        # Check if there's already a part in this slot (non-scrapper slots)
        if slot_name != "scrapper" and target_slot.get_part() != null and target_slot.get_part() != card:
            var previous_card = target_slot.get_part()
            if previous_card is Card and hand_manager:
                print("Returning previous card from slot to hand: ", previous_card.data.get("name", "Unknown"))
                hand_manager.return_card_to_hand(previous_card)
        
        # Position the card in the center of the slot
        if card is Card:
            # Set state to CHASSIS_SLOT to trigger scaling
            if card.has_method("set_card_state"):
                card.set_card_state(Card.State.CHASSIS_SLOT)
            
            # Now that the card is set to chassis slot state with 0.5 scale,
            # we need to account for that in our positioning
            # The slot center needs to accommodate the VISIBLE size (which is half)
            var slot_center = target_slot.global_position + (target_slot.size / 2)
            
            # The offset needs to account for the fact that the card will be half size
            # So we center based on the visual bounds, not the logical bounds
            var card_visual_size = card.size * 0.5  # Card is scaled to 0.5 in chassis
            card.target_position = slot_center - (card_visual_size / 2)
            
            print("Setting card target_position to center of slot: ", card.target_position)
            
        # Add the card to the slot (after setting its state and position)
        target_slot.set_part(card)
        
        # Play attach sound
        Sound.play_attach_part()

            
        # Trigger screen shake
        var main = get_tree().get_root().get_node_or_null("Main")
        if main:
            var screen_shake = main.get_node_or_null("ScreenShake") 
            if screen_shake and screen_shake.has_method("start_shake"):
                screen_shake.start_shake()
    
    # Emit signal to update any robot visuals
    emit_signal("chassis_updated", attached_parts)
    
    return true

func discard_scrapper_card(card):
    if !chassis_slots_map["scrapper"]:
        return null
        
    # Remove from the scrapper slot
    chassis_slots_map["scrapper"].remove_card(card)
    
    # Also update attached_parts if needed
    if "scrapper" in attached_parts and attached_parts["scrapper"] is Array:
        if attached_parts["scrapper"].has(card):
            attached_parts["scrapper"].erase(card)
    
    # Emit signal to update visuals
    emit_signal("chassis_updated", attached_parts)
    
    return true

func get_scrapper_cards():
    if !chassis_slots_map["scrapper"]:
        return []
        
    # Return a duplicate of the array to prevent issues when items are removed
    # This prevents the caller from iterating through an array while we modify it
    return chassis_slots_map["scrapper"].get_all_cards()

# Attach card to the scrapper slot
func _attach_card_to_scrapper(card) -> bool:
    var scrapper_slot_control = chassis_slots_map["scrapper"]
    if not scrapper_slot_control or not scrapper_slot_control is ScrapperSlot:
        return false
    
    # Check if the card has heat (must have at least 1 heat for scrapper)
    if card is Card and card.data.has("heat"):
        var heat_value = int(card.data.heat)
        if heat_value < 1:
            print("Card rejected from scrapper: must have at least 1 heat")
            return false
    
    # Check if there's room in the scrapper
    var max_cards = 5 # Default capacity
    if scrapper_slot_control.has_method("get_capacity"):
        max_cards = scrapper_slot_control.get_capacity()
    
    # Initialize scrapper array if it doesn't exist
    if not attached_parts.has("scrapper") or not attached_parts["scrapper"] is Array:
        attached_parts["scrapper"] = []
    
    var scrapper_cards = attached_parts["scrapper"] as Array
    
    # If we've reached capacity, we can't add more cards
    if scrapper_cards.size() >= max_cards:
        return false
    
    # Check if the card is already in another slot
    var card_current_slot = ""
    for existing_slot in attached_parts:
        if existing_slot == "scrapper":
            continue # Skip checking scrapper slot itself
            
        var slot_content = attached_parts[existing_slot]
        if slot_content == card:
            card_current_slot = existing_slot
            break
    
    # If card is in another slot, remove it from there
    if card_current_slot != "":
        attached_parts.erase(card_current_slot)
        
        # Clear the old slot's part reference
        var old_slot = chassis_slots_map[card_current_slot]
        if old_slot and old_slot is ChassisSlot:
            old_slot.clear_part()
    
    # Add card to scrapper array if not already there
    if not scrapper_cards.has(card):
        scrapper_cards.append(card)
    
    # Update the scrapper slot with the new array of cards
    if scrapper_slot_control.has_method("add_scrapper_card"):
        # Position the card in the appropriate position in the scrapper slot
        if card is Card:
            # Set state to CHASSIS_SLOT to trigger scaling
            if card.has_method("set_card_state"):
                card.set_card_state(Card.State.CHASSIS_SLOT)
                
            var base_position = scrapper_slot_control.global_position
            var cards_count = scrapper_cards.size()
            
            # Calculate position based on number of cards in scrapper
            var offset_x = (cards_count - 1) * 20  # Offset cards horizontally
            
            # Account for the visual size (half size in chassis slot)
            var card_visual_size = card.size * 0.5
            
            # Position with the horizontal offset, and vertically centered
            var slot_center_y = scrapper_slot_control.size.y / 2
            var target_y = base_position.y + (slot_center_y - card_visual_size.y / 2)
            card.target_position = Vector2(base_position.x + offset_x, target_y)
            
            print("Setting scrapper card target_position: ", card.target_position)
            
        # Add the card to the slot (after setting its state and position)
        scrapper_slot_control.add_scrapper_card(card)
    
    # Emit signal to update any robot visuals
    emit_signal("chassis_updated", attached_parts)
    
    return true

# Clear all chassis parts
func clear_all_chassis_parts() -> Array:
    # Return all attached cards to hand
    var cards_to_return = []
    for slot_name in attached_parts:
        var slot_content = attached_parts[slot_name]
        if slot_content is Array:
            # Handle scrapper slot with multiple cards
            for card in slot_content:
                if is_instance_valid(card) and card is Card:
                    cards_to_return.append(card)
        elif is_instance_valid(slot_content) and slot_content is Card:
            # Handle regular slots with single cards
            cards_to_return.append(slot_content)
            
    # Play detach sound if we have parts to detach
    if cards_to_return.size() > 0:
        Sound.play_detach_part()
    
    # Clear the attached_parts tracking first
    attached_parts.clear()
    
    # Clear all chassis slots
    for slot_name in chassis_slots_map:
        var slot = chassis_slots_map[slot_name]
        if slot and slot.has_method("clear_part"):
            slot.clear_part()
    
    # Reset energy to maximum when clearing chassis
    if turn_manager and turn_manager.has_method("reset_energy"):
        turn_manager.reset_energy()
    
    # Emit signal to update robot visuals (empty chassis)
    emit_signal("chassis_updated", attached_parts)
    
    return cards_to_return
    
# === DRAG DROP FUNCTIONALITY ===

# Handle card drag event - highlight valid targets
func handle_card_drag(card):
    print("=== DEBUG: handle_card_drag called ===")
    if not card:
        print("ERROR: Card is null in handle_card_drag")
        return
        
    # Register slots as drop targets for this card
    register_slots_as_drop_targets(card)
    
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
                    print("Card data found: type = ", card_data.get("type", "unknown"))
                else:
                    slot.highlight(false)  # Pass false for invalid highlight

    # Setup mouse enter/exit signals for slots to show stat previews
    if stat_manager:
        # Connect to mouse hover events for each slot
        for slot_name in chassis_slots_map:
            var slot = chassis_slots_map[slot_name]
            if slot and slot is Control:
                # Check if this slot type matches the card type
                var valid_slot = is_valid_slot_for_card(card, slot_name)
                if valid_slot:
                    # Disconnect existing signals if any
                    if slot.is_connected("mouse_entered", Callable(self, "_on_slot_mouse_entered")):
                        slot.disconnect("mouse_entered", Callable(self, "_on_slot_mouse_entered"))
                    if slot.is_connected("mouse_exited", Callable(self, "_on_slot_mouse_exited")):
                        slot.disconnect("mouse_exited", Callable(self, "_on_slot_mouse_exited"))
                    
                    # Connect new signals
                    slot.mouse_entered.connect(Callable(self, "_on_slot_mouse_entered").bind(card, slot_name))
                    slot.mouse_exited.connect(Callable(self, "_on_slot_mouse_exited"))

# Check if slot is valid for a card type
func is_valid_slot_for_card(card, slot_name: String) -> bool:
    if not card or not card.data or not card.data.has("type"):
        return false
    
    # Special case for scrapper slot (accepts any card)
    if slot_name == "scrapper":
        return true
    
    # Check card type against slot type
    match card.data.type:
        "Head":
            return slot_name == "head"
        "Core":
            return slot_name == "core"
        "Arm":
            return slot_name == "arm_left" or slot_name == "arm_right"
        "Leg", "Legs":
            return slot_name == "legs"
        "Utility":
            return slot_name == "utility"
    
    return false

# Handler for mouse entering a valid slot
func _on_slot_mouse_entered(card: Card, slot_name: String):
    if stat_manager and stat_manager.has_method("card_hover_over_slot"):
        stat_manager.card_hover_over_slot(card, slot_name)

# Handler for mouse exiting a slot
func _on_slot_mouse_exited():
    if stat_manager and stat_manager.has_method("card_hover_end"):
        stat_manager.card_hover_end()

# Handle card drop event - place card at target or determine best target
func handle_card_drop(card, drop_pos, target = null):
    print("ChassisManager: Handling card drop at position: ", drop_pos)
    
    # Reset all slot highlights
    reset_slot_highlights()
    
    # Reset card highlight
    if card is Card and card.has_method("set_highlight"):
        card.set_highlight(false)
    else:
        print("WARNING: Card doesn't have set_highlight method")
    
    # Check if dropped on HandContainer or its Area2D
    if target != null:
        # Check if target is HandContainer or its Area2D
        if target is HandContainer or (target is Area2D and target.get_parent() is HandContainer):
            print("Card dropped on HandContainer")
            
            # First remove card from any chassis slots it might be in
            var card_current_slot = ""
            for existing_slot in attached_parts:
                var slot_content = attached_parts[existing_slot]
                if slot_content is Array:
                    # Handle scrapper slot with multiple cards
                    var cards_array = slot_content as Array
                    if cards_array.has(card):
                        card_current_slot = existing_slot
                        cards_array.erase(card)
                        break
                elif slot_content == card:
                    # Handle regular single-card slots
                    card_current_slot = existing_slot
                    attached_parts.erase(existing_slot)
                    break
            
            # Clear the slot if needed
            if card_current_slot != "":
                Sound.play_detach_part()
                print("Removing card from chassis slot: ", card_current_slot)
                var old_slot = chassis_slots_map[card_current_slot] if chassis_slots_map.has(card_current_slot) else null
                if old_slot and old_slot is ChassisSlot:
                    old_slot.clear_part()
                
                # Mark that the card was attached to a slot (for positioning)
                if card is Card:
                    card.set_meta("was_attached", true)
                    # Remove attached_to_chassis metadata if it exists
                    if card.has_meta("attached_to_chassis"):
                        card.remove_meta("attached_to_chassis")
                
                # Update UI for robot visuals
                emit_signal("chassis_updated", attached_parts)
            
            # Check for recursion guard
            if card.has_meta("handling_drop"):
                print("ChassisManager: Preventing recursive drop handling")
                return
                
            # Set a guard to prevent recursion
            card.set_meta("handling_drop", true)
            
            if hand_manager:
                hand_manager.return_card_to_hand(card)
            
            # Remove the guard
            card.remove_meta("handling_drop")
            return
        
        # Check if it's one of our chassis slots
        for slot_name in chassis_slots_map:
            if chassis_slots_map[slot_name] == target:
                if attach_part_to_slot(card, slot_name):
                    return
    
    # Try several approaches to find the slot
    var slot_name = ""
    
    # First try exact position check
    slot_name = _get_slot_at_position(drop_pos)
    
    # If that didn't work, try the card's global position
    if slot_name == "" and card is Card:
        var card_center = card.global_position + (card.size / 2)
        slot_name = _get_slot_at_position(card_center)
        
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
                        break
                if slot_name != "":
                    break
            if slot_name != "":
                break
    
    if slot_name != "":
        # Attach to slot (method handles replacing existing parts)
        if attach_part_to_slot(card, slot_name):
            return
    
    # If we get here, the card wasn't successfully placed, return it to hand
    # Play error sound
    Sound.play_error()
    
    if hand_manager:
        hand_manager.return_card_to_hand(card)

# Reset all slot highlights
func reset_slot_highlights():
    print("Resetting all slot highlights")
    for slot_name in chassis_slots_map:
        var slot = chassis_slots_map[slot_name]
        if slot and slot is ChassisSlot:
            print("Unhighlighting slot: ", slot_name)
            slot.unhighlight()
        elif slot and slot.has_method("set_self_modulate"):
            slot.set_self_modulate(Color(1, 1, 1, 1))  # Reset tint
        elif slot and slot.has_method("highlight"):
            # Call highlight with false to unhighlight
            slot.highlight(false)
    
    # Also ensure we clear any active tweens
    for slot_name in chassis_slots_map:
        var slot = chassis_slots_map[slot_name]
        if slot:
            var bg = slot.get_node_or_null("Background") if slot.has_method("get_node_or_null") else null
            if bg and bg.has_meta("active_tween"):
                var tween = bg.get_meta("active_tween")
                if tween and tween.is_valid() and tween.is_running():
                    tween.kill()
                bg.remove_meta("active_tween")

# Get slot name at position, or empty string if none
func _get_slot_at_position(check_pos):
    print("Checking for slot at position: ", check_pos)
    
    # For each slot, test direct hits
    for slot_name in chassis_slots_map:
        var slot = chassis_slots_map[slot_name]
        if slot:
            print("Testing slot: ", slot_name, " at position: ", slot.global_position, " with size: ", slot.size)
            
            # Try different approaches to get the slot rect
            var slot_rect1 = Rect2(slot.global_position, slot.size)
            var slot_rect2 = slot.get_global_rect()
            
            # Use both approaches - if either one hits, count it as a match
            if slot_rect1.has_point(check_pos) or slot_rect2.has_point(check_pos):
                print("FOUND MATCH for slot: ", slot_name, " with check_pos: ", check_pos)
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
            
            # Keep track of closest slot
            if distance < closest_distance and distance < 150:  # Within reasonable range
                closest_distance = distance
                closest_slot = slot_name
    
    # If we found a reasonably close slot and no exact match
    if closest_slot != "" and closest_distance < 100:
        return closest_slot
        
    # Direct manual detection attempt as last resort
    # We know the exact positions and sizes of slots, so let's try absolute positioning
    
    # Since we can't directly access the viewport as a Node, use a typical viewport size
    # In a real implementation, this should be passed from the parent control
    var viewport_size = Vector2(1280, 720)  # Default size
    
    # Top area is likely head
    if check_pos.y < viewport_size.y * 0.3:
        return "head"
    
    # Center area is likely core
    if check_pos.y < viewport_size.y * 0.6 and check_pos.y > viewport_size.y * 0.3:
        if check_pos.x > viewport_size.x * 0.3 and check_pos.x < viewport_size.x * 0.7:
            return "core"
    
    # Left side is left arm
    if check_pos.x < viewport_size.x * 0.4 and check_pos.y > viewport_size.y * 0.3:
        return "arm_left"
    
    # Right side is right arm
    if check_pos.x > viewport_size.x * 0.6 and check_pos.y > viewport_size.y * 0.3:
        return "arm_right"
    
    # Bottom center is legs
    if check_pos.y > viewport_size.y * 0.7 and check_pos.x > viewport_size.x * 0.3 and check_pos.x < viewport_size.x * 0.7:
        return "legs"
        
    return ""
