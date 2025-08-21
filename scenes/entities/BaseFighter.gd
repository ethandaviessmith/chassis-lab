extends CharacterBody2D
class_name BaseFighter

# Resources
var energy: int = 10  # Health/energy for player robot, HP for enemies
var max_energy: int = 10
var heat: int = 0
var max_heat: int = 10
var armor: int = 0

# Movement and combat stats
var move_speed: float = 100.0
var attack_speed: float = 1.0

# Attack properties
var attack_types = ["melee"]    # Default to melee only
var attack_ranges = [1.0]       # Default range
var current_attack_index = 0    # Which attack type to use next

# Parts data (for stat calculation)
var parts = {}  # Dictionary of attached parts

# Part effects cache
var effects = {}  # Dictionary of active effects

# Combat state
var target = null
var is_active: bool = false
var combat_view = null          # Reference to combat view for effects

# References
@onready var health_bar = $HealthBar
@onready var animation_player = $AnimationPlayer

# Signal for defeat
signal fighter_defeated

func _ready():
    # Initialize health bar
    update_bars()
    
    # Find combat view for effects
    find_combat_view()

# Find reference to combat view
func find_combat_view():
    await get_tree().process_frame  # Wait for scene to be ready
    combat_view = get_tree().get_first_node_in_group("combat_view")

func _physics_process(delta):
    if is_active:
        process_combat_behavior(delta)

# Default implementation - can be overridden in child classes
func process_combat_behavior(delta):
    if not target:
        target = find_target()
    
    if target and is_instance_valid(target):
        # Simple approach: move toward target and attack when in range
        move_toward_target(target)
        try_attack(target, delta)
    else:
        # No valid target, stop moving
        velocity = Vector2.ZERO

# Generic try_attack implementation
func try_attack(target_node, _delta):
    # Check if fighter is defeated
    if energy <= 0:
        return  # Don't attack if defeated
        
    # Basic implementation - can be overridden by subclasses
    # Check distance to target
    var distance_to_target = global_position.distance_to(target_node.global_position)
    var attack_range = 50  # Default range
    
    if distance_to_target <= attack_range:
        perform_attack(target_node)

# Find a target to attack
func find_target():
    # Players should target enemies
    if is_in_group("player_robot"):
        var enemies = get_tree().get_nodes_in_group("enemies")
        if enemies.size() > 0:
            # Find closest enemy
            var closest_enemy = null
            var closest_distance = INF
            
            for enemy in enemies:
                if is_instance_valid(enemy):
                    var distance = global_position.distance_to(enemy.global_position)
                    if distance < closest_distance:
                        closest_distance = distance
                        closest_enemy = enemy
            
            return closest_enemy
    
    # Enemies should target player
    elif is_in_group("enemies"):
        # Look for player robot in combat group
        var player_robots = get_tree().get_nodes_in_group("player_robot")
        if player_robots.size() > 0:
            return player_robots[0]
        
        # Fallback - look for any player
        var players = get_tree().get_nodes_in_group("player")
        if players.size() > 0:
            return players[0]
    
    return null

# Move toward target
func move_toward_target(target_node):
    if not is_instance_valid(target_node):
        return
        
    var direction = (target_node.global_position - global_position).normalized()
    velocity = direction * move_speed
    move_and_slide()

# Take damage from an attack
func take_damage(amount: int):
    # Calculate actual damage
    var actual_damage = max(0, amount - armor)
    energy -= actual_damage
    energy = max(0, energy)
    
    update_bars()
    print(self.name, " took ", actual_damage, " damage (", energy, "/", max_energy, ")")
    
    # Show shield indicator if armor reduced damage significantly
    if armor > 0 and amount > actual_damage and combat_view:
        combat_view.show_combat_effect("shield", self)
    
    # Play hit animation
    play_hurt_animation()
    
    # Check for defeat
    if energy <= 0:
        play_death_animation()

# Play animations - to be implemented or extended in child classes
func play_attack_animation():
    if animation_player and animation_player.has_animation("attack"):
        animation_player.play("attack")

func play_hurt_animation():
    if animation_player and animation_player.has_animation("hurt"):
        animation_player.play("hurt")

func play_death_animation():
    if animation_player and animation_player.has_animation("death"):
        animation_player.play("death")
        await animation_player.animation_finished
    
    # Signal defeat
    emit_signal("fighter_defeated")

# Status management
func update_bars():
    if health_bar:
        health_bar.value = 100.0 * energy / max_energy

func get_armor() -> int:
    return armor

func is_defeated() -> bool:
    return energy <= 0
    
func is_overheated() -> bool:
    return heat >= max_heat

func get_combat_effectiveness() -> float:
    # Return a value between 0-1 representing how effective the fighter is
    var health_factor = float(energy) / float(max_energy)
    var heat_factor = 1.0 - (float(heat) / float(max_heat))
    return (health_factor + heat_factor) / 2.0

# Combat state management
func activate():
    is_active = true
    add_to_group("active_fighters")
    print(self.name, " activated for combat")

func deactivate():
    is_active = false
    if is_in_group("active_fighters"):
        remove_from_group("active_fighters")
    target = null
    velocity = Vector2.ZERO
    print(self.name, " deactivated")

func set_target(new_target):
    target = new_target
    
# Get fighter status summary
func get_status_summary() -> String:
    var status = "Energy: " + str(energy) + "/" + str(max_energy)
    status += " | Heat: " + str(heat) + "/" + str(max_heat)
    status += " | Armor: " + str(armor)
    if is_defeated():
        status += " | DEFEATED"
    elif is_overheated():
        status += " | OVERHEATED"
    return status

# Generic attack implementation that can be overridden by subclasses
func perform_attack(target_node):
    # Basic damage calculation
    var base_damage = 1
    
    # Apply randomization to damage (±20%)
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    var damage_variation = rng.randf_range(0.8, 1.2)
    var damage = round(base_damage * damage_variation)
    damage = max(1, damage)  # Ensure minimum damage of 1
    
    # Get current attack type and range
    var attack_type = attack_types[current_attack_index]
    var attack_range = attack_ranges[current_attack_index] * 100.0  # Convert to pixels
    
    # Attack based on type
    if attack_type == "melee":
        # Direct melee attack
        if target_node.has_method("take_damage"):
            target_node.take_damage(damage)
            print(self.name, " attacked for ", damage, " damage with melee")
            
            if combat_view:
                combat_view.show_combat_effect("melee_attack", self)
                combat_view.show_damage_number(damage, target_node)
                
    elif attack_type == "range":
        if combat_view:
            print(self.name, " fired a projectile for ", damage, " damage")
            combat_view.show_combat_effect("range_attack", self)
            combat_view.fire_projectile(self, target_node.global_position, damage, attack_range)
    
    # Cycle to next attack type
    current_attack_index = (current_attack_index + 1) % attack_types.size()

# Add heat - primarily for player robot, but can be used by enemies
func add_heat(amount: int):
    heat = min(heat + amount, max_heat)
    
    if heat >= max_heat:
        # Overheating penalties could be applied here
        if combat_view:
            combat_view.show_combat_effect("overheat", self)
    elif heat >= 8 and heat < max_heat:
        # High heat warning
        if combat_view:
            combat_view.show_combat_effect("overheat", self)

# Reduce heat
func reduce_heat(amount: int):
    var previous_heat = heat
    heat = max(0, heat - amount)
    update_bars()
    
    # Show cooldown indicator when significant heat reduction happens
    if previous_heat > 5 and amount >= 2 and combat_view:
        combat_view.show_combat_effect("cooldown", self)
