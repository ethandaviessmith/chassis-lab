extends Node
class_name GameManager

enum GameState {BUILD, COMBAT, REWARD, GAME_OVER}

signal game_started
signal build_phase_started
signal build_phase_ended
signal combat_phase_started
signal combat_phase_ended
signal reward_phase_started
signal game_over(victory)

var current_state: GameState = GameState.BUILD
var current_encounter: int = 0
var max_encounters: int = 3
var victory: bool = false

# Export references - set these in the editor
@export var deck_manager: DeckManager
@export var turn_manager: TurnManager
@export var hand_manager: HandManager
@export var build_view: Control
@export var combat_view: CombatView
@export var reward_screen: RewardScreen
@export var data_loader: DataLoader
@export var deck_control: DeckControl

@export var level: Label
@export var volume: HSlider

@export var play_music: bool = false

func _ready():


    # Connect signals when components are available
    if build_view and build_view.has_signal("combat_requested"):
        build_view.combat_requested.connect(_on_combat_requested)
    
    if combat_view:
        combat_view.combat_finished.connect(_on_combat_ended)
        combat_view.show_reward_screen.disconnect(_on_show_reward_screen)
        combat_view.show_reward_screen.connect(_on_show_reward_screen)
    
    if reward_screen:
        reward_screen.continue_to_next_encounter.connect(_on_continue_to_next_encounter)
        reward_screen.reward_selected.connect(_on_reward_selected)
    
    if volume:
        volume.value_changed.connect(_on_volume_changed)

    # Start new game
    start_new_game()

    # if play_music:
        # Sound.start_background_music()

func _on_volume_changed(value: float):
    Sound.set_music_volume(value)

func start_new_game():
    current_encounter = 0
    set_level(1)
    victory = false
    emit_signal("game_started")
    start_build_phase()

func start_build_phase():
    current_state = GameState.BUILD
    
    # Show build view, hide others
    build_view.visible = true
    combat_view.visible = false
    reward_screen.visible = false
    
    # Switch background music to build mode
    Sound.switch_game_mode_music("build")
    
    # Reset turn state
    turn_manager.initialize()  # Initialize the turn manager (reset energy)
    
    # Show "Ready to Build" message in green
    var ready_label = _show_ready_to_build_message(build_view)
    
    # Clear and redraw hand for the new build phase
    if hand_manager and hand_manager.has_method("start_sequential_card_draw"):
        print("GameManager: Starting card draw for new build phase...")
        hand_manager.clear_hand()  # Clear existing hand first
        hand_manager.start_sequential_card_draw()  # Draw a new hand
        build_view.connect_card_signals()
    else:
        print("GameManager: No HandManager found or missing card draw methods")
        # Fallback - use turn_manager's start_turn which includes drawing cards
        turn_manager.start_turn()
    
    # Clean up the message after a short delay
    await get_tree().create_timer(1.5).timeout
    if is_instance_valid(ready_label) and ready_label.is_inside_tree():
        ready_label.queue_free()
    
    emit_signal("build_phase_started")

func start_combat_phase():
    Sound.switch_game_mode_music("combat")
    current_state = GameState.COMBAT
    print("GameManager: Starting combat phase")
    
    # Hide build view, show combat view
    if build_view:
        build_view.visible = false
    if combat_view:
        combat_view.visible = true
    
    # Build robot from chassis and start combat
    if turn_manager and build_view and combat_view:
        # Get the robot fighter from turn manager
        var robot_fighter = turn_manager.robot_fighter
        if robot_fighter:
            # Get enemy data for current encounter
            var enemy_data = get_enemy_for_encounter(current_encounter)
            combat_view.start_combat(robot_fighter, enemy_data)
        else:
            print("GameManager: No robot fighter available!")
    else:
        print("GameManager: Missing required components for combat!")
    
    emit_signal("combat_phase_started")

func get_enemy_for_encounter(encounter_num: int) -> Dictionary:
    """Get enemy data based on encounter number"""
    if data_loader:
        var all_enemies = data_loader.get_all_enemies()
        if all_enemies.size() > 0:
            # Cycle through enemies, with boss at the end
            if encounter_num >= max_encounters - 1:
                # Boss encounter
                for enemy in all_enemies:
                    if enemy.get("is_boss", false):
                        return enemy
            else:
                # Regular enemy
                var regular_enemies = []
                for enemy in all_enemies:
                    if not enemy.get("is_boss", false):
                        regular_enemies.append(enemy)
                
                if regular_enemies.size() > 0:
                    return regular_enemies[encounter_num % regular_enemies.size()]
    
    # Fallback enemy data
    return {
        "name": "Test Drone",
        "hp": 8 + (encounter_num * 2),  # Scale with encounter
        "armor": encounter_num,
        "damage": 2 + encounter_num,
        "attack_speed": 1.5,
        "move_speed": 100
    }

func start_reward_phase():
    current_state = GameState.REWARD
    print("GameManager: Starting reward phase")
    
    # Hide combat view, show reward screen
    if combat_view:
        combat_view.visible = false
    if deck_control:
        deck_control.visible = true
    if reward_screen:
        reward_screen.show_rewards(true)
    
    emit_signal("reward_phase_started")

func set_level(lvl:int):
    level.text = "Round 0" + str(lvl)

func advance_to_next_encounter():
    current_encounter += 1
    set_level(current_encounter + 1)
    print("GameManager: Advancing to encounter ", current_encounter)
    
    if current_encounter >= max_encounters:
        # Victory!
        end_game(true)
    else:
        # Next encounter
        start_build_phase()

func end_game(is_victory: bool):
    current_state = GameState.GAME_OVER
    victory = is_victory
    print("GameManager: Game ended. Victory: ", is_victory)
    emit_signal("game_over", victory)
    
    # Show appropriate message based on victory status
    var message_label = null
    if is_victory:
        # Victory message (can be implemented later)
        pass
    else:
        # Defeat message - show "YOU LOSE" in red
        message_label = _show_game_over_message(build_view)
    
    # Show game over screen (implement later)
    # For now, restart the game
    await get_tree().create_timer(2.0).timeout
    
    # Clean up message if it exists
    if is_instance_valid(message_label) and message_label.is_inside_tree():
        message_label.queue_free()
    
    #just reload the scene to restart
    get_tree().reload_current_scene()


# Signal handlers
func _on_combat_requested():
    # Called when player hits "Start Combat" button in BuildView
    print("GameManager: Combat requested from BuildView")
    
    # Build the robot using TurnManager
    if turn_manager and build_view:
        turn_manager.build_robot_and_start_combat(build_view, self)
    
    emit_signal("build_phase_ended")

func _on_combat_ended(player_won: bool):
    print("GameManager: Combat ended. Player won: ", player_won)
    emit_signal("combat_phase_ended")
    
    if player_won:
        # Victory is handled through the show_reward_screen signal
        # Do nothing here, the CombatView will emit show_reward_screen
        pass
    else:
        # Defeat ends the game
        end_game(false)

# Shows a green "READY TO BUILD" message
func _show_ready_to_build_message(view_node) -> Label:
    # Create a new label for the build phase message
    var label = Label.new()
    label.name = "ReadyToBuildLabel"
    label.text = "READY TO BUILD"
    label.add_theme_font_size_override("font_size", 28)
    label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))  # Green color
    
    # Position it in the center of the screen
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.size = Vector2(400, 100)
    label.position = Vector2(
        (view_node.get_viewport_rect().size.x - label.size.x) / 2,
        (view_node.get_viewport_rect().size.y - label.size.y) / 2
    )
    
    # Add a growing/shrinking animation effect
    var tween = view_node.create_tween()
    tween.tween_property(label, "scale", Vector2(1.1, 1.1), 0.5)
    tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.5)
    tween.set_loops()
    
    # Add to the view
    view_node.add_child(label)
    
    return label
    
# Shows a red "YOU LOSE" message
func _show_game_over_message(view_node) -> Label:
    # Create a new label for the game over message
    var label = Label.new()
    label.name = "GameOverLabel"
    label.text = "YOU LOSE"
    label.add_theme_font_size_override("font_size", 40)  # Larger font for impact
    label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))  # Red color
    
    # Position it in the center of the screen
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.size = Vector2(400, 100)
    label.position = Vector2(
        (view_node.get_viewport_rect().size.x - label.size.x) / 2,
        (view_node.get_viewport_rect().size.y - label.size.y) / 2
    )
    
    # Add a shaking animation effect to emphasize defeat
    var tween = view_node.create_tween()
    tween.tween_property(label, "position:x", label.position.x - 10, 0.1)
    tween.tween_property(label, "position:x", label.position.x + 10, 0.1)
    tween.tween_property(label, "position:x", label.position.x, 0.1)
    tween.set_loops(3)  # Shake 3 times
    
    # Add to the view
    view_node.add_child(label)
    
    return label

func _on_show_reward_screen():
    # Called by CombatView when victory is achieved
    print("GameManager: Combat view requesting reward screen")
    start_reward_phase()

func _on_reward_selected(card_data: Dictionary):
    # Called when the player selects a reward card
    print("GameManager: Reward selected: ", card_data.get("name", "Unknown"))
    
    # Add selected card to deck
    if deck_manager and card_data.size() > 0:
        deck_manager.add_card_to_deck(card_data)
        print("GameManager: Added reward card to deck: ", card_data.get("name", "Unknown"))

func _on_continue_to_next_encounter():
    # Called by RewardScreen when player continues to next encounter
    print("GameManager: Continuing to next encounter")
    
    # Advance to next encounter
    advance_to_next_encounter()
