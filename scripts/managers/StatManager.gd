extends Node
class_name StatManager

# Signals
signal stats_updated(stat_data)
signal stat_hover_preview(stat_data, preview_data)
signal stat_hover_ended()

# References to other managers - set via exports
@export var chassis_manager: ChassisManager
@export var game_manager: GameManager
@export var deck_manager: DeckManager
@export var turn_manager: TurnManager

# Base stats for the player's robot
var base_stats = {
	"damage": 1,
	"armor": 0,
	"speed": 100,
	"crit_chance": 5,  # Base 5% crit chance
	"dodge_chance": 0,
	"attack_speed": 1.0,
	"energy": 10,
	"heat_capacity": 10,
	"heat_dissipation": 1
}

# Current calculated stats
var current_stats = {}

# Called when the node enters the scene tree for the first time
func _ready():
	# Initialize stats with base values
	current_stats = base_stats.duplicate(true)
	
	# Connect to chassis updates to recalculate stats
	if chassis_manager:
		chassis_manager.chassis_updated.connect(_on_chassis_updated)
	emit_signal("stats_updated", get_current_stats())

# Calculate robot stats based on attached parts
func calculate_stats(attached_parts) -> Dictionary:
	# Start with base stats
	var stats = base_stats.duplicate(true)
	
	# Process parts in each slot
	for slot_name in attached_parts:
		if slot_name == "scrapper":
			continue  # Skip scrapper slot for stats calculation
		
		var part = attached_parts[slot_name]
		if part is Card:
			_apply_part_stats(stats, part.data)
	
	current_stats = stats
	return stats

# Apply a single part's stats to the stats dictionary
func _apply_part_stats(stats: Dictionary, part_data: Dictionary) -> void:
	# Process effects array if it exists
	if "effects" in part_data and part_data.effects is Array:
		for effect in part_data.effects:
			match effect.type:
				"damage":
					stats.damage += int(effect.value)
				"damage_percent":
					stats.damage = stats.damage * (1 + (float(effect.value) / 100.0))
				"armor":
					stats.armor += int(effect.value)
				"crit_chance":
					stats.crit_chance += int(effect.value)
				"dodge_chance":
					stats.dodge_chance += int(effect.value)
				"attack_speed_percent":
					stats.attack_speed = stats.attack_speed * (1 + (float(effect.value) / 100.0))
				"move_speed_percent":
					stats.speed = stats.speed * (1 + (float(effect.value) / 100.0))
				"max_heat":
					stats.heat_capacity += int(effect.value)
				"heat_dissipation":
					stats.heat_dissipation += int(effect.value)
				"energy_next_turn":
					stats.energy += int(effect.value)
				# Add more stat types as needed

# Get the current calculated stats
func get_current_stats() -> Dictionary:
	return current_stats

# Calculate preview stats when a card is hovered over a slot
func calculate_preview_stats(card: Card, target_slot: String) -> Dictionary:
	# Get a copy of the current attached parts
	var temp_attached_parts = chassis_manager.attached_parts.duplicate()
	
	# Temporarily add or replace the part in the specific slot
	temp_attached_parts[target_slot] = card
	
	# Calculate the new stats
	var preview_stats = calculate_stats(temp_attached_parts)
	
	# Return both current and preview stats for comparison
	return {
		"current": current_stats,
		"preview": preview_stats,
		"differences": _calculate_stat_differences(current_stats, preview_stats)
	}

# Calculate the differences between two stat dictionaries
func _calculate_stat_differences(old_stats: Dictionary, new_stats: Dictionary) -> Dictionary:
	var differences = {}
	
	for stat_name in new_stats.keys():
		if old_stats.has(stat_name):
			var diff = new_stats[stat_name] - old_stats[stat_name]
			if abs(diff) > 0.01:  # Account for floating point errors
				differences[stat_name] = diff
	
	return differences

# Handle chassis updates
func _on_chassis_updated(attached_parts):
	var new_stats = calculate_stats(attached_parts)
	emit_signal("stats_updated", new_stats)

# Called when a card hovers over a slot
func card_hover_over_slot(card: Card, slot_name: String):
	var preview_data = calculate_preview_stats(card, slot_name)
	emit_signal("stat_hover_preview", current_stats, preview_data)

# Called when a card stops hovering over a slot
func card_hover_end():
	emit_signal("stat_hover_ended")
