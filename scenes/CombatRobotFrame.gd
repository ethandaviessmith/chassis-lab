extends Control
class_name CombatRobotFrame

signal part_clicked(part_name)

# Reference to the robot frame
@onready var robot_frame = $RobotFrame

# Part data
var part_data = {
    "head": null,
    "core": null,
    "left_arm": null, 
    "right_arm": null,
    "legs": null,
    "utility": null
}

func _ready():
    # Make sure robot frame is configured for showing durability
    if robot_frame:
        robot_frame.show_durability = true
        
        # Connect signals from robot frame
        if robot_frame.has_signal("part_clicked"):
            if not robot_frame.part_clicked.is_connected(_on_robot_frame_part_clicked):
                robot_frame.part_clicked.connect(_on_robot_frame_part_clicked)
    
    # Initialize with empty frames
    reset_all_parts()

# Initialize from a PlayerRobot
func initialize_from_robot(robot: PlayerRobot):
    if not robot:
        reset_all_parts()
        return
    
    # Store parts data
    part_data = {
        "head": robot.head,
        "core": robot.core,
        "left_arm": robot.left_arm,
        "right_arm": robot.right_arm,
        "legs": robot.legs,
        "utility": robot.utility
    }
    
    # Create part objects for robot frame
    var parts_for_frame = {}
    
    for slot_name in part_data.keys():
        var part = part_data[slot_name]
        if part:
            # Convert part to format expected by RobotFrame
            var part_data_for_frame = create_part_data_for_frame(part, slot_name)
            parts_for_frame[slot_name] = part_data_for_frame
    
    # Update robot frame with parts
    for slot_name in parts_for_frame:
        robot_frame.attach_part_visual(parts_for_frame[slot_name], slot_name)

# Helper function to create part data from a Part object for RobotFrame
func create_part_data_for_frame(part, _slot_name: String):
    if part is Part:
        var frame_data = {
            "name": part.name,
            "type": part.type,
            "frame_index": part.frame if part.frame != null else 0,
            "durability": part.durability,
            "current_durability": part.durability
        }
        return frame_data
    elif part is Dictionary:
        return part
    return null

# Reset all parts to empty
func reset_all_parts():
    part_data = {
        "head": null,
        "core": null,
        "left_arm": null, 
        "right_arm": null,
        "legs": null,
        "utility": null
    }
    
    if robot_frame:
        robot_frame.clear_all_parts()

# Update durability display for a specific part
func update_part_durability(slot_name: String, current_durability: int):
    var part = part_data[slot_name]
    if not part:
        return
    
    # Store the updated durability
    if part is Part:
        part.durability = current_durability
    elif part is Dictionary:
        part.durability = current_durability
    
    # Update the visual pips in robot frame
    if robot_frame:
        robot_frame.update_part_durability(slot_name, current_durability)

# Handle part clicked signal from robot frame
func _on_robot_frame_part_clicked(slot_name: String):
    emit_signal("part_clicked", slot_name)

# Show damage effect on a part
func show_part_damage(slot_name: String):
    if robot_frame:
        robot_frame.show_part_damage(slot_name)

# Show part usage effect
func show_part_usage(slot_name: String):
    if robot_frame:
        robot_frame.show_part_usage(slot_name)

# Show part overheating effect
func show_part_overheat(slot_name: String):
    if robot_frame:
        robot_frame.show_part_overheat(slot_name)

# Update the frame from a dictionary of parts - to be used with the chassis_updated signal
func update_from_parts_dict(parts_dict: Dictionary):
    # Store the new parts data
    part_data = {
        "head": parts_dict.get("head"),
        "core": parts_dict.get("core"),
        "left_arm": parts_dict.get("arm_left"),
        "right_arm": parts_dict.get("arm_right"),
        "legs": parts_dict.get("legs"),
        "utility": parts_dict.get("utility")
    }
    
    # Create part objects for robot frame
    var parts_for_frame = {}
    
    for slot_name in part_data.keys():
        var part = part_data[slot_name]
        if part:
            # Convert part to format expected by RobotFrame
            var part_data_for_frame = create_part_data_for_frame(part, slot_name)
            parts_for_frame[slot_name] = part_data_for_frame
    
    # Update robot frame with parts
    for slot_name in parts_for_frame:
        robot_frame.attach_part_visual(parts_for_frame[slot_name], slot_name)
