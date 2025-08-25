extends Node
class_name DataLoader

# File paths
const CARDS_PATH = "res://data/cards.json"  # Single source of truth for card data
const ENEMIES_PATH = "res://data/enemies.json"

func _ready():
	pass

func load_all_cards() -> Array:
	var parts = []
	
	print("DataLoader: Loading cards from: ", CARDS_PATH)
	
	# Load cards from the JSON file
	var file = FileAccess.open(CARDS_PATH, FileAccess.READ)
	if file:
		print("DataLoader: Successfully opened cards file")
		var json_text = file.get_as_text()
		file.close()
		
		print("DataLoader: JSON text length: ", json_text.length())
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			var data = json.get_data()
			
			# Convert JSON data to Part objects
			for card_data in data:
				var part = Part.new()
				part.initialize_from_data(card_data)
				parts.append(part)
				
			print("DataLoader: Successfully parsed JSON, created ", parts.size(), " Part objects")
		else:
			print("DataLoader: ERROR - Failed to parse JSON: ", json.error_string)
			push_error("DataLoader: Failed to parse cards.json: " + json.error_string)
			parts = _get_fallback_parts()
	else:
		push_error("DataLoader: ERROR - Failed to open cards file: " + CARDS_PATH)
		print("DataLoader: Using fallback cards instead")
		parts = _get_fallback_parts()
	
	return parts

func load_starting_deck() -> Array:
	# Load 15 random cards for the starting deck
	print("DataLoader: Loading starting deck...")
	var all_parts = load_all_cards()
	print("DataLoader: Loaded ", all_parts.size(), " total parts from JSON")
	var starter_deck = []
	
	# If we don't have enough cards, duplicate the available ones
	if all_parts.size() == 0:
		print("DataLoader: ERROR - No parts available to create starting deck!")
		return starter_deck
	
	# Create a pool of cards to choose from (including duplicates if needed)
	var part_pool = all_parts.duplicate()
	print("DataLoader: Initial part pool size: ", part_pool.size())
	
	# If we need more than available, add duplicates
	while part_pool.size() < 15:
		part_pool.append_array(all_parts)
		print("DataLoader: Expanded part pool to: ", part_pool.size())
	
	# Shuffle the pool
	part_pool.shuffle()
	print("DataLoader: Shuffled part pool")
	
	# Take the first 15 parts and clone them to avoid shared references
	for i in range(15):
		var part = part_pool[i].clone()
		starter_deck.append(part)
	
	print("DataLoader: Created starting deck with ", starter_deck.size(), " parts")
	for i in range(min(3, starter_deck.size())):
		print("  Sample part ", i+1, ": ", starter_deck[i].part_name)
	
	return starter_deck

func load_all_enemies() -> Array:
	var enemies = []
	
	# Load enemies from JSON file
	var file = FileAccess.open(ENEMIES_PATH, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			var data = json.get_data()
			enemies = data
	else:
		push_error("Failed to open enemies file: " + ENEMIES_PATH)
		# Fallback to minimal data
		enemies = _get_fallback_enemies()
	
	return enemies

# Public getter methods for GameManager
func get_all_cards() -> Array:
	return load_all_cards()

func get_all_enemies() -> Array:
	return load_all_enemies()

func get_starting_deck() -> Array:
	return load_starting_deck()

func load_enemy_data() -> Array:
	var enemies = []
	
	# Load enemies from JSON file
	var file = FileAccess.open(ENEMIES_PATH, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			var data = json.get_data()
			enemies = data
	else:
		push_error("Failed to open enemies file: " + ENEMIES_PATH)
		# Fallback to minimal data
		enemies = _get_fallback_enemies()
	
	return enemies

func load_boss_data() -> Dictionary:
	var enemies = load_enemy_data()
	
	# Find the boss enemy
	for enemy in enemies:
		if enemy.get("is_boss", false):
			return enemy
	
	# Fallback to final enemy if no boss specified
	return enemies[enemies.size() - 1] if enemies.size() > 0 else _get_fallback_boss()

func load_reward_options() -> Array:
	# For prototype, just use a subset of all cards as rewards
	var all_cards = load_all_cards()
	var reward_options = []
	
	# Filter for uncommon and rare cards
	for card in all_cards:
		if card.rarity == "Uncommon" or card.rarity == "Rare":
			reward_options.append(card)
	
	return reward_options

func get_card_by_id(card_id) -> Part:
	var all_cards = load_all_cards()
	for card in all_cards:
		if card.id == card_id:
			return card.clone()  # Return a clone to avoid shared references
	return null

# Fallback functions in case files can't be loaded
func _get_fallback_parts() -> Array:
	var parts = []
	
	var fallback_data = [
		{
			"id": "scope_visor",
			"name": "Scope Visor",
			"type": "Head",
			"cost": 1,
			"heat": 0,
			"durability": 3,
			"effects": [
				{
					"type": "stat",
					"timing": "attach",
					"stat": "crit_chance",
					"value": 10,
					"target": "self",
					"description": "+10% crit chance"
				}
			],
			"rarity": "Common",
			"description": "Basic targeting system with modest crit bonus."
		},
		{
			"id": "pulse_blaster",
			"name": "Pulse Blaster",
			"type": "Arm",
			"cost": 1,
			"heat": 0,
			"durability": 3,
			"attack_type": ["melee", "range"],
			"attack_range": [0.1, 4.0],
			"effects": [
				{
					"type": "stat",
					"timing": "attach",
					"stat": "damage",
					"value": 6,
					"target": "self",
					"description": "6 damage per hit"
				}
			],
			"rarity": "Common",
			"description": "Standard energy weapon with consistent output."
		},
		{
			"id": "heavy_plating",
			"name": "Heavy Plating",
			"type": "Core",
			"cost": 1,
			"heat": 0,
			"durability": 5,
			"effects": [
				{
					"type": "stat",
					"timing": "attach",
					"stat": "armor",
					"value": 10,
					"target": "self",
					"description": "+10 Armor"
				},
				{
					"type": "stat",
					"timing": "attach",
					"stat": "move_speed",
					"value": -5,
					"target": "self",
					"description": "-5% Move Speed"
				}
			],
			"rarity": "Common",
			"description": "Thick armor plating that slows movement slightly."
		},
		{
			"id": "tracked_legs",
			"name": "Tracked Legs",
			"type": "Legs",
			"cost": 1,
			"heat": 0,
			"durability": 4,
			"effects": [
				{
					"type": "stat",
					"timing": "attach",
					"stat": "stability",
					"value": 20,
					"target": "self",
					"description": "+20% stability"
				}
			],
			"rarity": "Common",
			"description": "Basic treads for stable movement."
		}
	]
	
	for data in fallback_data:
		var part = Part.new()
		part.initialize_from_data(data)
		parts.append(part)
		
	return parts

func _get_fallback_enemies() -> Array:
	return [
		{
			"id": "basic_drone",
			"name": "Basic Drone",
			"hp": 6,
			"armor": 0,
			"damage": 1,
			"attack_speed": 1.0,
			"move_speed": 80,
			"behavior": "default",
			"is_boss": false
		},
		{
			"id": "scavenger_drone",
			"name": "Scavenger Drone",
			"hp": 8,
			"armor": 0,
			"damage": 2,
			"attack_speed": 2.0,
			"move_speed": 120,
			"behavior": "aggressive",
			"is_boss": false
		},
		{
			"id": "guardian_sentry", 
			"name": "Guardian Sentry",
			"hp": 15,
			"armor": 5,
			"damage": 3,
			"attack_speed": 0.8,
			"move_speed": 50,
			"behavior": "defensive",
			"is_boss": false
		},
		{
			"id": "striker_unit",
			"name": "Striker Unit",
			"hp": 12,
			"armor": 2,
			"damage": 2,
			"attack_speed": 1.5,
			"move_speed": 100,
			"behavior": "flanking",
			"is_boss": false
		},
		_get_fallback_boss()
	]

func _get_fallback_boss() -> Dictionary:
	return {
		"id": "juggernaut",
		"name": "Juggernaut Prototype",
		"hp": 30,
		"armor": 10,
		"damage": 4,
		"attack_speed": 1.0,
		"move_speed": 70,
		"behavior": "aggressive",
		"is_boss": true,
		"special_abilities": [
			{
				"name": "Adaptive Defense",
				"description": "Changes attack pattern at low health",
				"trigger": "on_health_threshold",
				"effect": "behavior_change"
			}
		]
	}
