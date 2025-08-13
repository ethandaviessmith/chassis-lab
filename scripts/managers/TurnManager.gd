extends Node
class_name TurnManager

signal energy_changed(new_value, max_value)
signal turn_started
signal turn_ended

var current_energy: int = 0
var max_energy: int = 4  # Default 4 energy per turn

# UI References (can be set from BuildView or Main scene)
var energy_label: Label = null

func _ready():
    # Initialize energy for the first turn (but don't start turn yet)
    current_energy = max_energy
    _update_energy_display()

func initialize():
    # Call this to start the first turn properly
    start_turn()

func set_energy_label(label: Label):
    energy_label = label
    _update_energy_display()

func start_turn():
    # Reset energy to max at start of turn
    current_energy = max_energy
    emit_signal("energy_changed", current_energy, max_energy)
    _update_energy_display()
    emit_signal("turn_started")
    
    # Draw new hand
    var deck_manager = get_node_or_null("../DeckManager")
    if deck_manager:
        deck_manager.draw_hand()

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

func set_max_energy(new_max: int):
    max_energy = new_max
    current_energy = min(current_energy, max_energy)  # Adjust current if over new max
    emit_signal("energy_changed", current_energy, max_energy)
    _update_energy_display()

func _update_energy_display():
    if energy_label:
        energy_label.text = "Energy: " + str(current_energy) + "/" + str(max_energy)
