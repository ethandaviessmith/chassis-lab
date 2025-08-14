extends Node2D
class_name CombatEffects

# Combat indicators with emojis
const INDICATORS = {
    "melee_attack": "🗡️",  # Melee attack
    "range_attack": "🏹",   # Ranged attack
    "shield": "🛡️",         # Shield/defense
    "heal": "❤️",           # Healing
    "overheat": "🔥",       # Overheating
    "cooldown": "❄️",       # Cooling down
}

func show_effect(effect_type: String, target_position: Vector2):
    if not INDICATORS.has(effect_type):
        return
    
    # Create indicator label
    var indicator = Label.new()
    indicator.text = INDICATORS[effect_type]
    indicator.add_theme_font_size_override("font_size", 32)
    
    # Position slightly above target
    indicator.global_position = target_position + Vector2(0, -30)
    
    # Add to scene
    add_child(indicator)
    
    # Animate and remove
    var tween = create_tween()
    tween.tween_property(indicator, "position", indicator.position + Vector2(0, -20), 1.0)
    tween.parallel().tween_property(indicator, "modulate:a", 0.0, 1.0)
    tween.tween_callback(indicator.queue_free)

func show_damage_number(amount: int, target_position: Vector2):
    # Create damage number label
    var damage_label = Label.new()
    damage_label.text = str(amount)
    damage_label.add_theme_font_size_override("font_size", 20)
    
    if amount >= 5:
        damage_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))  # Red for high damage
    else:
        damage_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))  # Orange for normal damage
    
    # Position slightly above target and random x offset for variation
    var rand_x = randf_range(-15, 15)
    damage_label.global_position = target_position + Vector2(rand_x, -20)
    
    # Add to scene
    add_child(damage_label)
    
    # Animate and remove
    var tween = create_tween()
    tween.tween_property(damage_label, "position", damage_label.position + Vector2(0, -30), 0.8)
    tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 0.8)
    tween.tween_callback(damage_label.queue_free)
