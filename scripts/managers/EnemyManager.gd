extends Node
class_name EnemyManager

signal next_enemy_determined(enemy_data)

@export var game_manager: GameManager
@export var data_loader: DataLoader
@export var enemy_scaling: EnemyScalingSystem

# Enemy data
var all_enemies = []
var next_enemy = null
var current_encounter_index = 0
var boss_encounter_index = 5 # Boss after 5 normal encounters

# Called when the node enters the scene tree for the first time
func _ready():
    # Load enemy data
    if data_loader:
        all_enemies = data_loader.load_all_enemies()
        
    # Start by determining the first enemy
    determine_next_enemy()

func determine_next_enemy():
    if all_enemies.size() == 0:
        push_error("EnemyManager: No enemies loaded!")
        return
        
    # Ensure enemy scaling system has the correct battle number
    if enemy_scaling:
        enemy_scaling.current_battle_number = current_encounter_index

    # Check if this is a boss encounter
    var is_boss_encounter = (current_encounter_index % boss_encounter_index == 0) and current_encounter_index > 0

    var candidate_enemies = []

    if is_boss_encounter:
        for enemy in all_enemies:
            if enemy.is_boss:
                candidate_enemies.append(enemy)
        if candidate_enemies.size() == 0:
            push_warning("No boss enemies found - using regular enemies")
            is_boss_encounter = false

    if !is_boss_encounter:
        for enemy in all_enemies:
            if !enemy.is_boss:
                candidate_enemies.append(enemy)

    if candidate_enemies.size() > 0:
        var random_index = randi() % candidate_enemies.size()
        var base_enemy = candidate_enemies[random_index]
        # Apply scaling system
        if enemy_scaling:
            var scaled_stats = enemy_scaling.get_scaled_enemy_stats()
            # Clone base enemy and apply scaled stats
            var enemy_instance = base_enemy.duplicate()
            enemy_instance.health = scaled_stats.health
            enemy_instance.max_health = scaled_stats.health
            enemy_instance.damage = scaled_stats.damage
            enemy_instance.armor = scaled_stats.armor
            next_enemy = enemy_instance
        else:
            next_enemy = base_enemy.duplicate() # Always duplicate to prevent reference issues

        # Create a standardized display data object for consistent UI display
        var display_data = {
            "name": next_enemy.name if "name" in next_enemy else (next_enemy.enemy_name if "enemy_name" in next_enemy else "Unknown Enemy"),
            "hp": next_enemy.health if "health" in next_enemy else (next_enemy.max_energy if "max_energy" in next_enemy else 0),
            "damage": next_enemy.damage if "damage" in next_enemy else 0,
            "armor": next_enemy.armor if "armor" in next_enemy else 0,
            "move_speed": next_enemy.move_speed if "move_speed" in next_enemy else 100,
            "is_boss": next_enemy.is_boss if "is_boss" in next_enemy else false,
            "sprite": next_enemy.sprite if "sprite" in next_enemy else ""
        }
        
        # Debug output to verify actual combat values
        print("EnemyManager: Next enemy combat values - Health: %s, Damage: %s, Armor: %s" % [
            next_enemy.health if "health" in next_enemy else (next_enemy.max_energy if "max_energy" in next_enemy else 0),
            next_enemy.damage if "damage" in next_enemy else 0,
            next_enemy.armor if "armor" in next_enemy else 0
        ])
        
        # Emit the standardized display data for UI
        emit_signal("next_enemy_determined", display_data)
    else:
        push_error("EnemyManager: No suitable enemies found!")

# Get the next enemy that will be faced
func get_next_enemy():
    return next_enemy

# Advance to the next encounter
func advance_encounter():
    current_encounter_index += 1
    
    # Update the enemy scaling system with the current encounter index
    if enemy_scaling:
        enemy_scaling.current_battle_number = current_encounter_index
        print("EnemyManager: Advanced to encounter %d, updating scaling" % current_encounter_index)
    
    determine_next_enemy()

# Get enemy data by ID
func get_enemy_by_id(id: String):
    for enemy in all_enemies:
        if enemy.id == id:
            return enemy
    return null
