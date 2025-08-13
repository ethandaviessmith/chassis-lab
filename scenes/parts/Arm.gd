extends Part
class_name Arm

# Special arm functionality
var damage = 0        # Base damage
var fire_rate = 1.0   # Attacks per second
var range = 200.0     # Attack range
var pierce = 0        # Number of targets to pierce
var effect_type = ""  # Special effect type (bleed, stagger, etc)
var effect_value = 0  # Value for the effect

var attack_timer = 0.0

func _init():
	type = "arm"

func _process(delta):
	if is_instance_valid(get_parent()) and get_parent().has_method("is_defeated") and not get_parent().is_defeated():
		attack_timer += delta
		
		# Auto-attack when timer expires
		if attack_timer >= 1.0 / fire_rate:
			attack_timer = 0.0
			attack()

func attack():
	if is_exhausted or is_broken():
		return
		
	# Find valid target
	var target = find_target()
	if not target:
		return
		
	# Apply damage
	deal_damage(target)
	
	# Generate heat
	if is_instance_valid(get_parent()) and get_parent().has_method("add_heat"):
		get_parent().add_heat(heat_generation)

func find_target():
	var parent = get_parent()
	if not is_instance_valid(parent) or not parent.has_method("find_target"):
		return null
	
	# Get target from parent robot
	return parent.find_target()

func deal_damage(target):
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	
	# Apply damage modifiers
	var final_damage = damage
	
	# Check for crit if robot has head
	var parent = get_parent()
	if is_instance_valid(parent) and parent.head and parent.head.has_method("calculate_crit"):
		if parent.head.calculate_crit():
			final_damage = int(final_damage * 1.5)  # 50% crit bonus
	
	# Deal damage
	var combat_resolver = get_node("/root/Managers/CombatResolver")
	if combat_resolver:
		combat_resolver.apply_damage(get_parent(), target, final_damage)
	else:
		# Fallback if resolver not available
		target.take_damage(final_damage)
	
	# Apply special effects
	apply_special_effect(target)
	
	# Handle pierce
	if pierce > 0:
		# Find additional targets
		# This is simplified - would need more complex targeting in a full implementation
		pass

func apply_special_effect(target):
	if not effect_type or effect_type == "" or effect_value <= 0:
		return
		
	match effect_type:
		"bleed":
			# Apply bleed damage over time
			# Would need a proper DoT system
			pass
		"stagger":
			# Reduce target movement speed temporarily
			if target.has_method("apply_status_effect"):
				target.apply_status_effect("stagger", effect_value, 2.0)  # 2 sec duration
		"armor_shred":
			# Reduce target armor temporarily
			if target.has_method("modify_armor"):
				target.modify_armor(-effect_value, 3.0)  # 3 sec duration
