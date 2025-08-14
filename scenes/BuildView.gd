extends Control
class_name BuildView

signal combat_requested()
signal chassis_updated(attached_parts)

# References to managers - set these in the editor
@export var game_manager: GameManager
@export var deck_manager: DeckManager
@export var turn_manager: TurnManager
@export var chassis_manager: ChassisManager
@export var hand_manager: HandManager

# UI elements
@export var energy_label: Label
@export var heat_label: Label
@export var end_phase_button: Button
@export var clear_chassis_button: Button

# Energy and Heat Bars
@export var energy_bar: EnergyBar
@export var heat_bar: HeatBar

# Card container
@export var hand_container: Container
@export var deck_container: Control
var cards_in_hand = []


# Dictionary to map slot names to controls
var chassis_slots_map = {}

# Dictionary to track attached parts
var attached_parts = {}

# Managers


# Called when the node enters the scene tree for the first time
func _ready():   
    # Initialize managers first
    _initialize_managers()
    
    # Connect chassis manager signals
    if chassis_manager:
        chassis_manager.chassis_updated.connect(func(parts): emit_signal("chassis_updated", parts))
    
    # Connect TurnManager to energy label if both exist
    if turn_manager and energy_label:
        turn_manager.set_energy_label(energy_label)
        turn_manager.energy_changed.connect(_on_energy_changed)
    
    # Connect to energy and heat bars
    if turn_manager and energy_bar:
        turn_manager.energy_changed.connect(_on_energy_changed_bar)
        # Initialize energy bar with current values
        energy_bar.set_energy(turn_manager.current_energy, turn_manager.max_energy)
    
    if heat_bar:
        # Connect chassis updates to heat calculation
        chassis_updated.connect(_on_chassis_updated_heat)
        # Initialize heat bar with zero values
        heat_bar.set_heat(0, 0, 10)
    
    # Setup UI elements
    setup_ui()
    
    # Initialize the build phase
    start_build_phase()

# Initialize all managers and connect signals
func _initialize_managers():
    # Initialize the chassis manager
    if chassis_manager:
        # Add the slot mappings from chassis manager to local copy
        chassis_slots_map = chassis_manager.chassis_slots_map
        # Connect to the chassis updated signal
        chassis_manager.chassis_updated.connect(func(parts): 
            attached_parts = parts
            emit_signal("chassis_updated", parts)
        )




# Set up the UI elements
func setup_ui():
    # Connect button if needed
    if end_phase_button and not end_phase_button.pressed.is_connected(Callable(self, "_on_end_phase_button_pressed")):
        end_phase_button.pressed.connect(Callable(self, "_on_end_phase_button_pressed"))
    
    # Connect clear chassis button if needed
    if clear_chassis_button and not clear_chassis_button.pressed.is_connected(Callable(self, "_on_clear_chassis_button_pressed")):
        clear_chassis_button.pressed.connect(Callable(self, "_on_clear_chassis_button_pressed"))
    
    # Initialize UI labels with default values
    if energy_label:
        energy_label.text = "Energy: 0/0"
    
    if heat_label:
        heat_label.text = "Heat: 0/0"

# Check and discard any cards on slots with 0 or lower durability
func check_and_discard_broken_parts():
    if not chassis_manager or not chassis_manager.attached_parts:
        return
        
    var parts_to_discard = []
    
    # Check each slot for parts with zero durability
    for slot_name in chassis_manager.attached_parts:
        var part = chassis_manager.attached_parts[slot_name]
        
        if part is Card:
            # Check if card has 0 or lower durability
            if part.data.has("durability") and int(part.data.durability) <= 0:
                print("Discarding broken part from slot: ", slot_name)
                parts_to_discard.append({
                    "slot": slot_name,
                    "part": part
                })
        elif part is Array:
            # Check scrapper array
            var cards_to_remove = []
            for card in part:
                if card is Card and card.data.has("durability") and int(card.data.durability) <= 0:
                    cards_to_remove.append(card)
            
            # Remove broken cards from scrapper
            for card in cards_to_remove:
                part.erase(card)
                print("Discarding broken part from scrapper")
                # Send directly to discard pile if available
                if deck_manager and deck_manager.has_method("discard_card"):
                    deck_manager.discard_card(card)
                else:
                    card.queue_free()
    
    # Remove broken parts from regular slots
    for item in parts_to_discard:
        var slot_name = item["slot"]
        var part = item["part"]
        
        # Remove from chassis
        chassis_manager.attached_parts.erase(slot_name)
        
        # Clear slot UI
        var slot = chassis_manager.chassis_slots_map[slot_name]
        if slot and slot.has_method("clear_part"):
            slot.clear_part()
        
        # Send to discard pile
        if deck_manager and deck_manager.has_method("discard_card"):
            deck_manager.discard_card(part)
        else:
            part.queue_free()
    
    # Update UI if any parts were discarded
    if parts_to_discard.size() > 0 or chassis_manager.attached_parts.has("scrapper"):
        chassis_manager.emit_signal("chassis_updated", chassis_manager.attached_parts)

# Initialize the build phase
func start_build_phase():
    # Check for broken parts and discard them
    check_and_discard_broken_parts()
    
    # Initialize turn manager for energy
    if turn_manager:
        turn_manager.initialize()
    
    # Initialize deck container visual
    setup_deck_container()
    
    # Clear hand
    hand_manager.clear_hand()
    
    # Update UI
    update_ui()
    
    # Start drawing cards sequentially with delay
    hand_manager.start_sequential_card_draw()
    
    # Connect signals for all cards after a short delay to ensure they're created
    await get_tree().create_timer(0.5).timeout
    connect_card_signals()

# Setup the visual deck container
func setup_deck_container():
    if not deck_container:
        return
    
    # Clear existing deck visuals
    for child in deck_container.get_children():
        child.queue_free()
    
    # Create deck stack visual
    create_deck_stack_visual()

# Create visual representation of the deck stack
func create_deck_stack_visual():
    if not deck_container or not deck_manager:
        return
    
    # Create a stack of card backs to represent the deck
    var deck_status = deck_manager.get_deck_status()
    var total_cards = deck_status.deck_size + deck_status.discard_size
    
    # Create main deck visual (a stack of card backs)
    var deck_visual = ColorRect.new()
    deck_visual.name = "DeckStack"
    deck_visual.color = Color(0.2, 0.3, 0.5, 0.8)  # Dark blue for deck
    deck_visual.size = Vector2(100, 150)
    deck_visual.position = Vector2(10, 10)
    
    # Add deck count label
    var count_label = Label.new()
    count_label.name = "DeckCount"
    count_label.text = str(total_cards)
    count_label.position = Vector2(35, 60)
    count_label.add_theme_font_size_override("font_size", 24)
    deck_visual.add_child(count_label)
    
    # Add deck title label
    var title_label = Label.new()
    title_label.name = "DeckTitle"
    title_label.text = "DECK"
    title_label.position = Vector2(30, 10)
    title_label.add_theme_font_size_override("font_size", 14)
    deck_visual.add_child(title_label)
    
    # Make deck clickable for drawing cards
    deck_visual.mouse_filter = Control.MOUSE_FILTER_STOP
    deck_visual.gui_input.connect(_on_deck_clicked)
    
    deck_container.add_child(deck_visual)

# Draw chassis slots (this is now more of a visual function)
func draw_chassis_slots():
    # We don't need to create slots since they're now exported controls
    # Just add some visual indicators if needed
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
    pass

# Handle energy changes for the energy bar
func _on_energy_changed_bar(current: int, maximum: int):
    if energy_bar:
        energy_bar.set_energy(current, maximum)
    
    # Update card affordability in hand
    hand_manager.update_card_affordability(current)

# Handle chassis updates for heat calculation
func _on_chassis_updated_heat(_attached_parts_dict: Dictionary):
    _update_heat_display()

# Calculate and update heat display
func _update_heat_display():
    if not heat_bar or not chassis_manager:
        return
    
    # Get heat values from chassis manager
    var heat_data = chassis_manager.calculate_heat()
    
    # Update the heat bar
    heat_bar.set_heat(heat_data.needed_heat, heat_data.scrapper_heat, heat_data.max_heat)

# Handle button press to end the build phase
func _on_end_phase_button_pressed():
    # Build robot and start combat through TurnManager
    if turn_manager and turn_manager.has_method("build_robot_and_start_combat"):
        turn_manager.build_robot_and_start_combat(self, game_manager)
    else:
        # Fallback to old behavior
        emit_signal("combat_requested")

# Handle button press to clear all chassis parts
func _on_clear_chassis_button_pressed():
    # Use chassis manager to clear parts
    var returned_cards = chassis_manager.clear_all_chassis_parts()
    
    # Return all cards to hand
    for card in returned_cards:
        await hand_manager.return_card_to_hand(card)

# Update the deck visual counter
func update_deck_visual():
    if not deck_container:
        return
    
    var deck_stack = deck_container.get_node_or_null("DeckStack")
    if not deck_stack:
        return
    
    var count_label = deck_stack.get_node_or_null("DeckCount")
    if not count_label:
        return
        
    # Update the card count
    if deck_manager:
        var deck_status = deck_manager.get_deck_status()
        var total_cards = deck_status.deck_size + deck_status.discard_size
        count_label.text = str(total_cards)
    
# Handle when a card is drawn
func _on_card_drawn(card):
    if card:
        # Connect signals for the new card
        if card.has_signal("drop_attempted"):
            if not card.drop_attempted.is_connected(Callable(self, "_handle_card_drop")):
                card.drop_attempted.connect(Callable(self, "_handle_card_drop"))
                print("Connected drop_attempted signal for newly drawn card")
            
        if card.has_signal("drag_started"):
            if not card.drag_started.is_connected(Callable(self, "_handle_card_drag")):
                card.drag_started.connect(Callable(self, "_handle_card_drag"))
                print("Connected drag_started signal for newly drawn card")
        
        # Update the deck visual after drawing
        update_deck_visual()

# Connect signals for all cards in hand
func connect_card_signals():
    if hand_manager and hand_manager.cards_in_hand:
        for card in hand_manager.cards_in_hand:
            if card and card.has_signal("drop_attempted"):
                # Connect drop_attempted signal to _handle_card_drop if not already connected
                if not card.drop_attempted.is_connected(Callable(self, "_handle_card_drop")):
                    card.drop_attempted.connect(Callable(self, "_handle_card_drop"))
                    print("Connected drop_attempted signal for card: ", card.data.name if card.data.has("name") else "Unknown")
                
                # Connect drag_started signal if it exists and not already connected
                if card.has_signal("drag_started") and not card.drag_started.is_connected(Callable(self, "_handle_card_drag")):
                    card.drag_started.connect(Callable(self, "_handle_card_drag"))
                    print("Connected drag_started signal for card")

# Handle deck container clicks to draw cards
func _on_deck_clicked(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        hand_manager.draw_single_card()
        update_deck_visual()

# Handle card drop event - delegate to chassis_manager
func _handle_card_drop(card, drop_pos, target = null):
    print("BuildView: Handling card drop at position: ", drop_pos)
    
    # Check if we're already processing this card to prevent recursion
    if card.has_meta("being_processed_by_buildview"):
        print("BuildView: Preventing recursive card drop handling")
        return
    
    # Set guard flag
    card.set_meta("being_processed_by_buildview", true)
    
    if chassis_manager:
        chassis_manager.handle_card_drop(card, drop_pos, target)
    else:
        print("ERROR: chassis_manager is null in _handle_card_drop")
    _update_heat_display()  # Update heat display after card is handled
    
    # Remove guard flag
    card.remove_meta("being_processed_by_buildview")

# Handle card drag event - delegate to chassis_manager
func _handle_card_drag(card):
    print("BuildView: Handling card drag")
    if chassis_manager:
        chassis_manager.handle_card_drag(card)
    else:
        print("ERROR: chassis_manager is null in _handle_card_drag")

# Return card to hand - delegate to hand_manager
func _return_card_to_hand(card):
    return hand_manager.return_card_to_hand(card)
