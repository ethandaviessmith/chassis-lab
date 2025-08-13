extends Node
class_name TurnManager

signal energy_changed(new_value)
signal turn_started
signal turn_ended

var current_energy: int = 0
var max_energy: int = 3  # Default starting energy per turn

func _ready():
	pass

func start_turn():
	# Reset energy to max at start of turn
	current_energy = max_energy
	emit_signal("energy_changed", current_energy)
	emit_signal("turn_started")
	
	# Draw new hand
	$"../DeckManager".draw_hand()

func end_turn():
	emit_signal("turn_ended")
	start_turn()

func spend_energy(amount: int) -> bool:
	if amount > current_energy:
		return false
	
	current_energy -= amount
	emit_signal("energy_changed", current_energy)
	return true

func gain_energy(amount: int):
	current_energy += amount
	emit_signal("energy_changed", current_energy)

func set_max_energy(new_max: int):
	max_energy = new_max
