class_name HandManager
extends Node

signal card_drawn(card)

# External references
@export var deck_manager: DeckManager
@export var hand_container: Container
@export var turn_manager: TurnManager
@export var build_view: BuildView

@export var card_scene: PackedScene

# Card tracking - only the visual representation, actual cards are managed by DeckManager
var cards_in_hand = []

func _ready():
    # Connect to DeckManager's card lifecycle signals
    if deck_manager:
        deck_manager.card_drawn_to_hand.connect(_on_card_drawn_to_deck_hand)
        deck_manager.hand_emptied.connect(_on_hand_emptied)
    else:
        push_error("HandManager: No DeckManager assigned!")
        
# Handler for when DeckManager draws a card to hand
func _on_card_drawn_to_deck_hand(card_data):
    # Create visual representation of the card
    create_card_instance(card_data)
    
# Handler for when DeckManager empties the hand
func _on_hand_emptied():
    # Remove all visual cards
    clear_hand()
    
# Create visual representation of a card and add it to the hand
func create_card_instance(card_data):
    # Calculate the index for the new card
    var new_index = cards_in_hand.size()
    
    # Create the card using the existing method - this is a coroutine so we need to await
    var card = await create_card_sprite(card_data, new_index)
    
    # Emit our signal for anyone who needs to know
    emit_signal("card_drawn", card)

# # Draw the initial hand of cards
# func draw_starting_hand():
#     # Before drawing, check if we already have cards in hand
#     if cards_in_hand.size() > 0:
#         print("HandManager: Cards already in hand, not drawing starting hand")
#         return
    
#     # Reset existing cards to be safe
#     clear_hand()
    
#     # Draw new cards
#     var hand = deck_manager.draw_hand()
    
#     # If hand is empty, try to reload the deck, but only if we don't have ANY cards anywhere
#     var status = deck_manager.get_deck_status()
#     if hand.size() == 0 and status.deck_size == 0 and status.discard_size == 0:
#         print("HandManager: Empty deck and no cards anywhere, attempting to reload deck")
#         if deck_manager.has_method("reload_deck"):
#             deck_manager.reload_deck()
#             hand = deck_manager.draw_hand()
    
#     # If still empty, fall back to test cards
#     if hand.size() == 0:
#         print("HandManager: Still no cards, using test cards")
#         create_test_cards()
#         return
    
#     # Create card sprites for each card in hand
#     print("HandManager: Creating card sprites for " + str(hand.size()) + " cards")
#     for i in range(hand.size()):
#         create_card_sprite(hand[i], i)

# Draw a single card from deck to hand
# This method now delegates to DeckManager to handle the actual card draw
# and relies on signals to update the visual representation
func draw_single_card():
    if not deck_manager:
        print("HandManager: No deck_manager available, cannot draw card")
        return false
    
    # Check if hand is at max capacity
    if cards_in_hand.size() >= deck_manager.max_hand_size:
        print("HandManager: Hand is already at max capacity (" + str(cards_in_hand.size()) + "/" + str(deck_manager.max_hand_size) + ")")
        return false
    
    # Draw the card from DeckManager - this will emit card_drawn_to_hand signal
    # which we're already connected to via _on_card_drawn_to_deck_hand
    print("HandManager: Delegating card draw to DeckManager")
    var card_data = deck_manager.draw_card()
    
    # Check if we got a valid card
    if card_data.is_empty():
        print("HandManager: Failed to draw card - empty result from deck_manager")
        return false
    
    # Note: We don't need to create the card sprite here anymore
    # The signal handler _on_card_drawn_to_deck_hand will handle it
    
    # Log the card counts after drawing
    print("HandManager: Visual cards in hand: " + str(cards_in_hand.size()) + 
          ", DeckManager hand array size: " + str(deck_manager.hand.size()))
    
    return true

# Start drawing cards sequentially with delay
func start_sequential_card_draw():
    if not deck_manager:
        print("HandManager: No deck manager, cannot draw cards")
        return
    
    # Calculate exactly how many cards we need
    var cards_needed = deck_manager.max_hand_size - cards_in_hand.size()
    print("HandManager: Need to draw " + str(cards_needed) + " cards to fill hand")
    
    # Don't do anything if we don't need cards
    if cards_needed <= 0:
        print("HandManager: Hand already full, not drawing more cards")
        return
    
    # Only reload deck if truly necessary
    var initial_status = deck_manager.get_deck_status()
    if initial_status.deck_size == 0 and initial_status.discard_size > 0:
        # Note: DeckManager.draw_card() will handle reshuffling as needed
        print("HandManager: Draw deck empty, will trigger reshuffle when drawing")
    elif initial_status.deck_size == 0 and initial_status.discard_size == 0 and initial_status.exhausted_size == 0 and initial_status.hand_size == 0:
        print("HandManager: No cards anywhere in system, reloading deck")
        deck_manager.reload_deck()
        await get_tree().process_frame
    
    # Draw exactly the number of cards needed
    print("HandManager: Drawing " + str(cards_needed) + " cards sequentially")
    
    # Draw cards one by one with delay between each
    var cards_drawn = 0
    for i in range(cards_needed):
        # CRITICAL CHECK: Stop drawing if we've reached max hand size
        if cards_in_hand.size() >= deck_manager.max_hand_size:
            print("HandManager: Max hand size reached during sequential draw, stopping")
            break
            
        # Draw a single card
        var success = draw_single_card()
        
        # Check if draw was successful
        if not success:
            print("HandManager: Failed to draw card " + str(i+1) + ", stopping")
            break
        
        # Count successful draws
        cards_drawn += 1
        
        # Wait before drawing next card (except for the last one)
        if i < cards_needed - 1:
            await get_tree().create_timer(0.2).timeout
    
    print("HandManager: Finished sequential draw, drew " + str(cards_drawn) + " cards")

# Clear all cards from hand
func clear_hand():
    for card in cards_in_hand:
        card.queue_free()
    cards_in_hand.clear()
    
# Reset the hand state for a new build phase
func reset_hand():
    print("HandManager: Resetting hand state")
    
    # First clear any existing cards
    clear_hand()
    
    # Make sure our internal state matches DeckManager
    if deck_manager:
        # Synchronize hand tracking with DeckManager
        var status = deck_manager.get_deck_status()
        print("HandManager: Deck status - Draw: %d, Hand: %d, Discard: %d" % [status.deck_size, status.hand_size, status.discard_size])
        
        # If DeckManager thinks cards are in hand but we've cleared them,
        # we need to make sure they get moved to discard
        if status.hand_size > 0:
            print("HandManager: Moving %d lingering cards from DeckManager hand to discard" % status.hand_size)
            deck_manager.discard_all_from_hand()
    else:
        print("HandManager: No deck_manager reference, cannot synchronize state")

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
        print("HandManager: Added card to cards_in_hand array, new size: " + str(cards_in_hand.size()) + 
              ", index was: " + str(index))
        
        # Initialize the card data
        if card.has_method("initialize"):
            card.initialize(prepared_data, hand_container, deck_manager)
            
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

# Discard all cards in hand to the discard pile
func discard_hand():
    if not deck_manager:
        print("HandManager: No deck_manager found, cannot discard hand")
        return
    
    print("HandManager: Discarding all cards in hand... Current visual cards: " + str(cards_in_hand.size()))
    
    # Clear the visual hand
    clear_hand()
    
    # Tell DeckManager to discard all cards from hand
    deck_manager.discard_all_from_hand()
    
    print("HandManager: After discarding - Visual cards: " + str(cards_in_hand.size()) + 
          ", DeckManager hand size: " + str(deck_manager.hand.size()))
          
    # Final validation
    var status = deck_manager.get_deck_status()
    var total_cards = status.deck_size + status.discard_size + status.exhausted_size
    print("HandManager: Total tracked cards after discard: " + str(total_cards))
