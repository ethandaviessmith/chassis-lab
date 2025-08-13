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
@export var build_view: Control
@export var combat_view: CombatView
@export var reward_screen: RewardScreen
@export var data_loader: DataLoader

func _ready():
    # Connect signals when components are available
    if build_view and build_view.has_signal("combat_requested"):
        build_view.combat_requested.connect(_on_combat_requested)
    
    if combat_view:
        combat_view.combat_finished.connect(_on_combat_ended)
        combat_view.show_reward_screen.connect(_on_show_reward_screen)
    
    if reward_screen:
        reward_screen.continue_to_next_encounter.connect(_on_continue_to_next_encounter)
    
    # Start new game
    start_new_game()

func start_new_game():
    current_encounter = 0
    victory = false
    emit_signal("game_started")
    start_build_phase()

func start_build_phase():
    current_state = GameState.BUILD
    
    # Show build view, hide others
    build_view.visible = true
    combat_view.visible = false
    reward_screen.visible = false
    
    # Reset turn state
    turn_manager.start_turn()
    
    emit_signal("build_phase_started")

func start_combat_phase():
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
    if reward_screen:
        reward_screen.visible = true
        reward_screen.show_rewards(true)  # Always victory if we reach rewards
    
    emit_signal("reward_phase_started")

func advance_to_next_encounter():
    current_encounter += 1
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
    
    # Show game over screen (implement later)
    # For now, restart the game
    await get_tree().create_timer(2.0).timeout
    start_new_game()

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
        # Victory leads to rewards
        start_reward_phase()
    else:
        # Defeat ends the game
        end_game(false)

func _on_show_reward_screen():
    # Called by CombatView when victory is achieved
    print("GameManager: Combat view requesting reward screen")
    start_reward_phase()

func _on_continue_to_next_encounter():
    # Called by RewardScreen when player selects a reward and continues
    print("GameManager: Continuing to next encounter")
    
    # Add selected card to deck
    if reward_screen and deck_manager:
        var selected_reward = reward_screen.get_selected_reward()
        if selected_reward.size() > 0:
            deck_manager.add_card_to_deck(selected_reward)
            print("GameManager: Added reward card to deck: ", selected_reward.get("name", "Unknown"))
    
    # Hide reward screen
    if reward_screen:
        reward_screen.hide_screen()
    
    # Advance to next encounter
    advance_to_next_encounter()
