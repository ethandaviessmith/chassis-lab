extends Node
class_name EnemyScalingSystem

@export var base_enemy_stats = {
    "health": 10,
    "damage": 1,
    "armor": 0
}
@export var scaling_curve: Curve = Curve.new()
@export var max_scaling_factor: float = 3.0
var current_battle_number: int = 0

func get_scaled_enemy_stats() -> Dictionary:
    var normalized_progress = min(current_battle_number / 10.0, 1.0)
    var curve_value = scaling_curve.sample(normalized_progress)
    var scaling_factor = 1.0 + (curve_value * max_scaling_factor)
    var scaled_stats = {}
    for stat in base_enemy_stats:
        scaled_stats[stat] = base_enemy_stats[stat] * scaling_factor
    scaled_stats.health = int(scaled_stats.health * randf_range(0.9, 1.1))
    scaled_stats.damage = int(max(1, scaled_stats.damage * randf_range(0.9, 1.1)))
    Log.pr("Scaled Enemy Stats: %s" % scaled_stats)
    return scaled_stats

func advance_battle():
    current_battle_number += 1
