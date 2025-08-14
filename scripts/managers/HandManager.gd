class_name HandManager
extends Node

signal card_drawn(card)

# External references
@export var deck_manager: DeckManager
@export var hand_container: Container
@export var turn_manager: TurnManager
@export var build_view: BuildView

@export var card_scene: PackedScene

# Card tracking
var cards_in_hand = []

# Draw the initial hand of cards
func draw_starting_hand():
    # Reset existing cards
    clear_hand()
    
    # Draw new cards
    var hand = deck_manager.draw_hand()
    
    # If hand is empty, try to reload the deck
    if hand.size() == 0:
        if deck_manager.has_method("reload_deck"):
            deck_manager.reload_deck()
            hand = deck_manager.draw_hand()
    
    # If still empty, fall back to test cards
    if hand.size() == 0:
        create_test_cards()
        return
    
    # Create card sprites for each card in hand
    for i in range(hand.size()):
        create_card_sprite(hand[i], i)

# Draw a single card from deck to hand
func draw_single_card():
    if not deck_manager:
        return
    
    # Check if hand is at max capacity
    if cards_in_hand.size() >= deck_manager.max_hand_size:
        return
    
    # Draw the card first (this handles deck/discard reshuffling internally)
    var drawn_card = deck_manager.draw_card()
    if not drawn_card.is_empty():
        # Create visual for the new card (use current hand size as index since we're about to add it)
        create_card_sprite(drawn_card, cards_in_hand.size())
        
        # Update deck visual
        return true
        
    return false

# Start drawing cards sequentially with delay
func start_sequential_card_draw():
    if not deck_manager:
        return
    
    # Draw cards up to hand limit with delay
    var max_cards = deck_manager.max_hand_size
    
    # If deck is empty, try to force reload
    var initial_status = deck_manager.get_deck_status()
    if initial_status.deck_size == 0 and initial_status.discard_size == 0:
        deck_manager.reload_deck()
        await get_tree().process_frame  # Wait for reload to complete
    
    for i in range(max_cards):
        # Check if we can still draw cards
        if cards_in_hand.size() >= deck_manager.max_hand_size:
            break
        
        # If no cards available, break
        var deck_status = deck_manager.get_deck_status()
        if deck_status.deck_size == 0 and deck_status.discard_size == 0:
            break
        
        # Draw the card
        draw_single_card()
        
        # Wait 0.2 seconds before drawing next card
        if i < max_cards - 1:  # Don't wait after the last card
            await get_tree().create_timer(0.2).timeout

# Clear all cards from hand
func clear_hand():
    for card in cards_in_hand:
        card.queue_free()
    cards_in_hand.clear()

# Create a visual representation of a card
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
            card.position = Vector2(center_x + (index - cards_in_hand.size()/2.0) * 120, center_y)
            # Add to scene if not using container
            add_child(card)
        
        # Ensure the card's internal nodes are ready
        if Engine.is_editor_hint() == false:
            await get_tree().process_frame
            
        # Check if card has necessary signals
        print("Card signals: ", card.get_signal_list().map(func(s): return s.name))
        
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
            card.set_hand_container(hand_container)
            
            # Set initial card state to hand
            if card.has_method("set_card_state"):
                card.set_card_state(Card.State.HAND)
            
            # Connect card signals to BuildView handlers
            if build_view and card.has_signal("drop_attempted"):
                # Connect drop_attempted signal to _handle_card_drop
                if not card.drop_attempted.is_connected(Callable(build_view, "_handle_card_drop")):
                    card.drop_attempted.connect(Callable(build_view, "_handle_card_drop"))
                # Connect drag_started signal to _handle_card_drag
                if card.has_signal("drag_started") and not card.drag_started.is_connected(Callable(build_view, "_handle_card_drag")):
                    card.drag_started.connect(Callable(build_view, "_handle_card_drag"))
                    print("Connected drag_started signal for card: ", card.name)
                print("Connected card signals to BuildView")
                
            # Emit signal that a card was drawn/created
            emit_signal("card_drawn", card)
        else:
            print("ERROR: Card scene is missing initialize method!")
    else:
        # This is a fallback that shouldn't be needed in production
        print("ERROR: Failed to load Card scene, using fallback")
    
    return card

# Return card to hand
func return_card_to_hand(card):
    if not is_instance_valid(card):
        return false
        
    # Reset card properties for hand
    card.modulate = Color(1, 1, 1, 1)  # Reset transparency
    card.mouse_filter = Control.MOUSE_FILTER_STOP
    
    # Set card state to hand (this will handle scaling automatically)
    if card.has_method("set_card_state"):
        card.set_card_state(Card.State.HAND)
    
    # Add back to hand container if not already there
    if card.get_parent() != hand_container:
        # Capture the card's current global position before reparenting
        var card_global_pos = card.global_position
        
        if card.get_parent():
            card.get_parent().remove_child(card)
        if hand_container:
            hand_container.add_child(card)
            
            # Restore the card's global position after reparenting
            card.global_position = card_global_pos
            
            # Make sure the hand container is registered as a drop target
            if card.has_method("set_hand_container"):
                card.set_hand_container(hand_container)
    
    # Make sure the card is properly tracked in hand
    if not cards_in_hand.has(card):
        cards_in_hand.append(card)
    
    # If card was attached to chassis, refund energy cost and clear metadata
    if card.has_meta("attached_to_chassis"):
        # Get the energy cost of the card
        var card_cost = 0
        if card is Card and card.data.has("cost"):
            card_cost = int(card.data.cost)
        
        # Refund energy if cost is greater than 0 and turn_manager exists
        if card_cost > 0 and turn_manager and turn_manager.has_method("gain_energy"):
            print("HandManager: Refunding ", card_cost, " energy for returned card")
            turn_manager.gain_energy(card_cost)
        
        # Clear the chassis attachment metadata
        card.remove_meta("attached_to_chassis")
    
    # Set a guard flag on the card to prevent recursion
    card.set_meta("returning_to_hand", true)
    
    # Explicitly call the card's reset_position method to ensure target_position is set correctly
    if card.has_method("reset_position"):
        card.reset_position()
    
    # Remove the guard flag
    card.remove_meta("returning_to_hand")
    
    # Reposition cards in hand container (this will update all target positions)
    if hand_container and hand_container.has_method("_reposition_cards"):
        hand_container._reposition_cards()
        
    return true

# Create test cards when no DeckManager available
func create_test_cards():
    # Reset existing cards
    clear_hand()
    
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

# Update card affordability in hand
func update_card_affordability(available_energy: int):
    for card in cards_in_hand:
        if card is Card and card.has_method("update_affordability"):
            card.update_affordability(available_energy)
