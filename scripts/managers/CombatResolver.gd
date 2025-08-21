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
signal effect_activated(effect_description)

var combat_active = false
var round_count = 0
var tick_count = 0
var combat_speed = 1.0  # Multiplier for combat speed

# Effect system
var effect_system: CardEffectSystem

# Combat entities
var player_robot = null
var current_enemy = null
var current_enemy_data = null

# References
@export var data_loader: DataLoader
@export var enemy_manager: EnemyManager
@export var combat_view: CombatView
@export var robot_fighter: PlayerRobot
@export var card_effect_system: CardEffectSystem

func _ready():
    # Initialize effect system if not provided
    if card_effect_system == null:
        card_effect_system = CardEffectSystem.new()
        add_child(card_effect_system)
    effect_system = card_effect_system

func _process(_delta):
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
    
    # Process initial attach effects when combat starts
    if player_robot:
        _process_attach_effects()
    
    # Get enemy data from EnemyManager if available
    if enemy_manager and enemy_manager.get_next_enemy():
        current_enemy_data = enemy_manager.get_next_enemy()
        current_enemy = _create_enemy_from_data(current_enemy_data)
        # Advance to next encounter for future battles
        enemy_manager.advance_encounter()
    else:
        # Fallback to legacy method if EnemyManager not available
        current_enemy = _create_enemy_for_encounter(encounter_id)
        
    combat_view.spawn_enemy(current_enemy)
    
    print("Combat started: Player vs ", current_enemy.name)
    
# Process initial attach effects for parts
func _process_attach_effects():
    var context = {
        "stat_modifiers": {},
        "max_energy": 0,
        "max_heat": 0
    }
    
    var _effect_results = process_effects(effect_system.EffectTiming.ON_ATTACH, player_robot, context)
    
    # Apply energy and heat modifications
    if context.max_energy > 0 and player_robot.has_method("modify_max_energy"):
        player_robot.modify_max_energy(context.max_energy)
        
    if context.max_heat > 0 and player_robot.has_method("modify_max_heat"):
        player_robot.modify_max_heat(context.max_heat)

func advance_combat_round():
    round_count += 1
    print("Combat round: ", round_count)
    
    # Process turn start effects
    process_turn_start_effects()
    
    # Process robot parts - reduce durability etc.
    for part in player_robot.get_parts():
        reduce_part_durability(part)
        
    # Process turn end effects
    process_turn_end_effects()

func reduce_part_durability(part):
    if part.durability > 0:
        part.durability -= 1
        emit_signal("part_durability_changed", part, part.durability)
        
        if part.durability <= 0:
            emit_signal("part_broken", part)
            player_robot.remove_part(part)

func apply_damage(source, target, amount):
    var actual_damage = amount
    
    # If player is attacking, apply card effects
    if source == player_robot:
        var effect_context = process_attack_effects(target)
        
        # Apply damage modifiers from effects
        if effect_context.has("damage_modifiers") and effect_context.damage_modifiers != 1.0:
            actual_damage = actual_damage * effect_context.damage_modifiers
    
    # Apply armor reduction if target has armor
    if target.has_method("get_armor"):
        var armor = target.get_armor()
        var damage_reduction = min(0.7, armor * 0.05)  # 5% per armor point, max 70% reduction
        actual_damage = max(1, int(actual_damage * (1 - damage_reduction)))
    
    # Apply damage
    target.take_damage(actual_damage)
    
    # Play damage sound
    Sound.play_damage()
    
    emit_signal("damage_dealt", source, target, actual_damage)
    
    # When the player's robot is attacked, also damage a random part
    if target == player_robot and source != player_robot:
        # Process damage taken effects
        process_damage_taken_effects()
        damage_random_part()
    
    # Check for defeat
    if target.is_defeated():
        emit_signal("entity_defeated", target)

func damage_random_part():
    if not player_robot or not player_robot.has_method("get_parts"):
        return
        
    var parts = player_robot.get_parts()
    if parts.is_empty():
        return
        
    # Randomly select a part to damage
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    var random_index = rng.randi() % parts.size()
    var random_part = parts[random_index]
    
    if random_part and random_part.has_method("reduce_durability"):
        random_part.reduce_durability(1)
        print("Random part damaged: ", random_part.name if random_part.has_method("get_name") else "Unknown")
        emit_signal("part_durability_changed", random_part, random_part.durability)
    
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
    
    return _create_enemy_from_data(enemy_data)

func _create_enemy_from_data(enemy_data):
    var enemy = Enemy.new()
    enemy.initialize_from_data(enemy_data, combat_view)
    
    return enemy

func _end_combat(player_won: bool):
    combat_active = false
    
    if player_won:
        print("Player won combat!")
    else:
        print("Player was defeated!")
    
    emit_signal("combat_ended", player_won)

# Process card effects based on timing
func process_effects(timing: int, target = null, context = {}):
    if not player_robot or not player_robot.has_method("get_parts"):
        return []
        
    var all_results = []
    var parts = player_robot.get_parts()
    
    for part in parts:
        if not part.has("data") or not "effects" in part.data:
            continue
            
        var part_data = part.data
        var effect_results = effect_system.apply_effects(part_data, timing, target, context)
        
        # Signal each effect that was applied
        for result in effect_results:
            if result.applied and result.description != "":
                emit_signal("effect_activated", result.description)
                
        # Add to combined results
        all_results.append_array(effect_results)
    
    return all_results

# Apply effects when attack is performed
func process_attack_effects(target):
    var context = {
        "damage_modifiers": 1.0,
        "stat_modifiers": {},
        "stat_multipliers": {}
    }
    
    # Get all attack-timed effects
    var _effect_results = process_effects(effect_system.EffectTiming.ON_ATTACK, target, context)
    
    # Apply context modifiers to final damage
    return context
    
# Apply effects when damage is taken
func process_damage_taken_effects():
    var context = {
        "damage_reduction": 0,
        "heat_change": 0
    }
    
    # Get all damage-taken effects
    var _effect_results = process_effects(effect_system.EffectTiming.ON_DAMAGE_TAKEN, player_robot, context)
    
    # Apply heat changes
    if context.heat_change != 0 and player_robot.has_method("modify_heat"):
        player_robot.modify_heat(context.heat_change)
    
    return context

# Process turn-start effects
func process_turn_start_effects():
    var context = {
        "energy_gain": 0,
        "heat_change": 0
    }
    
    var _effect_results = process_effects(effect_system.EffectTiming.ON_TURN_START, player_robot, context)
    
    # Apply energy gain
    if context.energy_gain > 0 and player_robot.has_method("add_energy"):
        player_robot.add_energy(context.energy_gain)
        
    # Apply heat change
    if context.heat_change != 0 and player_robot.has_method("modify_heat"):
        player_robot.modify_heat(context.heat_change)
        
    return context
    
# Process turn-end effects
func process_turn_end_effects():
    var context = {
        "heal_amount": 0,
        "heat_change": 0
    }
    
    var _effect_results = process_effects(effect_system.EffectTiming.ON_TURN_END, player_robot, context)
    
    # Apply healing
    if context.heal_amount > 0 and player_robot.has_method("heal"):
        player_robot.heal(context.heal_amount)
        
    # Apply heat change
    if context.heat_change != 0 and player_robot.has_method("modify_heat"):
        player_robot.modify_heat(context.heat_change)
        
    return context
