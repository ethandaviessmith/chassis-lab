extends Node2D
class_name Part_bac

var id: String
var part_name: String
var type: String  # "head", "core", "arm", "leg", "utility"
var cost: int
var heat_generation: int
var durability: int
var max_durability: int
var effects: Array
var rarity: String
var description: String

var sprite: Texture2D
var is_enhanced: bool = false
var is_exhausted: bool = false

signal durability_changed(new_value)
signal part_broken

func _ready():
	update_visuals()

func initialize_from_data(data: Dictionary):
	id = data.id
	part_name = data.name
	type = data.type
	cost = data.cost
	heat_generation = data.heat
	durability = data.durability
	max_durability = data.durability
	rarity = data.rarity
	description = data.description
	
	# Load effects
	effects = []
	for effect_data in data.effects:
		effects.append(effect_data)
	
	# Load sprite if specified
	if "image" in data and data.image != "":
		sprite = load(data.image)

func update_visuals():
	# Update sprite based on part state
	if is_enhanced:
		# Add glow or effect to indicate enhancement
		modulate = Color(1.2, 1.2, 0.8)  # Slightly yellow glow
	
	if is_exhausted:
		# Gray out to indicate exhausted
		modulate = Color(0.5, 0.5, 0.5)

func enhance(heat_used: int):
	# Apply heat-based enhancement
	is_enhanced = true
	is_exhausted = true
	
	# Enhance effects based on heat used
	for effect in effects:
		if "value" in effect and typeof(effect.value) == TYPE_INT:
			effect.value += heat_used
	
	update_visuals()

func reduce_durability(amount: int = 1):
	durability -= amount
	emit_signal("durability_changed", durability)
	
	if durability <= 0:
		emit_signal("part_broken")
	
	update_visuals()

func restore_durability(amount: int):
	durability = min(durability + amount, max_durability)
	emit_signal("durability_changed", durability)
	update_visuals()

func is_broken() -> bool:
	return durability <= 0
	
# Called when the part is used in combat
# Override in derived classes
func activate():
	pass
