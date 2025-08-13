extends Node
class_name DataLoader

# File paths
const CARDS_PATH = "res://data/cards.json"
const ENEMIES_PATH = "res://data/enemies.json"

func _ready():
	pass

func load_all_cards() -> Array:
	var cards = []
	
	# Load cards from JSON file
	var file = FileAccess.open(CARDS_PATH, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			var data = json.get_data()
			cards = data
	else:
		push_error("Failed to open cards file: " + CARDS_PATH)
		# Fallback to minimal data
		cards = _get_fallback_cards()
	
	return cards

func load_starting_deck() -> Array:
	# For the prototype, just load a subset of cards as starting deck
	var all_cards = load_all_cards()
	var starter_deck = []
	
	# Add some basic cards of each type
	var type_counts = {
		"Head": 0,
		"Core": 0,
		"Arm": 0,
		"Leg": 0,
		"Utility": 0
	}
	
	# Add a balanced starter deck
	for card in all_cards:
		if card.rarity == "Common" and type_counts[card.type] < 2:
			starter_deck.append(card)
			type_counts[card.type] += 1
	
	return starter_deck

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
			"id": "scavenger_drone",
			"name": "Scavenger Drone",
			"hp": 8,
			"armor": 0,
			"damage": 1,
			"attack_speed": 2.0,
			"move_speed": 120,
			"behavior": "aggressive"
		},
		{
			"id": "guardian_sentry",
			"name": "Guardian Sentry",
			"hp": 15,
			"armor": 5,
			"damage": 3,
			"attack_speed": 0.8,
			"move_speed": 50,
			"behavior": "defensive"
		},
		{
			"id": "striker_unit",
			"name": "Striker Unit",
			"hp": 12,
			"armor": 2,
			"damage": 2,
			"attack_speed": 1.5,
			"move_speed": 100,
			"behavior": "flanking"
		}
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
