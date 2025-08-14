extends Control
class_name HeatBar

signal heat_changed(needed_heat, scrapper_heat)

# UI References - these will be found automatically by name
@onready var background: ColorRect = $Background
@onready var needed_fill: ColorRect = $NeededFill
@onready var scrapper_fill: ColorRect = $ScrapperFill
@onready var heat_label: Label = $HeatLabel

# Heat values
var needed_heat: int = 0
var scrapper_heat: int = 0
var max_heat: int = 10  # Default maximum for display scaling

func _ready():
    update_display()

func set_heat(needed: int, scrapper: int, maximum: int = 10):
    needed_heat = needed
    scrapper_heat = scrapper
    max_heat = maximum
    update_display()
    emit_signal("heat_changed", needed_heat, scrapper_heat)

func update_display():
    if not needed_fill or not scrapper_fill or not heat_label:
        return
        
    # Calculate fill percentages
    var needed_percentage = float(needed_heat) / float(max_heat) if max_heat > 0 else 0.0
    var scrapper_percentage = float(scrapper_heat) / float(max_heat) if max_heat > 0 else 0.0
    
    # Clamp percentages to 0-1 range
    needed_percentage = clamp(needed_percentage, 0.0, 1.0)
    scrapper_percentage = clamp(scrapper_percentage, 0.0, 1.0)
    
    # Update the needed heat fill bar (orange, fill from bottom)
    needed_fill.anchor_top = 1.0 - needed_percentage
    needed_fill.color = Color(1.0, 0.6, 0.2)  # Orange
    
    # Update the scrapper heat fill bar (red, fill from bottom)
    scrapper_fill.anchor_top = 1.0 - scrapper_percentage
    scrapper_fill.color = Color(1.0, 0.2, 0.2)  # Red
    
    # Update the label text
    heat_label.text = "N:" + str(needed_heat) + " S:" + str(scrapper_heat)
    
    # Make scrapper fill semi-transparent so both bars are visible when overlapping
    scrapper_fill.color.a = 0.8

func get_needed_heat() -> int:
    return needed_heat

func get_scrapper_heat() -> int:
    return scrapper_heat

func get_total_heat() -> int:
    return needed_heat + scrapper_heat

func set_max_heat(new_max: int):
    max_heat = new_max
    update_display()
