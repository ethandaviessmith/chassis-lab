extends Control
class_name BuildView

signal combat_requested()
signal chassis_updated(attach_part)

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

# Info panels
@export var stat_display: StatDisplay
@export var enemy_display: NextEnemyDisplay

# Managers for info panels
@export var stat_manager: StatManager
@export var enemy_manager: EnemyManager

# Card container
@export var hand_container: Container
@export var deck_control: DeckControl

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
        
        # Initialize heat bar with starting values (2 default heat)
        if chassis_manager:
            var heat_data = chassis_manager.calculate_heat()
            heat_bar.set_heat(heat_data.needed_heat, heat_data.scrapper_heat, heat_data.max_heat)
        else:
            # Fallback if chassis manager isn't available yet
            heat_bar.set_heat(0, 2, 10)
    
    # Setup UI elements
    setup_ui()
    
    # Initialize the build phase
    start_build_phase()

    # Setup info panels
    setup_info_panels()
    
# Setup the info panels for stats and next enemy
func setup_info_panels():
    # Setup stat display panel
    if stat_display and stat_manager:
        # Make sure the stat display is properly configured
        if stat_display.has_method("_ready"):
            if not stat_display.stat_manager:
                stat_display.stat_manager = stat_manager
        
        # Initialize stats display with current stats
        if stat_manager.has_method("get_current_stats"):
            var current_stats = stat_manager.get_current_stats()
            # Use the update_display method directly if it exists
            if stat_display.has_method("update_display"):
                stat_display.update_display(current_stats)
            # Otherwise emit the stats_updated signal for the stat display to catch
            elif stat_manager.has_method("_on_chassis_updated") and chassis_manager:
                stat_manager._on_chassis_updated(chassis_manager.attached_parts)
    
    # Setup enemy display panel
    if enemy_display and enemy_manager:
        # Make sure the enemy display is properly configured
        if enemy_display.has_method("_ready"):
            if not enemy_display.enemy_manager:
                enemy_display.enemy_manager = enemy_manager

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
    if not deck_control:
        return
    
    # Connect deck_manager to deck_control
    if deck_control and deck_manager:
        deck_control.deck_manager = deck_manager

# This function is no longer needed as DeckControl handles this now
func create_deck_stack_visual():
    pass  # Functionality moved to DeckControl

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
    
    # Update the heat bar - include default heat value
    heat_bar.set_heat(heat_data.needed_heat, heat_data.scrapper_heat, heat_data.max_heat)

# Handle button press to end the build phase
func _on_end_phase_button_pressed():
    # First check if there's enough heat to build the robot
    if chassis_manager and not chassis_manager.has_enough_heat():
        # Not enough heat - show warning message
        _show_not_enough_heat_warning()
        return
        
    # We have enough heat, proceed to combat
    if turn_manager and turn_manager.has_method("build_robot_and_start_combat"):
        turn_manager.build_robot_and_start_combat(self, game_manager)
        Sound.play_error()
    else:
        # Fallback to old behavior
        Sound.play_robot_power()
        emit_signal("combat_requested")

# Show a warning when there isn't enough heat to build
func _show_not_enough_heat_warning():
    # Check if we already have a warning label
    var existing_warning = find_child("NotEnoughHeatWarning", false)
    if existing_warning:
        # Refresh the existing warning (flash it)
        existing_warning.modulate = Color(1, 0, 0, 1)  # Bright red
        
        # Create a tween to fade out the warning
        var existing_tween = create_tween()
        existing_tween.tween_property(existing_warning, "modulate:a", 0.7, 0.5)
        return
    
    # Create a new warning label
    var warning_label = Label.new()
    warning_label.name = "NotEnoughHeatWarning"
    warning_label.text = "NOT ENOUGH HEAT TO BUILD"
    warning_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2)) # Red color
    warning_label.add_theme_font_size_override("font_size", 24) # Larger font
    
    # Position it near the heat bar or at a prominent location
    if heat_bar:
        warning_label.global_position = heat_bar.global_position + Vector2(0, -40)
    else:
        # Fallback position in the upper part of the screen
        warning_label.global_position = Vector2(get_viewport_rect().size.x / 2, 100)
        warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    
    add_child(warning_label)
    
    # Make it pulsate to draw attention
    var tween = create_tween()
    tween.tween_property(warning_label, "modulate:a", 0.7, 0.5)
    tween.tween_property(warning_label, "modulate:a", 1.0, 0.5)
    tween.set_loops(3)
    
    # Remove after a few seconds
    await get_tree().create_timer(3.0).timeout
    if is_instance_valid(warning_label) and warning_label.is_inside_tree():
        warning_label.queue_free()

# Handle button press to clear all chassis parts
func _on_clear_chassis_button_pressed():
    Sound.play_click()
    # Use chassis manager to clear parts
    var returned_cards = chassis_manager.clear_all_chassis_parts()
    
    # Return all cards to hand
    for card in returned_cards:
        await hand_manager.return_card_to_hand(card)

# This function is no longer needed as DeckControl handles deck display
func update_deck_visual():
    # Functionality moved to DeckControl which automatically updates
    pass
    
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
        
        # Deck visuals are automatically updated by DeckControl now

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

# This function is no longer needed as DeckControl handles deck interaction
func _on_deck_clicked(_event):
    pass # Functionality moved to DeckControl

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
