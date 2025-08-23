extends Node
class_name HeatManager

signal heat_updated(heat_data)
signal overheated
signal heat_threshold_reached(threshold_percent)

# Configuration
var base_scrapper_heat: int = 2
var heat_warning_threshold: float = 0.8

# Current state
var needed_heat: int = 0
var available_heat: int = 0
var max_heat: int = 10

func calculate_heat(attached_parts: Dictionary) -> Dictionary:
    # Calculate heat needed by parts and provided by scrapper
    needed_heat = 0
    var scrapper_heat = 0
    if attached_parts:
        for slot_name in ["head", "core", "arm_left", "arm_right", "legs", "utility"]:
            if attached_parts.has(slot_name):
                var card = attached_parts[slot_name]
                if card and card.data and card.data.heat:
                    needed_heat += int(card.data.heat)
        if attached_parts.has("scrapper"):
            for card in attached_parts["scrapper"]:
                if card and card.data and card.data.heat:
                    scrapper_heat += int(card.data.heat)
    available_heat = scrapper_heat + base_scrapper_heat
    max_heat = max(10, needed_heat + available_heat)
    var heat_data = {
        "needed_heat": needed_heat,
        "available_heat": available_heat,
        "max_heat": max_heat,
        "has_enough_heat": available_heat >= needed_heat,
        "heat_percent": float(needed_heat) / max(1, max_heat),
        "overheated": needed_heat > available_heat
    }
    emit_signal("heat_updated", heat_data)
    if heat_data.heat_percent >= heat_warning_threshold and heat_data.heat_percent < 1.0:
        emit_signal("heat_threshold_reached", heat_data.heat_percent)
    elif heat_data.overheated:
        emit_signal("overheated")
    return heat_data
