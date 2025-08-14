extends Control
class_name EnergyBar

signal energy_changed(current_energy, max_energy)

# UI References - these will be found automatically by name
@onready var background: ColorRect = $Background
@onready var fill: ColorRect = $Fill
@onready var energy_label: Label = $EnergyLabel

# Energy values
var current_energy: int = 4
var max_energy: int = 4

func _ready():
    update_display()

func set_energy(current: int, maximum: int):
    current_energy = current
    max_energy = maximum
    update_display()
    emit_signal("energy_changed", current_energy, max_energy)

func update_display():
    if not fill or not energy_label:
        return
        
    # Calculate fill percentage
    var fill_percentage = float(current_energy) / float(max_energy) if max_energy > 0 else 0.0
    
    # Update the fill bar height (fill from bottom)
    fill.anchor_top = 1.0 - fill_percentage
    
    # Update the label text
    energy_label.text = str(current_energy) + "/" + str(max_energy)
    
    # Color the fill based on energy level
    if fill_percentage > 0.6:
        fill.color = Color(0.2, 0.6, 1.0)  # Blue
    elif fill_percentage > 0.3:
        fill.color = Color(0.8, 0.8, 0.2)  # Yellow
    else:
        fill.color = Color(1.0, 0.4, 0.2)  # Red

func get_current_energy() -> int:
    return current_energy

func get_max_energy() -> int:
    return max_energy
