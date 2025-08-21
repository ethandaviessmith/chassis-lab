extends Node
class_name TurnManager

signal energy_changed(new_value, max_value)
signal turn_started
signal turn_ended
signal part_durability_changed(part, new_durability)

var current_energy: int = 0
var max_energy: int = 4  # Default 4 energy per turn

# UI References (can be set from BuildView or Main scene)
var energy_label: Label = null

# References - set these in the editor
@export var robot_frame: RobotFrame = null
@export var robot_fighter: PlayerRobot = null
@export var enemy_manager: EnemyManager = null
@export var stat_manager: StatManager = null
@export var build_view: BuildView = null
@export var chassis_manager: ChassisManager
@export var deck_manager: DeckManager
@export var hand_manager: HandManager

func _ready():
    # Initialize energy for the first turn (but don't start turn yet)
    current_energy = max_energy
    _update_energy_display()
    
    # Connect to robot frame signals for real-time visual updates
    if robot_frame:
        robot_frame.connect("robot_frame_updated", _on_robot_frame_updated)
        print("TurnManager: Connected to robot_frame signals")
    
    # Try to find and connect to BuildView
    call_deferred("_connect_to_build_view")
    
    if build_view:
        build_view.connect("robot_frame_updated", _on_robot_frame_updated)
        build_view.connect("chassis_updated", _on_chassis_updated)
        print("TurnManager: Connected to BuildView signals")

    # Request next enemy from enemy manager
    if enemy_manager:
        enemy_manager.determine_next_enemy()

func initialize():
    # Call this to start the first turn properly
    start_turn()

# Handle real-time robot frame updates
func _on_robot_frame_updated():
    print("TurnManager: Robot frame updated - triggering visual refresh")
    # This gets called whenever the robot frame changes
    # We can add visual effects or animations here if needed

# Handle chassis updates from BuildView
func _on_chassis_updated(attached_parts):
    print("TurnManager: Chassis updated, refreshing robot visuals...")
    update_robot_visuals(attached_parts)

# Update robot visuals in real-time
func update_robot_visuals(attached_parts):
    # Update visual robot frame
    if robot_frame:
        robot_frame.build_robot_visuals(attached_parts)
    else:
        print("Warning: No RobotFrame assigned for visual updates")

func set_energy_label(label: Label):
    energy_label = label
    _update_energy_display()

func start_turn():
    # Reset energy to max at start of turn
    current_energy = max_energy
    emit_signal("energy_changed", current_energy, max_energy)
    _update_energy_display()
    emit_signal("turn_started")


func end_turn():
    emit_signal("turn_ended")
    start_turn()

func spend_energy(amount: int) -> bool:
    if amount > current_energy:
        print("Not enough energy! Need: ", amount, ", Have: ", current_energy)
        return false
    
    current_energy -= amount
    emit_signal("energy_changed", current_energy, max_energy)
    _update_energy_display()
    print("Spent ", amount, " energy. Remaining: ", current_energy)
    return true

func gain_energy(amount: int):
    var old_energy = current_energy
    current_energy = min(current_energy + amount, max_energy)  # Cap at max
    var actual_gained = current_energy - old_energy
    emit_signal("energy_changed", current_energy, max_energy)
    _update_energy_display()
    print("Gained ", actual_gained, " energy (", amount, " requested). Energy: ", old_energy, " -> ", current_energy)

func reset_energy():
    # Reset energy to maximum (useful for clearing chassis)
    var old_energy = current_energy
    current_energy = max_energy
    emit_signal("energy_changed", current_energy, max_energy)
    _update_energy_display()
    print("Energy reset from ", old_energy, " to ", current_energy, " (max)")

func set_max_energy(new_max: int):
    max_energy = new_max
    current_energy = min(current_energy, max_energy)  # Adjust current if over new max
    emit_signal("energy_changed", current_energy, max_energy)
    _update_energy_display()

func _update_energy_display():
    if energy_label:
        energy_label.text = "Energy: " + str(current_energy) + "/" + str(max_energy)

# Build robot before combat begins
func build_robot_and_start_combat(view_instance, game_manager = null):
    print("Building robot from chassis...")
    
    # Get attached parts from BuildView
    var attached_parts = view_instance.attached_parts
    
    if not robot_frame and not robot_fighter:
        print("Error: No robot components assigned! Please set robot_frame and robot_fighter in the editor.")
        return
    
    # Build visual robot in the frame (for animation)
    if robot_frame:
        robot_frame.build_robot_visuals(attached_parts)
    else:
        print("Warning: No RobotFrame assigned, visual building will be skipped")
    
    # Build combat robot stats
    if robot_fighter:
        robot_fighter.build_from_chassis(attached_parts)
    else:
        print("Warning: No RobotFighter assigned, combat stats will not be updated")
    
    # Process scrapper parts - decrease durability by 1 for all cards in scrapper slots
    _process_scrapper_parts()
    
    # Track discard completion with a boolean flag
    var cards_discarded = false
    var scrapper_processed = false
    
    # Show a "Preparing for Combat..." message to indicate the transition
    var preparing_label = _show_preparing_for_combat_message(view_instance)
    
    # Discard remaining hand cards before combat
    if hand_manager and hand_manager.has_method("discard_hand"):
        print("TurnManager: Discarding remaining hand cards before combat...")
        hand_manager.discard_hand()
        # We'll add a short delay to allow animations to complete
        await get_tree().create_timer(0.7).timeout
        cards_discarded = true
    else:
        print("TurnManager: No HandManager found or missing discard_hand method")
        cards_discarded = true
    
    # Ensure all scrapper cards are properly processed with a visual delay
    await get_tree().create_timer(0.5).timeout
    scrapper_processed = true
    
    # Wait for both operations to complete
    if !cards_discarded or !scrapper_processed:
        await get_tree().process_frame
    
    # Remove the "Preparing" message if it exists
    if is_instance_valid(preparing_label) and preparing_label.is_inside_tree():
        preparing_label.queue_free()
    
    # Switch background music to combat mode
    

    print("Robot build complete! Starting combat phase...")
    
    # Tell GameManager to start combat phase
    if game_manager and game_manager.has_method("start_combat_phase"):
        game_manager.start_combat_phase()
    else:
        print("Warning: No GameManager provided or missing start_combat_phase method")
        
# Process cards in scrapper slots before combat
func _process_scrapper_parts():
    if not chassis_manager:
        print("TurnManager: No chassis_manager, cannot process scrapper parts")
        return
        
    # Get a safe copy of the scrapper cards array
    var scrapper_cards = chassis_manager.get_scrapper_cards()
    print("TurnManager: Processing " + str(scrapper_cards.size()) + " scrapper cards")

    var cards_to_discard = []
    
    # First pass - update durability for all cards
    for card in scrapper_cards:
        if !is_instance_valid(card):
            print("TurnManager: Invalid card detected in scrapper - skipping")
            continue
            
        # Ensure card has a unique instance ID for tracking
        var instance_id = card.data.get("instance_id", "")
        if instance_id == "" and deck_manager:
            # Generate a new unique ID
            instance_id = "card_" + str(randi()) + "_" + str(Time.get_unix_time_from_system())
            card.data["instance_id"] = instance_id
            # Register card if not already
            deck_manager.register_card(instance_id, card.data, card)
            
        # Decrease durability
        var current_durability = card.data.get("durability", 1)
        current_durability -= 1
        
        # Update durability in the registry and card
        if deck_manager:
            deck_manager.update_card_durability(instance_id, current_durability)
            
        # Check if card is destroyed
        if current_durability <= 0:
            print("TurnManager: Scrapper part destroyed - marking for discard")
            cards_to_discard.append(card)
        else:
            # Ensure card data reflects current durability
            card.data["durability"] = current_durability
            part_durability_changed.emit(card, current_durability)
            print("TurnManager: Scrapper durability reduced to ", current_durability)

    # Second pass - discard destroyed cards
    # Process separately to avoid modifying array during iteration
    for card in cards_to_discard:
        if is_instance_valid(card):
            print("TurnManager: Discarding destroyed scrapper part")
            # First remove from chassis to update the UI
            chassis_manager.discard_scrapper_card(card)
            # Then add to discard pile
            if deck_manager:
                deck_manager.discard_card(card)
    

# Show a "Preparing for combat" message during the transition
func _show_preparing_for_combat_message(view_node) -> Label:
    # Create a new label for the transition message
    var label = Label.new()
    label.name = "PreparingForCombatLabel"
    label.text = "PREPARING FOR COMBAT..."
    label.add_theme_font_size_override("font_size", 24)
    label.add_theme_color_override("font_color", Color(1, 0.8, 0.2)) # Yellow-ish color
    
    # Position it in the center of the screen
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.size = Vector2(400, 100)
    label.position = Vector2(
        (view_node.get_viewport_rect().size.x - label.size.x) / 2,
        (view_node.get_viewport_rect().size.y - label.size.y) / 2
    )
    
    # Add a pulsing animation effect
    var tween = view_node.create_tween()
    tween.tween_property(label, "modulate:a", 0.5, 0.5)
    tween.tween_property(label, "modulate:a", 1.0, 0.5)
    tween.set_loops()
    
    # Add to the view
    view_node.add_child(label)
    
    return label
