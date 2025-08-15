extends Node

@export var game_manager: GameManager
@export var help_system: Node # Reference to our help system

func _ready() -> void:
    if game_manager:
        game_manager.start_new_game()
    
    # Initialize help system
    if help_system:
        # Show the help button after a short delay to let the game initialize
        await get_tree().create_timer(0.5).timeout
        help_system.show_help_button()
