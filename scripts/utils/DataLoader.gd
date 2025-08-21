extends Node
class_name DataLoader

# File paths
const CARDS_PATH = "res://data/cards.json"  # Single source of truth for card data
const ENEMIES_PATH = "res://data/enemies.json"

func _ready():
	pass

func load_all_cards() -> Array:
	var cards = []
	
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
			cards = data
			print("DataLoader: Successfully parsed JSON, found ", cards.size(), " cards")
		else:
			print("DataLoader: ERROR - Failed to parse JSON: ", json.error_string)
			push_error("DataLoader: Failed to parse cards.json: " + json.error_string)
			cards = _get_fallback_cards()
	else:
		push_error("DataLoader: ERROR - Failed to open cards file: " + CARDS_PATH)
		print("DataLoader: Using fallback cards instead")
		cards = _get_fallback_cards()
	
	return cards

func load_starting_deck() -> Array:
	# Load 15 random cards for the starting deck
	print("DataLoader: Loading starting deck...")
	var all_cards = load_all_cards()
	print("DataLoader: Loaded ", all_cards.size(), " total cards from JSON")
	var starter_deck = []
	
	# If we don't have enough cards, duplicate the available ones
	if all_cards.size() == 0:
		print("DataLoader: ERROR - No cards available to create starting deck!")
		return starter_deck
	
	# Create a pool of cards to choose from (including duplicates if needed)
	var card_pool = all_cards.duplicate()
	print("DataLoader: Initial card pool size: ", card_pool.size())
	
	# If we need more than available, add duplicates
	while card_pool.size() < 15:
		card_pool.append_array(all_cards)
		print("DataLoader: Expanded card pool to: ", card_pool.size())
	
	# Shuffle the pool
	card_pool.shuffle()
	print("DataLoader: Shuffled card pool")
	
	# Take the first 15 cards and assign unique instance IDs
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(15):
		var card = card_pool[i].duplicate() # Create a deep copy to avoid modifying original
		
		# Add a unique instance ID for each card
		card["instance_id"] = "card_" + str(rng.randi()) + "_" + str(Time.get_unix_time_from_system())
		
		starter_deck.append(card)
	
	print("DataLoader: Created starting deck with ", starter_deck.size(), " cards")
	for i in range(min(3, starter_deck.size())):
		print("  Sample card ", i+1, ": ", starter_deck[i].get("name", "Unknown"), " (ID: ", starter_deck[i].get("instance_id", "None"), ")")
	
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

# Fallback functions in case files can't be loaded
func _get_fallback_cards() -> Array:
	return [
		{
			"id": "scope_visor",
			"name": "Scope Visor",
			"type": "Head",
			"cost": 1,
			"heat": 0,
			"durability": 3,
			"effects": [
				{
					"type": "crit",
					"value": 10,
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
			"effects": [
				{
					"type": "damage",
					"value": 6,
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
					"type": "armor",
					"value": 10,
					"description": "+10 Armor"
				},
				{
					"type": "move_speed_percent",
					"value": -5,
					"description": "-5% Move Speed"
				}
			],
			"rarity": "Common",
			"description": "Thick armor plating that slows movement slightly."
		},
		{
			"id": "tracked_legs",
			"name": "Tracked Legs",
			"type": "Leg",
			"cost": 1,
			"heat": 0,
			"durability": 4,
			"effects": [
				{
					"type": "stability",
					"value": 20,
					"description": "+20% stability"
				}
			],
			"rarity": "Common",
			"description": "Basic treads for stable movement."
		}
	]

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
