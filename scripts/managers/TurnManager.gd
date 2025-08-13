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

func _ready():
    # Initialize energy for the first turn (but don't start turn yet)
    current_energy = max_energy
    _update_energy_display()

func initialize():
    # Call this to start the first turn properly
    start_turn()

func set_energy_label(label: Label):
    energy_label = label
    _update_energy_display()

func start_turn():
    # Reset energy to max at start of turn
    current_energy = max_energy
    emit_signal("energy_changed", current_energy, max_energy)
    _update_energy_display()
    emit_signal("turn_started")
    
    # Draw new hand
    var deck_manager = get_node_or_null("../DeckManager")
    if deck_manager:
        deck_manager.draw_hand()

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
        # TODO: Add build animation sequence here
        # await robot_frame.play_build_animation()
    else:
        print("Warning: No RobotFrame assigned, visual building will be skipped")
    
    # Build combat robot stats
    if robot_fighter:
        robot_fighter.build_from_chassis(attached_parts)
    else:
        print("Warning: No RobotFighter assigned, combat stats will not be updated")
    
    print("Robot build complete! Starting combat phase...")
    
    # Tell GameManager to start combat phase
    if game_manager and game_manager.has_method("start_combat_phase"):
        game_manager.start_combat_phase()
    else:
        print("Warning: No GameManager provided or missing start_combat_phase method")
