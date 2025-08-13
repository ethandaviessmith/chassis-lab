extends Part
class_name Head

# Special head functionality
var target_bonus = null  # For targeting overrides
var crit_chance = 0.0    # Base crit chance bonus
var sensor_range = 0.0   # Detection range bonus

func _init():
	type = "head"

func activate():
	# Generate heat when used
	if is_instance_valid(get_parent()) and get_parent().has_method("add_heat"):
		get_parent().add_heat(heat_generation)

# Returns the best target based on head functionality
func get_optimal_target(possible_targets: Array):
	if target_bonus == "lowest_hp":
		# Target lowest HP enemy
		var lowest_hp_target = null
		var lowest_hp = INF
		
		for target in possible_targets:
			if target.hp < lowest_hp:
				lowest_hp = target.hp
				lowest_hp_target = target
				
		return lowest_hp_target
	
	# Default targeting
	return null if possible_targets.size() == 0 else possible_targets[0]

# Calculate if an attack crits
func calculate_crit() -> bool:
	return randf() < crit_chance
