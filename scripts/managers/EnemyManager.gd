extends Node
class_name EnemyManager

signal next_enemy_determined(enemy_data)

# References to other managers - set via exports
@export var game_manager: GameManager
@export var data_loader: DataLoader

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

# Determine the next enemy to face
func determine_next_enemy():
    if all_enemies.size() == 0:
        push_error("EnemyManager: No enemies loaded!")
        return
    
    # Check if this is a boss encounter
    var is_boss_encounter = (current_encounter_index % boss_encounter_index == 0) and current_encounter_index > 0
    
    var candidate_enemies = []
    
    if is_boss_encounter:
        # Filter for boss enemies
        for enemy in all_enemies:
            if enemy.is_boss:
                candidate_enemies.append(enemy)
        
        # Fallback if no bosses defined
        if candidate_enemies.size() == 0:
            push_warning("No boss enemies found - using regular enemies")
            is_boss_encounter = false
    
    # If not a boss encounter or no bosses available
    if !is_boss_encounter:
        # Filter for non-boss enemies
        for enemy in all_enemies:
            if !enemy.is_boss:
                candidate_enemies.append(enemy)
    
    # Select a random enemy from candidates
    if candidate_enemies.size() > 0:
        var random_index = randi() % candidate_enemies.size()
        next_enemy = candidate_enemies[random_index]
        emit_signal("next_enemy_determined", next_enemy)
    else:
        push_error("EnemyManager: No suitable enemies found!")

# Get the next enemy that will be faced
func get_next_enemy():
    return next_enemy

# Advance to the next encounter
func advance_encounter():
    current_encounter_index += 1
    determine_next_enemy()

# Get enemy data by ID
func get_enemy_by_id(id: String):
    for enemy in all_enemies:
        if enemy.id == id:
            return enemy
    return null
