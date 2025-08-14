extends Node2D
class_name CombatEffectsLayer

# Effect prefabs - could be replaced with actual scenes later
var effect_duration = 0.5
var damage_number_duration = 1.0
var effect_animations = {}

func _ready():
    pass

# Show an effect at a given position
func show_effect(effect_type: String, effect_position: Vector2):
    var container = Node2D.new()
    var effect_node = Label.new()
    add_child(container)
    container.add_child(effect_node)
    container.position = effect_position
    
    # Center the label
    effect_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    effect_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    
    # Set up effect appearance based on type
    match effect_type:
        "melee_attack":
            effect_node.text = "⚔️"
            effect_node.add_theme_font_size_override("font_size", 24)
            animate_effect(container, Vector2(20, -20))
        "range_attack":
            effect_node.text = "🏹"
            effect_node.add_theme_font_size_override("font_size", 24)
            animate_effect(container, Vector2(0, -30))
        "shield":
            effect_node.text = "🛡️"
            effect_node.add_theme_font_size_override("font_size", 24)
            animate_effect(container, Vector2(0, -20))
        "heal":
            effect_node.text = "💚"
            effect_node.add_theme_font_size_override("font_size", 24)
            animate_effect(container, Vector2(0, -30))
        "overheat":
            effect_node.text = "🔥"
            effect_node.add_theme_font_size_override("font_size", 32)
            animate_effect(container, Vector2(0, -20))
        "cooldown":
            effect_node.text = "❄️"
            effect_node.add_theme_font_size_override("font_size", 24)
            animate_effect(container, Vector2(0, -20))
        _:
            # Default effect
            effect_node.text = "✨"
            effect_node.add_theme_font_size_override("font_size", 24)
            animate_effect(container, Vector2(0, -20))

# Show damage numbers
func show_damage_number(amount: int, effect_position: Vector2):
    var container = Node2D.new()
    var number_node = Label.new()
    add_child(container)
    container.add_child(number_node)
    container.position = effect_position + Vector2(0, -30)  # Show above target
    
    # Center the label
    number_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    number_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    
    # Format based on amount
    if amount <= 0:
        number_node.text = "MISS"
        number_node.modulate = Color(0.7, 0.7, 0.7)  # Gray
    elif amount < 3:
        number_node.text = str(amount)
        number_node.modulate = Color(1, 0.8, 0)  # Gold
    elif amount < 5:
        number_node.text = str(amount) + "!"
        number_node.modulate = Color(1, 0.5, 0)  # Orange
    else:
        number_node.text = str(amount) + "!!"
        number_node.modulate = Color(1, 0, 0)  # Red
    
    number_node.add_theme_font_size_override("font_size", 20 + min(amount * 2, 16))  # Size based on damage
    
    # Animate the damage number
    animate_damage_number(container)

# Animate effect appearance and removal
func animate_effect(effect_node: Node2D, offset: Vector2):
    var tween = create_tween()
    
    # Starting properties
    effect_node.modulate.a = 0
    effect_node.scale = Vector2(0.5, 0.5)
    
    # Fade in and expand
    tween.tween_property(effect_node, "modulate:a", 1.0, 0.1)
    tween.parallel().tween_property(effect_node, "scale", Vector2(1.2, 1.2), 0.1)
    
    # Move in direction
    tween.tween_property(effect_node, "position", effect_node.position + offset, effect_duration)
    
    # Fade out
    tween.tween_property(effect_node, "modulate:a", 0.0, 0.2)
    
    # Remove after animation
    tween.tween_callback(effect_node.queue_free)

# Animate damage number appearance and removal
func animate_damage_number(number_node: Node2D):
    var tween = create_tween()
    
    # Starting properties
    number_node.modulate.a = 0
    number_node.scale = Vector2(0.5, 0.5)
    
    # Fade in and expand
    tween.tween_property(number_node, "modulate:a", 1.0, 0.1)
    tween.parallel().tween_property(number_node, "scale", Vector2(1.2, 1.2), 0.1)
    
    # Float upward
    tween.tween_property(number_node, "position", number_node.position + Vector2(0, -40), damage_number_duration)
    
    # Fade out near the end
    tween.tween_property(number_node, "modulate:a", 0.0, 0.3)
    
    # Remove after animation
    tween.tween_callback(number_node.queue_free)
