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

@onready var deck_manager = $"../DeckManager"
@onready var turn_manager = $"../TurnManager"
@onready var combat_resolver = $"../CombatResolver"
@onready var build_view = $"../../BuildView"
@onready var combat_view = $"../../CombatView"
@onready var reward_screen = $"../../RewardScreen"

func _ready():
    # Connect signals
    build_view.combat_requested.connect(_on_combat_requested)
    combat_resolver.combat_ended.connect(_on_combat_ended)
    
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
    
    # Hide build view, show combat view
    build_view.visible = false
    combat_view.visible = true
    
    # Start combat
    combat_resolver.start_combat(current_encounter)
    
    emit_signal("combat_phase_started")

func start_reward_phase():
    current_state = GameState.REWARD
    
    # Hide combat view, show reward screen
    combat_view.visible = false
    reward_screen.visible = true
    
    # Generate rewards
    var rewards = deck_manager.generate_rewards(3)
    reward_screen.display_rewards(rewards)
    
    emit_signal("reward_phase_started")

func advance_to_next_encounter():
    current_encounter += 1
    
    if current_encounter >= max_encounters:
        # Final boss encounter
        start_build_phase()
    elif current_encounter > max_encounters:
        # Victory!
        end_game(true)
    else:
        # Next regular encounter
        start_build_phase()

func end_game(is_victory: bool):
    current_state = GameState.GAME_OVER
    victory = is_victory
    emit_signal("game_over", victory)
    
    # Show game over screen
    # Implement later

func _on_combat_requested():
    # Called when player hits "Start Combat" button
    emit_signal("build_phase_ended")
    start_combat_phase()

func _on_combat_ended(player_won: bool):
    emit_signal("combat_phase_ended")
    
    if player_won:
        start_reward_phase()
    else:
        end_game(false)

func _on_reward_selected(_card_id: String):
    advance_to_next_encounter()
