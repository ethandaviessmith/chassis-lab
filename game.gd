extends Node

@export var game_manager: GameManager

func _ready() -> void:
    # Start background music at game launch
    if "Sound" in get_tree().root.get_children():
        var sound = get_tree().root.get_node("Sound")
        if sound.has_method("start_background_music"):
            print("Game: Starting background music")
            sound.start_background_music("build")
    
    if game_manager:
        game_manager.start_new_game()
