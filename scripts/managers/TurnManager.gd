extends Node
class_name TurnManager

signal energy_changed(new_value, max_value)
signal turn_started
signal turn_ended

var current_energy: int = 0
var max_energy: int = 4  # Default 4 energy per turn

# UI References (can be set from BuildView or Main scene)
var energy_label: Label = null

# Robot references - set these in the editor
@export var robot_frame: RobotFrame = null
@export var robot_fighter: RobotFighter = null
@export var enemy_manager: EnemyManager = null
@export var stat_manager: StatManager = null

func _ready():
    # Initialize energy for the first turn (but don't start turn yet)
    current_energy = max_energy
    _update_energy_display()
    
    # Connect to robot frame signals for real-time visual updates
    if robot_frame:
        robot_frame.connect("robot_frame_updated", _on_robot_frame_updated)
        print("TurnManager: Connected to robot_frame signals")
    
    # Try to find and connect to BuildView
    call_deferred("_connect_to_build_view")
    
    # Request next enemy from enemy manager
    if enemy_manager:
        enemy_manager.determine_next_enemy()

# Deferred connection to BuildView to ensure scene is ready
func _connect_to_build_view():
    var build_view = get_node_or_null("../../BuildView")
    if not build_view:
        build_view = get_node_or_null("../BuildView") 
    if not build_view:
        # Try to find BuildView in the scene tree
        var scene_root = get_tree().current_scene
        if scene_root:
            build_view = scene_root.find_child("BuildView", true, false)
    
    if build_view:
        connect_to_build_view(build_view)
    else:
        print("TurnManager: Warning - Could not find BuildView to connect to")

func initialize():
    # Call this to start the first turn properly
    start_turn()

# Handle real-time robot frame updates
func _on_robot_frame_updated():
    print("TurnManager: Robot frame updated - triggering visual refresh")
    # This gets called whenever the robot frame changes
    # We can add visual effects or animations here if needed

# Connect to BuildView to listen for chassis changes
func connect_to_build_view(build_view):
    if build_view and build_view.has_signal("chassis_updated"):
        build_view.connect("chassis_updated", _on_chassis_updated)
        print("TurnManager: Connected to BuildView chassis updates")

# Handle chassis updates from BuildView
func _on_chassis_updated(attached_parts):
    print("TurnManager: Chassis updated, refreshing robot visuals...")
    update_robot_visuals(attached_parts)

# Update robot visuals in real-time
func update_robot_visuals(attached_parts):
    # Update visual robot frame
    if robot_frame:
        robot_frame.build_robot_visuals(attached_parts)
    else:
        print("Warning: No RobotFrame assigned for visual updates")

func set_energy_label(label: Label):
    energy_label = label
    _update_energy_display()

func start_turn():
    # Reset energy to max at start of turn
    current_energy = max_energy
    emit_signal("energy_changed", current_energy, max_energy)
    _update_energy_display()
    emit_signal("turn_started")


func end_turn():
    emit_signal("turn_ended")
    start_turn()

func spend_energy(amount: int) -> bool:
    if amount > current_energy:
        print("Not enough energy! Need: ", amount, ", Have: ", current_energy)
        return false
    
    current_energy -= amount
    emit_signal("energy_changed", current_energy, max_energy)
    _update_energy_display()
    print("Spent ", amount, " energy. Remaining: ", current_energy)
    return true

func gain_energy(amount: int):
    var old_energy = current_energy
    current_energy = min(current_energy + amount, max_energy)  # Cap at max
    var actual_gained = current_energy - old_energy
    emit_signal("energy_changed", current_energy, max_energy)
    _update_energy_display()
    print("Gained ", actual_gained, " energy (", amount, " requested). Energy: ", old_energy, " -> ", current_energy)

func reset_energy():
    # Reset energy to maximum (useful for clearing chassis)
    var old_energy = current_energy
    current_energy = max_energy
    emit_signal("energy_changed", current_energy, max_energy)
    _update_energy_display()
    print("Energy reset from ", old_energy, " to ", current_energy, " (max)")

func set_max_energy(new_max: int):
    max_energy = new_max
    current_energy = min(current_energy, max_energy)  # Adjust current if over new max
    emit_signal("energy_changed", current_energy, max_energy)
    _update_energy_display()

func _update_energy_display():
    if energy_label:
        energy_label.text = "Energy: " + str(current_energy) + "/" + str(max_energy)

# Build robot before combat begins
func build_robot_and_start_combat(build_view, game_manager = null):
    print("Building robot from chassis...")
    
    # Get attached parts from BuildView
    var attached_parts = build_view.attached_parts
    
    if not robot_frame and not robot_fighter:
        print("Error: No robot components assigned! Please set robot_frame and robot_fighter in the editor.")
        return
    
    # Build visual robot in the frame (for animation)
    if robot_frame:
        robot_frame.build_robot_visuals(attached_parts)
    else:
        print("Warning: No RobotFrame assigned, visual building will be skipped")
    
    # Build combat robot stats
    if robot_fighter:
        robot_fighter.build_from_chassis(attached_parts)
    else:
        print("Warning: No RobotFighter assigned, combat stats will not be updated")
    
    # Discard remaining hand cards before combat
    var hand_manager = get_node_or_null("../HandManager")
    if hand_manager and hand_manager.has_method("discard_hand"):
        print("TurnManager: Discarding remaining hand cards before combat...")
        hand_manager.discard_hand()
    else:
        print("TurnManager: No HandManager found or missing discard_hand method")
    
    print("Robot build complete! Starting combat phase...")
    
    # Tell GameManager to start combat phase
    if game_manager and game_manager.has_method("start_combat_phase"):
        game_manager.start_combat_phase()
    else:
        print("Warning: No GameManager provided or missing start_combat_phase method")
