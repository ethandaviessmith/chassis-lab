extends Part
class_name Core

# Special core functionality
var energy_regen = 0  # Energy regenerated per round
var heat_dissipation = 0  # Heat reduced per round
var bonus_armor = 0  # Additional armor

func _init():
	type = "core"

func activate():
	var parent = get_parent()
	if not is_instance_valid(parent):
		return
	
	# Core passive effects
	if energy_regen > 0 and parent.has_method("heal"):
		parent.heal(energy_regen)
		
	if heat_dissipation > 0 and parent.has_method("reduce_heat"):
		parent.reduce_heat(heat_dissipation)

# Process heat dissipation at end of combat round
func process_end_of_round():
	# Apply additional effects at end of round
	var parent = get_parent()
	if is_instance_valid(parent) and heat_dissipation > 0 and parent.has_method("reduce_heat"):
		parent.reduce_heat(heat_dissipation)
