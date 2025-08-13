extends Node
class_name CombatResolver

signal combat_tick
signal damage_dealt(source, target, amount)
signal robot_heat_changed(new_heat)
signal overheat_started
signal overheat_ended
signal part_durability_changed(part, new_durability)
signal part_broken(part)
signal entity_defeated(entity)
signal combat_ended(player_won)

var combat_active = false
var round_count = 0
var tick_count = 0
var combat_speed = 1.0  # Multiplier for combat speed

# Combat entities
var player_robot = null
var current_enemy = null

# References
@export var data_loader: DataLoader
@onready var combat_view = $"../../CombatView"
@export var robot_fighter: RobotFighter

func _ready():
    pass

func _process(delta):
    if combat_active:
        # Combat tick processing
        tick_count += 1
        
        if tick_count % 60 == 0:  # Once per second
            advance_combat_round()
        
        emit_signal("combat_tick")
        
        # Process entities
        if player_robot and player_robot.energy <= 0:
            _end_combat(false)  # Player lost
        elif current_enemy and current_enemy.hp <= 0:
            _end_combat(true)   # Player won

func start_combat(encounter_id: int):
    # Reset combat state
    combat_active = true
    round_count = 0
    tick_count = 0
    
    # Set up player robot
    player_robot = combat_view.get_player_robot()
    
    # Create enemy for this encounter
    current_enemy = _create_enemy_for_encounter(encounter_id)
    combat_view.spawn_enemy(current_enemy)
    
    print("Combat started: Player vs ", current_enemy.name)

func advance_combat_round():
    round_count += 1
    print("Combat round: ", round_count)
    
    # Process robot parts - reduce durability etc.
    for part in player_robot.get_parts():
        reduce_part_durability(part)

func reduce_part_durability(part):
    if part.durability > 0:
        part.durability -= 1
        emit_signal("part_durability_changed", part, part.durability)
        
        if part.durability <= 0:
            emit_signal("part_broken", part)
            player_robot.remove_part(part)

func apply_damage(source, target, amount):
    var actual_damage = amount
    
    # Apply armor reduction if target has armor
    if target.has_method("get_armor"):
        var armor = target.get_armor()
        var damage_reduction = min(0.7, armor * 0.05)  # 5% per armor point, max 70% reduction
        actual_damage = max(1, int(actual_damage * (1 - damage_reduction)))
    
    # Apply damage
    target.take_damage(actual_damage)
    
    emit_signal("damage_dealt", source, target, actual_damage)
    
    # Check for defeat
    if target.is_defeated():
        emit_signal("entity_defeated", target)

func update_robot_heat(new_heat):
    emit_signal("robot_heat_changed", new_heat)
    
    # Check for overheat thresholds
    if new_heat >= 10 and player_robot.heat < 10:
        emit_signal("overheat_started")
    elif new_heat < 8 and player_robot.heat >= 8:
        emit_signal("overheat_ended")

func _create_enemy_for_encounter(encounter_id: int):
    var enemy_data
    
    if encounter_id >= 3:  # Boss encounter
        enemy_data = data_loader.load_boss_data()
    else:
        var enemies = data_loader.load_enemy_data()
        enemy_data = enemies[encounter_id % enemies.size()]
    
    var enemy = Enemy.new()
    enemy.initialize_from_data(enemy_data)
    
    return enemy

func _end_combat(player_won: bool):
    combat_active = false
    
    if player_won:
        print("Player won combat!")
    else:
        print("Player was defeated!")
    
    emit_signal("combat_ended", player_won)
