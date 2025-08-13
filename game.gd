extends Node

@export var game_manager: GameManager

func _ready() -> void:
    if game_manager:
        game_manager.start_new_game()
