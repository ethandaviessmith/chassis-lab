extends Node
class_name CardEffectSystem

# Effect Types
enum EffectType {
    STAT_MODIFY,
    STAT_MULTIPLY,
    DAMAGE,
    HEAL,
    COOL,
    SPECIAL
}

# Effect Timing
enum EffectTiming {
    ON_ATTACH,
    ON_DETACH,
    ON_TURN_START,
    ON_TURN_END,
    ON_ATTACK,
    ON_DAMAGE_TAKEN,
    ON_DESTROY
}

# Register effects from card data
func register_card_effects(card_data):
    var effects = []
    if card_data.has("effects"):
        for effect_data in card_data.effects:
            var effect = {
                "type": _parse_effect_type(effect_data.get("type", "")),
                "timing": _parse_effect_timing(effect_data.get("timing", "")),
                "stat": effect_data.get("stat", ""),
                "value": effect_data.get("value", 0),
                "duration": effect_data.get("duration", 0),
                "target": effect_data.get("target", "self"),
                "condition": effect_data.get("condition", ""),
                "parameters": effect_data.get("parameters", {})
            }
            effects.append(effect)
    return effects

# Apply effects based on timing
func apply_effects(card_data, timing: int, target = null, context = {}):
    var results = []
    var effects = register_card_effects(card_data)
    for effect in effects:
        if effect.timing != timing:
            continue
        var result = _apply_single_effect(effect, target, context)
        results.append(result)
    return results

# Helper functions for effect application
func _parse_effect_type(type_string: String) -> int:
    match type_string.to_lower():
        "stat": return EffectType.STAT_MODIFY
        "multiply": return EffectType.STAT_MULTIPLY
        "damage": return EffectType.DAMAGE
        "heal": return EffectType.HEAL
        "cool": return EffectType.COOL
        "special": return EffectType.SPECIAL
        _: return -1

func _parse_effect_timing(timing_string: String) -> int:
    match timing_string.to_lower():
        "attach": return EffectTiming.ON_ATTACH
        "detach": return EffectTiming.ON_DETACH
        "turn_start": return EffectTiming.ON_TURN_START
        "turn_end": return EffectTiming.ON_TURN_END
        "attack": return EffectTiming.ON_ATTACK
        "damage": return EffectTiming.ON_DAMAGE_TAKEN
        "destroy": return EffectTiming.ON_DESTROY
        _: return -1

func _apply_single_effect(effect, target, context):
    var result = {
        "applied": false,
        "type": effect.type,
        "value": 0,
        "description": ""
    }
    
    # Skip if target is invalid for this effect
    if effect.target != "self" and target == null:
        return result
        
    match effect.type:
        EffectType.STAT_MODIFY:
            if target and target.has_method("modify_stat"):
                target.modify_stat(effect.stat, effect.value)
                result.applied = true
                result.value = effect.value
                result.description = "Modified " + effect.stat + " by " + str(effect.value)
            elif context.has("stat_modifiers"):
                # Add to context stat modifiers
                if not context.stat_modifiers.has(effect.stat):
                    context.stat_modifiers[effect.stat] = 0
                context.stat_modifiers[effect.stat] += effect.value
                result.applied = true
                result.value = effect.value
                
        EffectType.STAT_MULTIPLY:
            if target and target.has_method("multiply_stat"):
                target.multiply_stat(effect.stat, effect.value)
                result.applied = true
                result.value = effect.value
                result.description = "Multiplied " + effect.stat + " by " + str(effect.value)
            elif context.has("stat_multipliers"):
                if not context.stat_multipliers.has(effect.stat):
                    context.stat_multipliers[effect.stat] = 1.0
                context.stat_multipliers[effect.stat] *= effect.value
                result.applied = true
                result.value = effect.value
                
        EffectType.DAMAGE:
            if target and target.has_method("take_damage"):
                var damage_amount = effect.value
                if context.has("damage_modifiers") and context.damage_modifiers > 0:
                    damage_amount *= context.damage_modifiers
                target.take_damage(damage_amount)
                result.applied = true
                result.value = damage_amount
                result.description = "Dealt " + str(damage_amount) + " damage"
                
        EffectType.HEAL:
            if target and target.has_method("heal"):
                target.heal(effect.value)
                result.applied = true
                result.value = effect.value
                result.description = "Healed for " + str(effect.value)
                
        EffectType.COOL:
            if target and target.has_method("reduce_heat"):
                target.reduce_heat(effect.value)
                result.applied = true
                result.value = effect.value
                result.description = "Cooled by " + str(effect.value)
            elif context.has("heat_change"):
                context.heat_change -= effect.value
                result.applied = true
                result.value = effect.value
                
        EffectType.SPECIAL:
            # Handle special effects based on parameters
            if effect.parameters.has("special_type"):
                match effect.parameters.special_type:
                    "energy_add":
                        if target and target.has_method("add_energy"):
                            target.add_energy(effect.value)
                            result.applied = true
                            result.description = "Added " + str(effect.value) + " energy"
                    "max_energy":
                        if target and target.has_method("set_max_energy"):
                            target.set_max_energy(target.max_energy + effect.value)
                            result.applied = true
                            result.description = "Increased max energy by " + str(effect.value)
                    "max_heat":
                        if target and target.has_method("set_max_heat"):
                            target.set_max_heat(target.max_heat + effect.value)
                            result.applied = true
                            result.description = "Increased max heat by " + str(effect.value)
            
    return result
