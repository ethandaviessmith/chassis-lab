extends Node2D
class_name CombatView

# Preload the CombatRobotFrame class
const CombatRobotFrame = preload("res://scenes/CombatRobotFrame.gd")

signal combat_finished(victory: bool)
signal show_reward_screen
signal chassis_updated(attached_parts)

# Export references - set these in the editor
@export var chassis_manager: ChassisManager = null
@export var player_spawn_point: Marker2D = null
@export var enemy_spawn_point: Marker2D = null
@export var combat_ui: Control = null
@export var start_combat_button: Button = null
@export var robot_frame_container: Control = null

# Internal references
var player_robot: PlayerRobot = null
var current_enemy = null
var combat_active: bool = false
var combat_timer: float = 0.0
var effects_layer: CombatEffectsLayer = null
var bullet_scene = preload("res://scenes/entities/Bullet.tscn")
var combat_robot_frame: CombatRobotFrame = null

# Combat parameters
var approach_distance: float = 150.0  # Distance robots approach before combat
var attack_range: float = 80.0        # Range for attacking
var approach_speed: float = 60.0      # Speed during approach phase

# Combat phases
enum CombatPhase {
    SETUP,
    APPROACH,
    FIGHTING,
    FINISHED
}
var current_phase: CombatPhase = CombatPhase.SETUP

func _ready():
    # Set up combat UI if available
    if start_combat_button:
        start_combat_button.pressed.connect(_on_start_combat_pressed)
        start_combat_button.text = "Start Combat"
    
    # Create effects layer for combat indicators
    effects_layer = CombatEffectsLayer.new()
    add_child(effects_layer)
    
    # Set up the combat_robot_frame if it exists
    if robot_frame_container:
        # Create CombatRobotFrame if it doesn't exist
        if not combat_robot_frame:
            var combat_frame_scene = preload("res://scenes/CombatRobotFrame.tscn")
            combat_robot_frame = combat_frame_scene.instantiate()
            robot_frame_container.add_child(combat_robot_frame)
        
        # Connect to the chassis_updated signal
        if not self.chassis_updated.is_connected(combat_robot_frame.update_from_parts_dict):
            self.chassis_updated.connect(combat_robot_frame.update_from_parts_dict)
    
    # Add to combat_view group so entities can find it
    add_to_group("combat_view")
    
    # Hide this view initially (BuildView should be shown first)
    visible = false

func _process(delta):
    if combat_active:
        combat_timer += delta
        process_combat_phase(delta)

# Start combat with robot fighter built from chassis
func start_combat(robot_fighter: PlayerRobot, enemy_data: Dictionary = {}):
    print("CombatView: Starting combat")
    
    # Set up player robot
    player_robot = robot_fighter
    if player_spawn_point:
        player_robot.global_position = player_spawn_point.global_position
    else:
        player_robot.global_position = Vector2(200, 300)  # Default position
    
    # Make sure robot is added to scene if not already
    if not player_robot.get_parent():
        add_child(player_robot)
    
    # Update combat robot frame with player robot data
    if combat_robot_frame:
        Log.pr("[CombatView] Initializing combat_robot_frame from player_robot")
        combat_robot_frame.initialize_from_robot(player_robot)
        
        # Connect signals for part usage and damage
        if not player_robot.is_connected("part_used", Callable(self, "_on_robot_part_used")):
            Log.pr("[CombatView] Connecting part_used signal")
            player_robot.connect("part_used", Callable(self, "_on_robot_part_used"))
        if not player_robot.is_connected("part_damaged", Callable(self, "_on_robot_part_damaged")):
            Log.pr("[CombatView] Connecting part_damaged signal")
            player_robot.connect("part_damaged", Callable(self, "_on_robot_part_damaged"))
    
    # Set up enemy
    spawn_enemy(enemy_data)
    
    # Initialize combat state
    current_phase = CombatPhase.SETUP
    combat_active = true
    combat_timer = 0.0
    
    # Show combat view
    visible = true
    
    # Connect robot signals
    if not player_robot.fighter_defeated.is_connected(_on_player_defeated):
        player_robot.fighter_defeated.connect(_on_player_defeated)

    print("CombatView: Combat setup complete")
    
    # Start the approach phase
    await get_tree().create_timer(0.5).timeout  # Brief setup delay
    current_phase = CombatPhase.APPROACH

# Spawn enemy based on data
func spawn_enemy(enemy_data: Dictionary = {}):
    # Use default enemy if none provided
    if enemy_data.is_empty():
        enemy_data = {
            "id": "test_drone",
            "name": "Test Drone",
            "hp": 8,
            "armor": 0,
            "damage": 2,
            "attack_speed": 1.5,
            "move_speed": 100,
            "behavior": "default"
        }
    
    # Load and instantiate Enemy scene
    var enemy_scene = preload("res://scenes/entities/Enemy.tscn")
    current_enemy = enemy_scene.instantiate()
    
    # Initialize enemy with data
    current_enemy.initialize_from_data(enemy_data, self)
    Log.pr("[CombatView] Spawned enemy with data: %s" % enemy_data)
    
    # Position enemy
    if enemy_spawn_point:
        current_enemy.global_position = enemy_spawn_point.global_position
    else:
        current_enemy.global_position = Vector2(600, 300)  # Default position
    
    add_child(current_enemy)
    
    # Connect defeat signal
    current_enemy.enemy_defeated.connect(_on_enemy_defeated)
    
    print("CombatView: Spawned enemy: ", enemy_data.get("name", "Unknown"))

# Process different combat phases
func process_combat_phase(delta):
    match current_phase:
        CombatPhase.SETUP:
            # Already handled in start_combat
            pass
            
        CombatPhase.APPROACH:
            process_approach_phase(delta)
            
        CombatPhase.FIGHTING:
            process_fighting_phase(delta)
            
        CombatPhase.FINISHED:
            # Combat is over, waiting for cleanup
            pass

# Handle approach phase where robots move toward each other
func process_approach_phase(_delta):
    if not player_robot or not current_enemy:
        return
    
    var distance = player_robot.global_position.distance_to(current_enemy.global_position)
    
    if distance > approach_distance:
        # Move robots toward each other
        var direction_to_enemy = (current_enemy.global_position - player_robot.global_position).normalized()
        var direction_to_player = (player_robot.global_position - current_enemy.global_position).normalized()
        
        # Move player robot
        player_robot.velocity = direction_to_enemy * approach_speed
        player_robot.move_and_slide()
        
        # Move enemy
        current_enemy.velocity = direction_to_player * approach_speed
        current_enemy.move_and_slide()
    else:
        # Close enough, start fighting
        print("CombatView: Robots in range, starting fight phase")
        current_phase = CombatPhase.FIGHTING
        
        # Activate combat for both robots
        player_robot.start_combat()
        if current_enemy is Enemy:
            current_enemy.activate()
            current_enemy.set_target(player_robot)

# Handle active fighting phase
func process_fighting_phase(_delta):
    # Check if combat should end
    if not player_robot or not current_enemy:
        end_combat(false)
        return
    
    if player_robot.is_defeated():
        end_combat(false)  # Player lost
        return
    
    if current_enemy is Enemy and current_enemy.is_defeated():
        end_combat(true)   # Player won
        return
    
    # Combat continues - robots handle their own AI in their _physics_process

# End combat and show results
func end_combat(victory: bool):
    print("CombatView: Combat ended. Victory: ", victory)
    
    combat_active = false
    current_phase = CombatPhase.FINISHED
    
    # Stop robot combat
    if player_robot:
        player_robot.end_combat()
    
    # For enemy, delay queue_free to allow death animation to be visible
    # This is especially important for victory, as the enemy has already played the animation
    if current_enemy and is_instance_valid(current_enemy):
        # Don't immediately remove the enemy
        var timer = get_tree().create_timer(2.0)
        await timer.timeout
        if is_instance_valid(current_enemy):
            current_enemy.queue_free()
            current_enemy = null
    
    # Emit result signal
    emit_signal("combat_finished", victory)
    
    # Show reward screen after a brief delay (longer now to account for death animation)
    await get_tree().create_timer(1.5).timeout
    if victory:
        emit_signal("show_reward_screen")

# Signal handlers
func _on_player_defeated():
    print("CombatView: Player robot defeated")
    end_combat(false)

func _on_enemy_defeated():
    print("CombatView: Enemy defeated")
    # end_combat(true)

func _on_start_combat_pressed():
    print("CombatView: Start combat button pressed")
    # Play click sound
    Sound.play_click()
    # This should be called by the GameManager with a properly built robot

# Utility functions
func hide_combat_view():
    visible = false
    
    # Clean up any active combat
    if combat_active:
        end_combat(false)

# Show combat effect at entity position
func show_combat_effect(effect_type: String, entity):
    if effects_layer and is_instance_valid(entity):
        effects_layer.show_effect(effect_type, entity.global_position)

# Show damage numbers
func show_damage_number(amount: int, entity):
    if effects_layer and is_instance_valid(entity):
        effects_layer.show_damage_number(amount, entity.global_position)

# Fire a projectile from source to target
func fire_projectile(source, target_pos: Vector2, damage: int, range_value: float = 200.0):
    if not bullet_scene:
        return
    
    # Create bullet instance
    var bullet = bullet_scene.instantiate()
    add_child(bullet)
    
    # Position at source
    bullet.global_position = source.global_position
    
    # Setup bullet properties
    bullet.setup(source, target_pos, damage, range_value)
    
    # Connect hit signal
    bullet.hit_target.connect(_on_bullet_hit_target)
    
    return bullet

func _on_bullet_hit_target(target):
    if target:
        # Show hit effect
        show_combat_effect("range_attack", target)

# Signal handlers for robot part usage and damage
func _on_robot_part_used(slot_name: String):
    Log.pr("[CombatView] _on_robot_part_used called for slot:", slot_name)
    if combat_robot_frame:
        combat_robot_frame.show_part_usage(slot_name)
    
    # Create a parts dictionary to emit with the chassis_updated signal
    var parts_dict = {}
    if player_robot:
        parts_dict = {
            "head": player_robot.head,
            "core": player_robot.core,
            "left_arm": player_robot.left_arm,
            "right_arm": player_robot.right_arm,
            "legs": player_robot.legs,
            "utility": player_robot.utility
        }
    
    # Emit chassis_updated signal for any listeners
    Log.pr("[CombatView] Emitting chassis_updated signal")
    emit_signal("chassis_updated", parts_dict)

func _on_robot_part_damaged(slot_name: String, current_durability: int):
    Log.pr("[CombatView] _on_robot_part_damaged called - slot:", slot_name, "durability:", current_durability)
    if combat_robot_frame:
        combat_robot_frame.update_part_durability(slot_name, current_durability)
        combat_robot_frame.show_part_damage(slot_name)
    
    # Create a parts dictionary to emit with the chassis_updated signal
    var parts_dict = {}
    if player_robot:
        parts_dict = {
            "head": player_robot.head,
            "core": player_robot.core,
            "left_arm": player_robot.left_arm,
            "right_arm": player_robot.right_arm,
            "legs": player_robot.legs,
            "utility": player_robot.utility
        }
    
    # Update the card data in ChassisManager to reflect the durability changes
    if chassis_manager and chassis_manager.has_method("update_part_durability"):       
        chassis_manager.update_part_durability(slot_name, current_durability)
    
    # Emit chassis_updated signal for any listeners
    Log.pr("[CombatView] Emitting chassis_updated signal after part damage")
    emit_signal("chassis_updated", parts_dict)

# Get the status of the combat robot frame
func get_robot_frame_status() -> String:
    var status = "Combat Status:\n"
    
    if not combat_robot_frame or not player_robot:
        return status + "No robot data available."
    
    status += "Heat: " + str(player_robot.current_heat) + "/" + str(player_robot.max_heat) + "\n"
    
    # Add more status information as needed
    
    return status

func get_combat_status() -> String:
    if not combat_active:
        return "Combat Inactive"
    
    var status = "Phase: " + CombatPhase.keys()[current_phase]
    status += " | Time: " + str(round(combat_timer * 10) / 10) + "s"
    
    if player_robot:
        status += " | Player: " + player_robot.get_status_summary()
    
    if current_enemy and current_enemy is Enemy:
        status += " | Enemy: " + str(current_enemy.hp) + "/" + str(current_enemy.max_hp) + " HP"
    
    return status
