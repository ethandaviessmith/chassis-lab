extends Node
class_name Main

func _ready():
	print("Chassis Lab - Game Initialized")
	
	# Initialize Managers
	$Managers/GameManager.start_new_game()
