extends Node
class_name Part

# Signals
signal durability_changed(new_value, max_value)
signal part_broken(part)
signal part_enhanced(part)
signal part_exhausted(part)
signal effect_activated(effect)
signal stat_changed(stat_name, new_value)
signal heat_generated(amount)

# Basic part properties
var id: String = ""
var part_name: String = ""
var type: String = ""  # "head", "core", "arm", "legs", "utility", "scrapper"
var cost: int = 0
var heat: int = 0  # Heat generation
var energy_cost: int = 0
var durability: int = 1
var max_durability: int = 1
var frame: int = 0  # Sprite frame index
var manufacturer: String = ""
var rarity: String = "Common"
var description: String = ""
var image_path: String = ""

# Special flags and metadata
var is_enhanced: bool = false
var is_exhausted: bool = false
var attached_to_chassis: bool = false
var chassis_slot: String = ""
var instance_id: String = ""  # Unique identifier for tracking this part

# Battle stats that may be modified by effects
var damage: int = 0
var attack_speed: float = 1.0
var armor: int = 0
var crit_chance: float = 0.0
var energy_capacity: int = 0
var heat_capacity: int = 0
var heat_dissipation: float = 0.0
var battle_heat: int = 0

# Type-specific properties
# Head properties
var perception: int = 0     # Affects targeting and dodge
var processing: int = 0     # Affects action speed
var intelligence: int = 0   # Affects decision making

# Core properties (some already covered in battle stats)

# Arm properties
var fire_rate: float = 1.0  # Attacks per second
var attack_range = [1.0]    # Attack ranges (array for multiple attack types)
var attack_type = ["melee"] # Attack types (melee, range, etc.)
var pierce: int = 0         # Number of targets to pierce
var effect_type: String = "" # Special effect type (bleed, stagger, etc)
var effect_value: int = 0   # Value for the effect

# Legs properties
var move_speed: float = 1.0  # Movement speed
var dodge: int = 0           # Chance to avoid attacks
var stability: int = 0       # Resistance to knockback

# Utility properties
var special_ability: String = ""  # Special ability name
var cooldown: int = 0            # Turns between uses
var passive_bonus: Dictionary = {}  # Passive stat bonuses

# Effect data
var effects: Array = []
var active_effects: Array = []

# Enums
enum PartType {
    HEAD,
    CORE,
    ARM,
    LEGS,
    UTILITY,
    SCRAPPER
}

enum EffectTiming {
    ON_ATTACH,
    ON_DETACH,
    ON_TURN_START,
    ON_TURN_END,
    ON_ATTACK,
    ON_DAMAGE_TAKEN,
    ON_DESTROY
}

enum EffectType {
    STAT_MODIFY,
    STAT_MULTIPLY,
    DAMAGE,
    HEAL,
    COOL,
    SPECIAL
}

func _ready():
    update_visuals()

# Initialize part from JSON data
func initialize_from_data(data: Dictionary) -> Part:
    id = data.get("id", "unknown")
    part_name = data.get("name", "Unknown Part")
    type = data.get("type", "").to_lower()
    cost = data.get("cost", 0)
    heat = data.get("heat", 0)
    durability = data.get("durability", 1)
    max_durability = durability
    frame = data.get("frame", 0)
    manufacturer = data.get("manufacturer", "")
    rarity = data.get("rarity", "Common")
    description = data.get("description", "")
    image_path = data.get("image", "")
    instance_id = data.get("instance_id", "")
    
    # Initialize battle stats based on part type
    match type.to_lower():
        "head":
            crit_chance = 0.05  # Base 5% crit chance
            perception = data.get("perception", 1)
            processing = data.get("processing", 1)
            intelligence = data.get("intelligence", 1)
        "core":
            energy_capacity = data.get("energy_capacity", 3)  # Base energy capacity
            heat_capacity = data.get("heat_capacity", 10)    # Base heat capacity
            heat_dissipation = data.get("heat_dissipation", 1.0)
            armor = data.get("armor", 0)
        "arm":
            damage = data.get("damage", 1)          # Base damage
            fire_rate = data.get("fire_rate", 1.0)
            
            # Handle attack types and ranges as arrays
            if data.has("attack_type"):
                if data["attack_type"] is Array:
                    attack_type = data["attack_type"]
                else:
                    attack_type = [data["attack_type"]]
            else:
                attack_type = ["melee"]  # Default to melee
                
            if data.has("attack_range"):
                if data["attack_range"] is Array:
                    attack_range = data["attack_range"]
                else:
                    attack_range = [data["attack_range"]]
            else:
                attack_range = [1.0]  # Default to melee range
                
            pierce = data.get("pierce", 0)
            effect_type = data.get("effect_type", "")
            effect_value = data.get("effect_value", 0)
        "legs":
            armor = data.get("armor", 1)           # Base armor
            move_speed = data.get("move_speed", 1.0)
            dodge = data.get("dodge", 0)
            stability = data.get("stability", 1)
        "utility":
            heat_dissipation = data.get("heat_dissipation", 1.0)  # Base heat dissipation rate
            special_ability = data.get("special_ability", "")
            cooldown = data.get("cooldown", 0)
            
            # Handle passive bonus dictionary if present
            if data.has("passive_bonus"):
                passive_bonus = data.passive_bonus.duplicate()
    
    # Process effects
    if data.has("effects"):
        for effect_data in data.effects:
            effects.append(effect_data)
    
    return self

# Duplicate another Part object's properties
func duplicate_from(other_part: Part) -> Part:
    # Copy all basic properties
    id = other_part.id
    part_name = other_part.part_name
    type = other_part.type
    cost = other_part.cost
    heat = other_part.heat
    energy_cost = other_part.energy_cost
    durability = other_part.durability
    max_durability = other_part.max_durability
    frame = other_part.frame
    manufacturer = other_part.manufacturer
    rarity = other_part.rarity
    description = other_part.description
    image_path = other_part.image_path
    instance_id = other_part.instance_id
    
    # Copy battle stats
    damage = other_part.damage
    attack_speed = other_part.attack_speed
    armor = other_part.armor
    crit_chance = other_part.crit_chance
    energy_capacity = other_part.energy_capacity
    heat_capacity = other_part.heat_capacity
    heat_dissipation = other_part.heat_dissipation
    
    # Copy effects (deep copy)
    effects.clear()
    for effect in other_part.effects:
        effects.append(effect.duplicate() if effect is Dictionary else effect)
    
    return self

# Get part type as enum
func get_part_type_enum() -> int:
    match type.to_lower():
        "head": return PartType.HEAD
        "core": return PartType.CORE
        "arm": return PartType.ARM
        "legs": return PartType.LEGS
        "utility": return PartType.UTILITY
        "scrapper": return PartType.SCRAPPER
        _: return -1

# Get string representation of part type
func get_part_type_string() -> String:
    return type.capitalize()

# Check if part is broken
func is_broken() -> bool:
    return durability <= 0

# Lifecycle methods
func attach_to_chassis(slot: String, card_id: String = "") -> void:
    attached_to_chassis = true
    chassis_slot = slot
    instance_id = card_id
    
    # Activate "on attach" effects
    activate_effects(EffectTiming.ON_ATTACH)

func detach_from_chassis() -> void:
    # Activate "on detach" effects
    activate_effects(EffectTiming.ON_DETACH)
    
    attached_to_chassis = false
    chassis_slot = ""
    # We don't clear instance_id as it needs to persist across detachments

# Reduce durability
func reduce_durability(amount: int = 1) -> void:
    if amount <= 0:
        return
        
    durability = max(0, durability - amount)
    emit_signal("durability_changed", durability, max_durability)
    
    if durability == 0:
        emit_signal("part_broken", self)
        activate_effects(EffectTiming.ON_DESTROY)
    else:
        activate_effects(EffectTiming.ON_DAMAGE_TAKEN)

# Take damage (similar to reduce_durability but returns actual damage dealt)
func take_damage(amount: int) -> int:
    var actual_damage = min(durability, amount)
    reduce_durability(actual_damage)
    return actual_damage

# Repair part
func repair(amount: int = 1) -> int:
    if amount <= 0:
        return 0
        
    var original_durability = durability
    durability = min(max_durability, durability + amount)
    
    var actual_repair = durability - original_durability
    if actual_repair > 0:
        emit_signal("durability_changed", durability, max_durability)
    
    return actual_repair

# Set enhanced state
func set_enhanced(enhanced: bool) -> void:
    is_enhanced = enhanced
    if enhanced:
        emit_signal("part_enhanced", self)

# Set exhausted state
func set_exhausted(exhausted: bool) -> void:
    is_exhausted = exhausted
    if exhausted:
        emit_signal("part_exhausted", self)

# Generate heat
func generate_heat() -> void:
    if heat > 0:
        emit_signal("heat_generated", heat)
        
# Effect system integration
func activate_effects(timing: int, target = null, context: Dictionary = {}) -> Array:
    var results = []
    
    for effect in effects:
        var effect_timing = _parse_effect_timing(effect.get("timing", ""))
        if effect_timing == timing:
            var result = _apply_effect(effect, target, context)
            if result:
                results.append(result)
                emit_signal("effect_activated", effect)
    
    return results

func _parse_effect_timing(timing_string: String) -> int:
    match timing_string.to_lower():
        "attach": return EffectTiming.ON_ATTACH
        "detach": return EffectTiming.ON_DETACH
        "turn_start": return EffectTiming.ON_TURN_START
        "turn_end": return EffectTiming.ON_TURN_END
        "attack": return EffectTiming.ON_ATTACK
        "damage_taken": return EffectTiming.ON_DAMAGE_TAKEN
        "destroy": return EffectTiming.ON_DESTROY
        _: return -1

func _parse_effect_type(type_string: String) -> int:
    match type_string.to_lower():
        "stat": return EffectType.STAT_MODIFY
        "multiply": return EffectType.STAT_MULTIPLY
        "damage": return EffectType.DAMAGE
        "heal": return EffectType.HEAL
        "cool": return EffectType.COOL
        "special": return EffectType.SPECIAL
        _: return -1

func _apply_effect(effect: Dictionary, target, context: Dictionary):
    # This is a simplified implementation. The full version would handle all effect types.
    var effect_type_str = effect.get("type", "")
    var effect_type_enum = _parse_effect_type(effect_type_str)
    
    match effect_type_enum:
        EffectType.STAT_MODIFY:
            var stat = effect.get("stat", "")
            var value = effect.get("value", 0)
            if target and target.has_method("modify_stat"):
                target.modify_stat(stat, value)
                return {"type": "stat", "stat": stat, "value": value, "target": target}
        EffectType.STAT_MULTIPLY:
            var stat = effect.get("stat", "")
            var value = effect.get("value", 1.0)
            if target and target.has_method("multiply_stat"):
                target.multiply_stat(stat, value)
                return {"type": "multiply", "stat": stat, "value": value, "target": target}
        EffectType.DAMAGE:
            var value = effect.get("value", 0)
            if target and target.has_method("take_damage"):
                var damage_dealt = target.take_damage(value)
                return {"type": "damage", "value": damage_dealt, "target": target}
        EffectType.HEAL:
            var value = effect.get("value", 0)
            if target and target.has_method("heal"):
                var heal_amount = target.heal(value)
                return {"type": "heal", "value": heal_amount, "target": target}
        EffectType.COOL:
            var value = effect.get("value", 0)
            if target and target.has_method("reduce_heat"):
                var cool_amount = target.reduce_heat(value)
                return {"type": "cool", "value": cool_amount, "target": target}
    
    return null

# Modify a stat value
func modify_stat(stat_name: String, value) -> void:
    match stat_name:
        "damage": damage += value
        "attack_speed": attack_speed += value / 100.0  # Convert percentage to decimal
        "armor": armor += value
        "crit_chance": crit_chance += value / 100.0  # Convert percentage to decimal
        "energy_capacity": energy_capacity += value
        "heat_capacity": heat_capacity += value
        "heat_dissipation": heat_dissipation += value
        "max_durability":
            max_durability += value
            durability += value  # Increasing max also increases current
        "perception": perception += value
        "processing": processing += value
        "intelligence": intelligence += value
        "move_speed": move_speed += value / 100.0  # Convert percentage to decimal
        "dodge": dodge += value
        "stability": stability += value
    
    emit_signal("stat_changed", stat_name, value)

# Multiply a stat value
func multiply_stat(stat_name: String, value: float) -> void:
    match stat_name:
        "damage": damage = int(damage * value)
        "attack_speed": attack_speed *= value
        "armor": armor = int(armor * value)
        "crit_chance": crit_chance *= value
        "energy_capacity": energy_capacity = int(energy_capacity * value)
        "heat_capacity": heat_capacity = int(heat_capacity * value)
        "heat_dissipation": heat_dissipation *= value
        "durability":
            # Special case - doesn't change max, just current
            durability = int(durability * value)
            durability = min(durability, max_durability)
            emit_signal("durability_changed", durability, max_durability)
        "perception": perception = int(perception * value)
        "processing": processing = int(processing * value)
        "intelligence": intelligence = int(intelligence * value)
        "move_speed": move_speed *= value
        "dodge": dodge = int(dodge * value)
        "stability": stability = int(stability * value)
    
    emit_signal("stat_changed", stat_name, value)

# Visual updates (empty implementation for base class)
func update_visuals() -> void:
    # To be implemented in visual child classes
    pass

static func from_dict(data: Dictionary) -> Part:
    var part = Part.new()
    part.initialize_from_data(data)
    return part

# Get a copy of this part's data as a dictionary
func to_dict() -> Dictionary:
    var dict = {
        "id": id,
        "name": part_name,
        "type": type,
        "cost": cost,
        "heat": heat,
        "durability": durability,
        "max_durability": max_durability,
        "frame": frame,
        "frame_index": frame,
        "manufacturer": manufacturer,
        "rarity": rarity,
        "description": description,
        "image": image_path,
        "instance_id": instance_id,
        "is_enhanced": is_enhanced,
        "is_exhausted": is_exhausted,
        "effects": effects.duplicate()
    }
    
    # Add battle stats
    dict["damage"] = damage
    dict["attack_speed"] = attack_speed
    dict["armor"] = armor
    dict["crit_chance"] = crit_chance
    dict["energy_capacity"] = energy_capacity
    dict["heat_capacity"] = heat_capacity
    dict["heat_dissipation"] = heat_dissipation
    
    # Add type-specific properties
    match type:
        "head":
            dict["perception"] = perception
            dict["processing"] = processing
            dict["intelligence"] = intelligence
        "arm":
            dict["fire_rate"] = fire_rate
            dict["attack_type"] = attack_type.duplicate() if attack_type is Array else ["melee"]
            dict["attack_range"] = attack_range.duplicate() if attack_range is Array else [1.0]
            dict["pierce"] = pierce
            dict["effect_type"] = effect_type
            dict["effect_value"] = effect_value
        "legs":
            dict["move_speed"] = move_speed
            dict["dodge"] = dodge
            dict["stability"] = stability
        "utility":
            dict["special_ability"] = special_ability
            dict["cooldown"] = cooldown
            dict["passive_bonus"] = passive_bonus.duplicate()
    
    return dict

# Initialize from another Part object
func initialize_from_part(other_part: Part) -> Part:
    # This is different from duplicate_from as it's meant to be used with a new Part
    # while duplicate_from is used on an existing Part instance
    
    # Copy all basic properties
    id = other_part.id
    part_name = other_part.part_name
    type = other_part.type
    cost = other_part.cost
    heat = other_part.heat
    energy_cost = other_part.energy_cost
    durability = other_part.durability
    max_durability = other_part.max_durability
    frame = other_part.frame
    manufacturer = other_part.manufacturer
    rarity = other_part.rarity
    description = other_part.description
    image_path = other_part.image_path
    
    # Generate new instance_id by default (can be overridden later)
    instance_id = "part_" + str(randi()) + "_" + str(Time.get_unix_time_from_system())
    
    # Copy battle stats
    damage = other_part.damage
    attack_speed = other_part.attack_speed
    armor = other_part.armor
    crit_chance = other_part.crit_chance
    energy_capacity = other_part.energy_capacity
    heat_capacity = other_part.heat_capacity
    heat_dissipation = other_part.heat_dissipation
    battle_heat = other_part.battle_heat
    
    # Copy type-specific properties
    perception = other_part.perception
    processing = other_part.processing
    intelligence = other_part.intelligence
    fire_rate = other_part.fire_rate
    
    # Handle attack_type and attack_range as arrays with proper duplication
    attack_type = other_part.attack_type.duplicate() if other_part.attack_type is Array else ["melee"]
    attack_range = other_part.attack_range.duplicate() if other_part.attack_range is Array else [1.0]
    
    pierce = other_part.pierce
    effect_type = other_part.effect_type
    effect_value = other_part.effect_value
    move_speed = other_part.move_speed
    dodge = other_part.dodge
    stability = other_part.stability
    special_ability = other_part.special_ability
    cooldown = other_part.cooldown
    
    # Copy passive bonus dictionary
    passive_bonus = other_part.passive_bonus.duplicate()
    
    # Copy effects (deep copy)
    effects.clear()
    for effect in other_part.effects:
        effects.append(effect.duplicate() if effect is Dictionary else effect)
        
    # Copy active effects (deep copy)
    active_effects.clear()
    for effect in other_part.active_effects:
        active_effects.append(effect.duplicate() if effect is Dictionary else effect)
    
    return self

# Create a clone of this part
func clone() -> Part:
    var new_part = Part.new()
    new_part.initialize_from_part(self)
    return new_part

# Convert to a scrap part
func convert_to_scrap() -> Part:
    var scrap_part = Part.new()
    
    # Base properties
    scrap_part.id = "scrap_" + id
    scrap_part.part_name = "Scrap " + part_name
    scrap_part.type = "scrapper"
    scrap_part.cost = 0
    scrap_part.heat = heat  # Scrap retains original heat value for recycling
    scrap_part.durability = 1
    scrap_part.max_durability = 1
    scrap_part.rarity = "Common"
    scrap_part.description = "Salvaged parts from a broken " + part_name
    
    # Special scrap frame index
    scrap_part.frame = 50  # Assuming 50 is the base scrapper frame index
    
    return scrap_part

# String representation for debugging
func _to_string() -> String:
    return "[Part: %s (%s) - Type: %s, Durability: %d/%d]" % [part_name, id, type, durability, max_durability]
