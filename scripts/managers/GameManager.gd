extends Node
class_name GameManager

# Game state enum - make it publicly accessible
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

# CENTRAL MANAGER: Centralized game state handling
func change_game_state(new_state: GameState):
    var old_state = current_state
    
    if old_state == new_state:
        print("GameManager: Already in state ", _state_to_string(new_state))
        return
        
    print("GameManager: Changing state from ", _state_to_string(old_state), 
          " to ", _state_to_string(new_state))
    
    # Handle exit logic for old state
    match old_state:
        GameState.BUILD:
            emit_signal("build_phase_ended")
        GameState.COMBAT:
            emit_signal("combat_phase_ended")
        GameState.REWARD:
            # Any cleanup needed when leaving reward phase
            pass
    
    # Update the current state
    current_state = new_state
    
    # Handle enter logic for new state
    match new_state:
        GameState.BUILD:
            _setup_build_phase()
            emit_signal("build_phase_started")
        GameState.COMBAT:
            _setup_combat_phase()
            emit_signal("combat_phase_started")
        GameState.REWARD:
            _setup_reward_phase()
            emit_signal("reward_phase_started")
        GameState.GAME_OVER:
            # Game over handling remains in end_game function
            pass

# Helper function to convert state enum to string for debugging
func _state_to_string(state: GameState) -> String:
    match state:
        GameState.BUILD: return "BUILD"
        GameState.COMBAT: return "COMBAT"
        GameState.REWARD: return "REWARD"
        GameState.GAME_OVER: return "GAME_OVER"
        _: return "UNKNOWN"
            
func start_new_game():
    current_encounter = 0
    set_level(1)
    victory = false
    emit_signal("game_started")
    change_game_state(GameState.BUILD)

# DEPRECATED: Use change_game_state(GameState.BUILD) instead
func start_build_phase():
    change_game_state(GameState.BUILD)
    
# Internal method for setting up the build phase
func _setup_build_phase():
    print("GameManager: Setting up build phase")
    
    # Show build view, hide others
    build_view.visible = true
    combat_view.visible = false
    reward_screen.visible = false
    
    # Switch background music to build mode
    Sound.switch_game_mode_music("build")
    
    # Show "Ready to Build" message in green
    var ready_label = _show_ready_to_build_message(build_view)
    
    # IMPORTANT: Let TurnManager handle all turn initialization including card draw
    # This consolidates the logic in one place and avoids duplicate draw calls
    if turn_manager:
        print("GameManager: Delegating build phase initialization to TurnManager")
        turn_manager.initialize()  # This will handle energy reset
        # Now start a new turn which handles card drawing through the proper chain
        turn_manager.start_new_turn()
    else:
        print("GameManager: ERROR - No TurnManager available!")
    
    # Connect card signals in the build view
    if build_view and build_view.has_method("connect_card_signals"):
        build_view.connect_card_signals()
    
    # Clean up the message after a short delay
    var timer = get_tree().create_timer(1.5)
    await timer.timeout
    if is_instance_valid(ready_label) and ready_label.is_inside_tree():
        ready_label.queue_free()

# DEPRECATED: Use change_game_state(GameState.COMBAT) instead
func start_combat_phase():
    change_game_state(GameState.COMBAT)

# Internal method for setting up the combat phase
func _setup_combat_phase():
    print("GameManager: Setting up combat phase")
    
    # Switch background music to combat mode
    Sound.switch_game_mode_music("combat")
    
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

# DEPRECATED: Use change_game_state(GameState.REWARD) instead
func start_reward_phase():
    change_game_state(GameState.REWARD)
    
# Internal method for setting up the reward phase
func _setup_reward_phase():
    print("GameManager: Setting up reward phase")
    
    # Hide combat view, show reward screen
    if combat_view:
        combat_view.visible = false
    if deck_control:
        deck_control.visible = true
    if reward_screen:
        reward_screen.show_rewards(true)

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
        change_game_state(GameState.BUILD)

func end_game(is_victory: bool):
    victory = is_victory
    print("GameManager: Game ended. Victory: ", is_victory)
    change_game_state(GameState.GAME_OVER)
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
        # Prepare robot and chassis for combat
        var success = await turn_manager.prepare_robot_for_combat(build_view)
        if success:
            # Change to combat state if robot preparation succeeded
            change_game_state(GameState.COMBAT)
        # The actual state change now happens here in the GameManager

func _on_combat_ended(player_won: bool):
    print("GameManager: Combat ended. Player won: ", player_won)
    
    if player_won:
        # Change to reward phase on victory
        change_game_state(GameState.REWARD)
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
    change_game_state(GameState.REWARD)

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
