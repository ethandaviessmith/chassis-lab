@tool
extends Control
class_name StatDisplay

# Spacing and styling constants
const STAT_ICON_SIZE = Vector2(16, 16)
const PIP_SIZE = Vector2(8, 12)   # Width, Height of each pip
const PIP_SPACING = 1            # Horizontal spacing between pips
const PIP_OUTLINE = 1            # Outline thickness for pips (set to 0 for no outline)
const MAX_PIPS_PER_ROW = 10      # Always show 10 pips per stat
const ROW_SPACING = 16           # Vertical spacing between stat rows
const LABEL_OFFSET = Vector2(0, 0)  # Label position adjustment

# Mapping of stat names to their max values and colors
const STAT_CONFIG = {
    "damage": {"max": 20, "color": Color(1, 0.5, 0.5), "icon": "⚔️", "label": "DMG"},
    "armor": {"max": 20, "color": Color(0.5, 0.5, 1), "icon": "🛡️", "label": "ARM"}, 
    "speed": {"max": 200, "color": Color(0.5, 1, 0.5), "icon": "👟", "label": "SPD"},
    "crit_chance": {"max": 30, "color": Color(1, 1, 0.5), "icon": "⚡", "label": "CRT"},
    "attack_speed": {"max": 2, "color": Color(1, 0.8, 0.2), "icon": "🔄", "label": "APS"},
    "dodge_chance": {"max": 30, "color": Color(0.7, 1, 1), "icon": "💨", "label": "EVA"},
    "heat_capacity": {"max": 20, "color": Color(1, 0.3, 0.3), "icon": "🔥", "label": "🔥Cap"},
    "heat_dissipation": {"max": 5, "color": Color(0.3, 0.7, 1), "icon": "❄️", "label": "🔥Cool"},
}

# UI elements
var stat_icons = {}
var stat_labels = {}
var stat_pip_containers = {}
var stat_pips = {}

# Reference to StatManager - using generic Node to avoid dependency issues
@export var stat_manager: StatManager

# Default stats for editor preview
@export var show_preview_in_editor: bool = true
@export_group("Preview Stats")
@export var preview_damage: int = 5
@export var preview_armor: int = 3
@export var preview_speed: int = 100
@export var preview_crit_chance: int = 10
@export var preview_attack_speed: float = 1.2
@export var preview_dodge_chance: int = 5
@export var preview_heat_capacity: int = 12
@export var preview_heat_dissipation: int = 2

# Current stats
var current_stats = {}
var hovering = false
var hover_preview = null

func _enter_tree():
    # Set up UI when entering the tree (works in editor)
    setup_ui()
    
    # Show preview in editor
    if Engine.is_editor_hint() and show_preview_in_editor:
        _show_editor_preview()

func _ready():
    # Only run game code when not in editor
    if not Engine.is_editor_hint():
        # Connect to stat manager signals if available
        if stat_manager:
            stat_manager.stats_updated.connect(_on_stats_updated)
            stat_manager.stat_hover_preview.connect(_on_stat_hover_preview)
            stat_manager.stat_hover_ended.connect(_on_stat_hover_ended)

# Show preview values in the editor
func _show_editor_preview():
    var preview_stats = {
        "damage": preview_damage,
        "armor": preview_armor,
        "speed": preview_speed,
        "crit_chance": preview_crit_chance,
        "attack_speed": preview_attack_speed,
        "dodge_chance": preview_dodge_chance,
        "heat_capacity": preview_heat_capacity,
        "heat_dissipation": preview_heat_dissipation
    }
    update_display(preview_stats)

# Set up the UI elements
func setup_ui():
    # Create containers for each stat
    var y_offset = 10
    
    for stat_name in STAT_CONFIG:
        # Create container for this stat row
        var row_container = HBoxContainer.new()
        row_container.name = stat_name + "Container"
        row_container.position = Vector2(10, y_offset)
        row_container.size.x = size.x - 20
        row_container.alignment = BoxContainer.ALIGNMENT_CENTER
        add_child(row_container)
        
        # Create a fixed size container for the label
        var label_container = Control.new()
        label_container.custom_minimum_size = Vector2(70, PIP_SIZE.y + (PIP_OUTLINE * 2))
        row_container.add_child(label_container)
        
        # Create label for this stat
        var label = Label.new()
        label.text = STAT_CONFIG[stat_name].label
        label.add_theme_font_size_override("font_size", 12)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.size = Vector2(70, PIP_SIZE.y + (PIP_OUTLINE * 2))
        label.position = LABEL_OFFSET
        label_container.add_child(label)
        stat_labels[stat_name] = label
        
        # Create pip container with fixed size
        var pip_container = HBoxContainer.new()
        pip_container.name = stat_name + "Pips"
        # Calculate size for container, accounting for pip size, outline and spacing
        var pip_width_with_outline = PIP_SIZE.x + (PIP_OUTLINE * 2)
        var pip_height_with_outline = PIP_SIZE.y + (PIP_OUTLINE * 2)
        pip_container.custom_minimum_size = Vector2(
            MAX_PIPS_PER_ROW * (pip_width_with_outline + PIP_SPACING) - PIP_SPACING,
            pip_height_with_outline
        )
        pip_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        pip_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        row_container.add_child(pip_container)
        stat_pip_containers[stat_name] = pip_container
        stat_pips[stat_name] = []
        
        y_offset += ROW_SPACING
    
    # Update the overall container size
    size.y = y_offset + 10

# Update the display with new stats
func update_display(stats: Dictionary):
    current_stats = stats
    
    for stat_name in STAT_CONFIG:
        if stats.has(stat_name):
            update_stat_pips(stat_name, stats[stat_name])

# Update the pips for a single stat
func update_stat_pips(stat_name: String, value):
    # Calculate how many pips to show
    var config = STAT_CONFIG[stat_name]
    var max_value = config.max
    var pip_color = config.color
    
    # For percentage values (like attack_speed), convert to a 0-10 scale
    var normalized_value
    if stat_name == "attack_speed":
        normalized_value = clamp(value * 5, 0, 10)  # Scale 0-2 to 0-10
    elif stat_name == "speed":
        normalized_value = clamp(value / 20, 0, 10)  # Scale 0-200 to 0-10
    else:
        # For integer values, normalize to a 0-10 scale
        normalized_value = clamp((value * 10.0) / max_value, 0, 10)
    
    # If we're initializing for the first time, create all 10 pips
    if stat_pips[stat_name].size() == 0:
        _initialize_pips(stat_name, pip_color)
    
    # Update pip fill states based on normalized value
    _update_pip_fill_states(stat_name, normalized_value, pip_color)
    
    # Update the label with the actual value
    if stat_labels.has(stat_name):
        var display_value
        if stat_name == "crit_chance" or stat_name == "dodge_chance":
            display_value = str(int(value)) + "%"
        elif stat_name == "attack_speed":
            display_value = str(snapped(value, 0.1))
        else:
            display_value = str(value)
        stat_labels[stat_name].text = STAT_CONFIG[stat_name].label + ": " + display_value

# Initialize 10 empty pips for a stat
func _initialize_pips(stat_name: String, color: Color):
    # Clear existing pips if any
    for pip in stat_pips[stat_name]:
        pip.queue_free()
    stat_pips[stat_name].clear()
    
    # Create a container for the pips with proper spacing
    var pip_row = HBoxContainer.new()
    pip_row.add_theme_constant_override("separation", PIP_SPACING)
    stat_pip_containers[stat_name].add_child(pip_row)
    
    # Create 10 empty pips
    for i in range(MAX_PIPS_PER_ROW):
        # Create a container for the pip if we want an outline
        var pip_container
        if PIP_OUTLINE > 0:
            # Use a Control with a child ColorRect for the border instead of Panel with StyleBox
            pip_container = Control.new()
            pip_container.custom_minimum_size = PIP_SIZE + Vector2(PIP_OUTLINE * 2, PIP_OUTLINE * 2)
            
            # Create border as a black ColorRect background
            var border = ColorRect.new()
            border.color = Color(0.1, 0.1, 0.1, 1.0)  # Dark outline
            border.size = pip_container.custom_minimum_size
            border.position = Vector2.ZERO
            pip_container.add_child(border)
        else:
            # If no outline, just use a container
            pip_container = Control.new()
            pip_container.custom_minimum_size = PIP_SIZE
        
        # Create the actual pip (background)
        var pip = ColorRect.new()
        pip.custom_minimum_size = PIP_SIZE
        pip.size = PIP_SIZE
        pip.color = color.darkened(0.7)  # Start with darkened/faded color
        
        # For outlined pips, position properly
        if PIP_OUTLINE > 0:
            pip.position = Vector2(PIP_OUTLINE, PIP_OUTLINE)
            pip_container.add_child(pip)
        else:
            pip_container = pip  # If no outline, the pip is the container
        
        # Store a filled part reference in each pip for later updates
        var filled_part = ColorRect.new()
        filled_part.size = Vector2(PIP_SIZE.x, 0)  # Zero height initially
        filled_part.position = Vector2(0, PIP_SIZE.y)  # Start at the bottom
        filled_part.color = color
        filled_part.name = "FilledPart"
        pip.add_child(filled_part)
        
        # Add to container and store reference
        pip_row.add_child(pip_container)
        stat_pips[stat_name].append(pip)

# Update the fill state of each pip based on the normalized value
func _update_pip_fill_states(stat_name: String, normalized_value: float, _color: Color):
    var full_pips = int(normalized_value)
    var partial_pip_value = normalized_value - full_pips
    
    # Create a tween for smooth animation
    var tween = create_tween()
    tween.set_parallel(true)  # Update all pips in parallel
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    
    for i in range(stat_pips[stat_name].size()):
        var pip = stat_pips[stat_name][i]
        var filled_part = pip.get_node("FilledPart")
        
        if i < full_pips:
            # Fully filled pip
            tween.tween_property(filled_part, "size:y", PIP_SIZE.y, 0.3)
            tween.tween_property(filled_part, "position:y", 0, 0.3)
        elif i == full_pips and partial_pip_value > 0:
            # Partial pip
            var new_height = PIP_SIZE.y * partial_pip_value
            var new_position = PIP_SIZE.y - new_height
            tween.tween_property(filled_part, "size:y", new_height, 0.3)
            tween.tween_property(filled_part, "position:y", new_position, 0.3)
        else:
            # Empty pip
            tween.tween_property(filled_part, "size:y", 0, 0.3)
            tween.tween_property(filled_part, "position:y", PIP_SIZE.y, 0.3)

# Handle stat updates from StatManager
func _on_stats_updated(stats):
    update_display(stats)

# Handle hover preview
func _on_stat_hover_preview(_stats, preview_data):
    hovering = true
    hover_preview = preview_data
    
    # Show the preview differences
    for stat_name in STAT_CONFIG:
        if preview_data.differences.has(stat_name):
            var difference = preview_data.differences[stat_name]
            
            # Update label to show the difference
            if stat_labels.has(stat_name):
                var display_value = preview_data.preview[stat_name]
                var display_diff = difference
                
                if stat_name == "crit_chance" or stat_name == "dodge_chance":
                    display_value = str(int(display_value)) + "%"
                    display_diff = str(int(difference)) + "%"
                
                var diff_text = ""
                if difference > 0:
                    diff_text = " (+%s)" % str(display_diff)
                elif difference < 0:
                    diff_text = " (%s)" % str(display_diff)
                    
                stat_labels[stat_name].text = STAT_CONFIG[stat_name].label + ": " + str(display_value) + diff_text
                
                # Highlight the label based on whether the change is positive or negative
                if difference > 0:
                    stat_labels[stat_name].add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
                elif difference < 0:
                    stat_labels[stat_name].add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))

# Handle end of hover
func _on_stat_hover_ended():
    hovering = false
    hover_preview = null
    
    # Reset display to current stats
    update_display(current_stats)
    
    # Reset label colors
    for stat_name in stat_labels:
        stat_labels[stat_name].remove_theme_color_override("font_color")
