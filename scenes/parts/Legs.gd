extends Part
class_name Legs

# Special leg functionality
var speed_bonus_percent = 0.0  # Movement speed bonus percentage
var dodge_chance = 0.0         # Chance to dodge attacks
var stability = 0.0            # Reduces knockback effects
var dodge_cooldown = 0.0       # Cooldown for dodge abilities
var knockback_resistance = 0.0 # Resistance to knockback as percentage

var dodge_timer = 0.0

func _init():
	type = "legs"

func _process(delta):
	# Process dodge cooldowns
	if dodge_timer > 0:
		dodge_timer -= delta

func activate():
	# Generate heat when used
	if is_instance_valid(get_parent()) and get_parent().has_method("add_heat"):
		get_parent().add_heat(heat_generation)

# Apply movement modifiers to parent robot
func apply_movement_modifiers():
	var parent = get_parent()
	if not is_instance_valid(parent):
		return
	
	# Apply speed bonus
	if speed_bonus_percent != 0 and "move_speed" in parent:
		var base_speed = parent.move_speed / (1 + speed_bonus_percent / 100.0)  # Reverse any previous application
		parent.move_speed = base_speed * (1 + speed_bonus_percent / 100.0)

# Check if an attack is dodged
func try_dodge() -> bool:
	if dodge_chance <= 0 or dodge_timer > 0:
		return false
		
	var roll = randf()
	if roll < dodge_chance:
		# Successful dodge
		dodge_timer = dodge_cooldown  # Start cooldown
		return true
		
	return false

# Handle knockback resistance
func calculate_knockback_resistance() -> float:
	return knockback_resistance / 100.0
