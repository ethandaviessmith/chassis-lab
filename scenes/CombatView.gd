extends Node2D
class_name CombatView

signal combat_finished(victory: bool)
signal show_reward_screen

# Export references - set these in the editor
@export var player_spawn_point: Marker2D = null
@export var enemy_spawn_point: Marker2D = null
@export var combat_ui: Control = null
@export var start_combat_button: Button = null

# Internal references
var player_robot: RobotFighter = null
var current_enemy = null
var combat_active: bool = false
var combat_timer: float = 0.0

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
    
    # Hide this view initially (BuildView should be shown first)
    visible = false

func _process(delta):
    if combat_active:
        combat_timer += delta
        process_combat_phase(delta)

# Start combat with robot fighter built from chassis
func start_combat(robot_fighter: RobotFighter, enemy_data: Dictionary = {}):
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
    
    # Set up enemy
    spawn_enemy(enemy_data)
    
    # Initialize combat state
    current_phase = CombatPhase.SETUP
    combat_active = true
    combat_timer = 0.0
    
    # Show combat view
    visible = true
    
    # Connect robot signals
    if not player_robot.robot_defeated.is_connected(_on_player_defeated):
        player_robot.robot_defeated.connect(_on_player_defeated)
    
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
    current_enemy.initialize_from_data(enemy_data)
    
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
    
    # Clean up enemy
    if current_enemy and is_instance_valid(current_enemy):
        current_enemy.queue_free()
        current_enemy = null
    
    # Emit result signal
    emit_signal("combat_finished", victory)
    
    # Show reward screen after a brief delay
    await get_tree().create_timer(1.0).timeout
    if victory:
        emit_signal("show_reward_screen")

# Signal handlers
func _on_player_defeated():
    print("CombatView: Player robot defeated")
    end_combat(false)

func _on_enemy_defeated():
    print("CombatView: Enemy defeated")
    end_combat(true)

func _on_start_combat_pressed():
    print("CombatView: Start combat button pressed")
    # This should be called by the GameManager with a properly built robot

# Utility functions
func hide_combat_view():
    visible = false
    
    # Clean up any active combat
    if combat_active:
        end_combat(false)

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
