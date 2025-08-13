extends CharacterBody2D
class_name Robot

signal robot_updated

# Resources
var energy: int = 10  # Health/energy combined
var max_energy: int = 10
var heat: int = 0
var max_heat: int = 10

# Stats
var move_speed: float = 100.0
var attack_speed: float = 1.0
var armor: int = 0

# Parts
var head = null
var core = null
var left_arm = null
var right_arm = null
var legs = null

# Part effects cache
var effects = {}

# References
@onready var head_sprite = $Sprite/HeadSprite
@onready var core_sprite = $Sprite/CoreSprite
@onready var left_arm_sprite = $Sprite/LeftArmSprite
@onready var right_arm_sprite = $Sprite/RightArmSprite
@onready var legs_sprite = $Sprite/LegsSprite
@onready var health_bar = $HealthBar
@onready var heat_bar = $HeatBar

func _ready():
    update_visuals()
    update_bars()

func _physics_process(_delta):
    var combat_resolver = get_node("/root/Managers/CombatResolver")
    if combat_resolver.combat_active:
        process_combat_behavior()

# Called during combat
func process_combat_behavior():
    var target = find_target()
    if target:
        move_toward_target(target)
        try_attack(target)

func find_target():
    # Default targeting - can be overridden by head parts
    var enemies = get_tree().get_nodes_in_group("enemies")
    if enemies.size() > 0:
        return enemies[0]  # Just get first enemy
    return null

func move_toward_target(target):
    var direction = (target.global_position - global_position).normalized()
    velocity = direction * move_speed
    
    # Apply modifiers from parts
    if heat >= 8:
        velocity *= 0.8  # Slow down when overheating
    
    move_and_slide()

func try_attack(_target):
    # Implement attacking logic
    # Will be called every physics frame, but attacks will be rate-limited by attack speed
    # Actual implementation will depend on arms equipped
    pass

func attach_part(part, slot: String):
    match slot:
        "head":
            head = part
            head_sprite.texture = part.sprite
        "core":
            core = part
            core_sprite.texture = part.sprite
        "left_arm":
            left_arm = part
            left_arm_sprite.texture = part.sprite
        "right_arm":
            right_arm = part
            right_arm_sprite.texture = part.sprite
        "legs":
            legs = part
            legs_sprite.texture = part.sprite
    
    # Update robot stats based on part
    apply_part_effects(part)
    update_visuals()
    emit_signal("robot_updated")

func remove_part(part):
    if head == part:
        head = null
        head_sprite.texture = null
    elif core == part:
        core = null
        core_sprite.texture = null
    elif left_arm == part:
        left_arm = null
        left_arm_sprite.texture = null
    elif right_arm == part:
        right_arm = null
        right_arm_sprite.texture = null
    elif legs == part:
        legs = null
        legs_sprite.texture = null
    
    # Remove part effects
    remove_part_effects(part)
    update_visuals()
    emit_signal("robot_updated")

func apply_part_effects(part):
    # Apply stat changes from part
    for effect in part.effects:
        match effect.type:
            "max_energy":
                max_energy += effect.value
                energy += effect.value  # Also increase current energy
            "max_heat":
                max_heat += effect.value
            "armor":
                armor += effect.value
            "move_speed_percent":
                move_speed *= (1 + effect.value / 100.0)
            "attack_speed_percent":
                attack_speed *= (1 + effect.value / 100.0)
    
    # Store effects for later removal
    effects[part] = part.effects

func remove_part_effects(part):
    # Remove previously applied effects
    if part in effects:
        var part_effects = effects[part]
        for effect in part_effects:
            match effect.type:
                "max_energy":
                    max_energy -= effect.value
                "max_heat":
                    max_heat -= effect.value
                "armor":
                    armor -= effect.value
                "move_speed_percent":
                    move_speed /= (1 + effect.value / 100.0)
                "attack_speed_percent":
                    attack_speed /= (1 + effect.value / 100.0)
        
        # Remove from effects cache
        effects.erase(part)

func get_parts() -> Array:
    var parts = []
    if head:
        parts.append(head)
    if core:
        parts.append(core)
    if left_arm:
        parts.append(left_arm)
    if right_arm:
        parts.append(right_arm)
    if legs:
        parts.append(legs)
    return parts

func take_damage(amount: int):
    energy -= amount
    update_bars()
    
    # Check for defeat
    if energy <= 0:
        energy = 0
        # Will be handled by combat resolver

func heal(amount: int):
    energy = min(energy + amount, max_energy)
    update_bars()

func add_heat(amount: int):
    heat = min(heat + amount, max_heat)
    update_bars()
    
    # Report heat change for potential overheat
    var combat_resolver = get_node("/root/Managers/CombatResolver")
    if combat_resolver:
        combat_resolver.update_robot_heat(heat)

func reduce_heat(amount: int):
    heat = max(0, heat - amount)
    update_bars()
    
    # Report heat change
    var combat_resolver = get_node("/root/Managers/CombatResolver")
    if combat_resolver:
        combat_resolver.update_robot_heat(heat)

func get_armor() -> int:
    return armor

func is_defeated() -> bool:
    return energy <= 0

func update_visuals():
    # Update sprites based on attached parts
    pass

func update_bars():
    if health_bar:
        health_bar.value = 100.0 * energy / max_energy
    
    if heat_bar:
        heat_bar.value = 100.0 * heat / max_heat
        
        # Update heat bar color
        if heat >= 10:
            heat_bar.modulate = Color(1, 0, 0)  # Red for overheat
        elif heat >= 8:
            heat_bar.modulate = Color(1, 0.5, 0)  # Orange for high heat
        else:
            heat_bar.modulate = Color(1, 0.8, 0)  # Yellow-orange normal
