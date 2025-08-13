extends Node

# This script initializes the BuildView with test card data

# Card data
var test_cards = [
	{
		"name": "Scope Visor",
		"type": "Head",
		"cost": 1,
		"heat": 0,
		"durability": 3,
		"effects": [{"description": "+10% crit; highlight lowest-HP target"}],
		"rarity": "Common",
		"description": "Basic head crit utility"
	},
	{
		"name": "Fusion Core",
		"type": "Core",
		"cost": 2,
		"heat": 1,
		"durability": 5,
		"effects": [{"description": "+1 Energy next turn; +2 Heat cap"}],
		"rarity": "Uncommon",
		"description": "Economy core"
	},
	{
		"name": "Rail Arm",
		"type": "Arm",
		"cost": 2,
		"heat": 1,
		"durability": 3,
		"effects": [{"description": "12 dmg shot; pierce 1"}],
		"rarity": "Uncommon",
		"description": "Mainline DPS with pierce"
	},
	{
		"name": "Tracked Legs",
		"type": "Leg",
		"cost": 1,
		"heat": 0,
		"durability": 4,
		"effects": [{"description": "+20% stability; -10% knockback"}],
		"rarity": "Common",
		"description": "Baseline stability legs"
	},
	{
		"name": "Overclock",
		"type": "Utility",
		"cost": 1,
		"heat": 2,
		"durability": 2,
		"effects": [{"description": "+25% dmg this turn; +3 Heat instantly"}],
		"rarity": "Uncommon",
		"description": "Burst with heat risk"
	}
]

func _ready():
	# Wait a bit to ensure the UI is initialized
	await get_tree().create_timer(0.1).timeout
	initialize_cards()
	
func initialize_cards():
	# Get reference to hand container
	var hand_container = $UI/BuildView/HandContainer
	
	# Check if we found the container
	if not hand_container:
		print("ERROR: Hand container not found!")
		return
		
	# Make sure we have cards to initialize
	if hand_container.get_child_count() < test_cards.size():
		print("WARNING: Not enough card instances in the hand container")
	
	# Initialize each card with test data
	for i in range(min(hand_container.get_child_count(), test_cards.size())):
		var card_node = hand_container.get_child(i)
		if card_node.has_method("initialize"):
			card_node.initialize(test_cards[i])
		else:
			print("ERROR: Card node is missing initialize method!")
	
	# Connect the start combat button
	var start_button = $UI/BuildView/StartCombatButton
	if start_button:
		start_button.pressed.connect(_on_start_combat_button_pressed)

func _on_start_combat_button_pressed():
	print("Combat requested! (Would transition to Combat View)")
	# In a full implementation, this would transition to the Combat View
