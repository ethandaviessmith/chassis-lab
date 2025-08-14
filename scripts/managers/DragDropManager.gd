class_name DragDropManager
extends Node

# References to other managers
var chassis_manager: ChassisManager
var hand_manager: HandManager

# Dictionary to map slot names to controls
var chassis_slots_map = {}

# Initialize the drag drop manager
func initialize(chassis_mgr: ChassisManager, hand_mgr: HandManager, slots_map: Dictionary):
    chassis_manager = chassis_mgr
    hand_manager = hand_mgr
    chassis_slots_map = slots_map

# Handle card drag event - highlight valid targets
func handle_card_drag(card):
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

# Handle card drop event - place card at target or determine best target
func handle_card_drop(card, drop_pos, target = null):
    # Reset all slot highlights
    reset_slot_highlights()
    
    # Reset card highlight
    if card is Card and card.has_method("set_highlight"):
        card.set_highlight(false)
    
    # Check if dropped on HandContainer or its Area2D
    if target != null:
        # Check if target is HandContainer or its Area2D
        if target is HandContainer or (target is Area2D and target.get_parent() is HandContainer):
            hand_manager.return_card_to_hand(card)
            return
        
        # Check if it's one of our chassis slots
        for slot_name in chassis_slots_map:
            if chassis_slots_map[slot_name] == target:
                if chassis_manager.attach_part_to_slot(card, slot_name):
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
        if chassis_manager.attach_part_to_slot(card, slot_name):
            return
    
    # If we get here, the card wasn't successfully placed, return it to hand
    hand_manager.return_card_to_hand(card)

# Reset all slot highlights
func reset_slot_highlights():
    for slot_name in chassis_slots_map:
        var slot = chassis_slots_map[slot_name]
        if slot and slot is ChassisSlot:
            slot.unhighlight()
        elif slot and slot.has_method("set_self_modulate"):
            slot.set_self_modulate(Color(1, 1, 1, 1))  # Reset tint

# Get slot name at position, or empty string if none
func _get_slot_at_position(check_pos):
    # For each slot, test direct hits
    for slot_name in chassis_slots_map:
        var slot = chassis_slots_map[slot_name]
        if slot:
            # Try different approaches to get the slot rect
            var slot_rect1 = Rect2(slot.global_position, slot.size)
            var slot_rect2 = slot.get_global_rect()
            
            # Use both approaches - if either one hits, count it as a match
            if slot_rect1.has_point(check_pos) or slot_rect2.has_point(check_pos):
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
    # In a real implementation, this should be passed in from a Control node that has access
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
