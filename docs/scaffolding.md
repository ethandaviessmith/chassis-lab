# Stage 5: Godot 4.4 Scaffolding and Stubs

This document contains paste-ready GDScript stubs for Chassis Lab, a deck-building auto-battler prototype.

## Core Manager Scripts

### GameManager.gd
```gdscript
extends Node
class_name GameManager

enum GameState {BUILD, COMBAT, REWARD, GAME_OVER}

signal game_started
signal build_phase_started
signal build_phase_ended
signal combat_phase_started
signal combat_phase_ended
signal reward_phase_started
signal game_over(victory)

var current_state: GameState = GameState.BUILD
var current_encounter: int = 0
var max_encounters: int = 3
var victory: bool = false

@onready var deck_manager = $"../DeckManager"
@onready var turn_manager = $"../TurnManager"
@onready var combat_resolver = $"../CombatResolver"
@onready var build_view = $"../../BuildView"
@onready var combat_view = $"../../CombatView"
@onready var reward_screen = $"../../RewardScreen"

func _ready():
	# Connect signals
	build_view.combat_requested.connect(_on_combat_requested)
	combat_resolver.combat_ended.connect(_on_combat_ended)
	
	# Start new game
	start_new_game()

func start_new_game():
	current_encounter = 0
	victory = false
	emit_signal("game_started")
	start_build_phase()

func start_build_phase():
	current_state = GameState.BUILD
	
	# Show build view, hide others
	build_view.visible = true
	combat_view.visible = false
	reward_screen.visible = false
	
	# Reset turn state
	turn_manager.start_turn()
	
	emit_signal("build_phase_started")

func start_combat_phase():
	current_state = GameState.COMBAT
	
	# Hide build view, show combat view
	build_view.visible = false
	combat_view.visible = true
	
	# Start combat
	combat_resolver.start_combat(current_encounter)
	
	emit_signal("combat_phase_started")

func start_reward_phase():
	current_state = GameState.REWARD
	
	# Hide combat view, show reward screen
	combat_view.visible = false
	reward_screen.visible = true
	
	# Generate rewards
	var rewards = deck_manager.generate_rewards(3)
	reward_screen.display_rewards(rewards)
	
	emit_signal("reward_phase_started")

func advance_to_next_encounter():
	current_encounter += 1
	
	if current_encounter >= max_encounters:
		# Final boss encounter
		start_build_phase()
	elif current_encounter > max_encounters:
		# Victory!
		end_game(true)
	else:
		# Next regular encounter
		start_build_phase()

func end_game(is_victory: bool):
	current_state = GameState.GAME_OVER
	victory = is_victory
	emit_signal("game_over", victory)
	
	# Show game over screen
	# Implement later

func _on_combat_requested():
	# Called when player hits "Start Combat" button
	emit_signal("build_phase_ended")
	start_combat_phase()

func _on_combat_ended(player_won: bool):
	emit_signal("combat_phase_ended")
	
	if player_won:
		start_reward_phase()
	else:
		end_game(false)

func _on_reward_selected(_card_id: String):
	advance_to_next_encounter()
```

### DeckManager.gd
```gdscript
extends Node
class_name DeckManager

signal card_drawn(card)
signal card_played(card, slot)
signal card_scrapped(card)

var deck = []
var hand = []
var discard_pile = []
var exhausted_pile = []

var max_hand_size = 5
var default_draw_count = 5

@onready var data_loader = $"../../Utils/DataLoader"

func _ready():
	# Load initial deck
	load_starting_deck()

func load_starting_deck():
	# Clear existing cards
	deck.clear()
	hand.clear()
	discard_pile.clear()
	exhausted_pile.clear()
	
	# Load starting cards from data
	var starting_cards = data_loader.load_starting_deck()
	for card_data in starting_cards:
		deck.append(card_data)
	
	# Shuffle the deck
	shuffle_deck()

func shuffle_deck():
	# Randomize the deck
	deck.shuffle()
	print("Deck shuffled, contains ", deck.size(), " cards")

func draw_card() -> Dictionary:
	if deck.size() == 0:
		if discard_pile.size() > 0:
			# Shuffle discard pile into deck
			for card in discard_pile:
				deck.append(card)
			discard_pile.clear()
			shuffle_deck()
		else:
			# No cards to draw!
			print("No cards left to draw!")
			return {}
	
	# Draw top card
	var card = deck.pop_front()
	hand.append(card)
	
	emit_signal("card_drawn", card)
	return card

func draw_hand():
	# Draw up to max hand size
	while hand.size() < max_hand_size and (deck.size() > 0 or discard_pile.size() > 0):
		draw_card()

func play_card(card: Dictionary, slot: String) -> bool:
	# Check if card is in hand
	if not hand.has(card):
		print("Card not in hand!")
		return false
	
	# Check if player has enough energy
	if turn_manager.current_energy < card.cost:
		print("Not enough energy!")
		return false
	
	# Remove from hand
	hand.erase(card)
	
	# Spend energy
	turn_manager.spend_energy(card.cost)
	
	# Emit signal so the BuildView can update
	emit_signal("card_played", card, slot)
	
	# Add to discard pile
	discard_pile.append(card)
	return true

func scrap_card(card: Dictionary) -> bool:
	# Check if card is in hand
	if not hand.has(card):
		print("Card not in hand!")
		return false
	
	# Remove from hand
	hand.erase(card)
	
	# Emit signal for scrapper
	emit_signal("card_scrapped", card)
	
	# Add to discard pile
	discard_pile.append(card)
	return true

func exhaust_card(card: Dictionary):
	# Remove from wherever it is
	if hand.has(card):
		hand.erase(card)
	elif discard_pile.has(card):
		discard_pile.erase(card)
	elif deck.has(card):
		deck.erase(card)
		
	# Add to exhausted pile
	exhausted_pile.append(card)

func generate_rewards(count: int) -> Array:
	# Generate count reward options
	var rewards = []
	var all_rewards = data_loader.load_reward_options()
	
	# Choose random rewards
	all_rewards.shuffle()
	for i in range(min(count, all_rewards.size())):
		rewards.append(all_rewards[i])
	
	return rewards

func add_card_to_deck(card: Dictionary):
	# Add a new card to discard pile
	discard_pile.append(card)

# Reference to other managers
@onready var turn_manager = $"../TurnManager"
```

### TurnManager.gd
```gdscript
extends Node
class_name TurnManager

signal energy_changed(new_value)
signal turn_started
signal turn_ended

var current_energy: int = 0
var max_energy: int = 3  # Default starting energy per turn

func _ready():
	pass

func start_turn():
	# Reset energy to max at start of turn
	current_energy = max_energy
	emit_signal("energy_changed", current_energy)
	emit_signal("turn_started")
	
	# Draw new hand
	$"../DeckManager".draw_hand()

func end_turn():
	emit_signal("turn_ended")
	start_turn()

func spend_energy(amount: int) -> bool:
	if amount > current_energy:
		return false
	
	current_energy -= amount
	emit_signal("energy_changed", current_energy)
	return true

func gain_energy(amount: int):
	current_energy += amount
	emit_signal("energy_changed", current_energy)

func set_max_energy(new_max: int):
	max_energy = new_max
```

### CombatResolver.gd
```gdscript
extends Node
class_name CombatResolver

signal combat_tick
signal damage_dealt(source, target, amount)
signal robot_heat_changed(new_heat)
signal overheat_started
signal overheat_ended
signal part_durability_changed(part, new_durability)
signal part_broken(part)
signal entity_defeated(entity)
signal combat_ended(player_won)

var combat_active = false
var round_count = 0
var tick_count = 0
var combat_speed = 1.0  # Multiplier for combat speed

# Combat entities
var player_robot = null
var current_enemy = null

# References
@onready var data_loader = $"../../Utils/DataLoader"
@onready var combat_view = $"../../CombatView"

func _ready():
	pass

func _process(_delta):
	if combat_active:
		# Combat tick processing
		tick_count += 1
		
		if tick_count % 60 == 0:  # Once per second
			advance_combat_round()
		
		emit_signal("combat_tick")
		
		# Process entities
		if player_robot and player_robot.energy <= 0:
			_end_combat(false)  # Player lost
		elif current_enemy and current_enemy.hp <= 0:
			_end_combat(true)   # Player won

func start_combat(encounter_id: int):
	# Reset combat state
	combat_active = true
	round_count = 0
	tick_count = 0
	
	# Set up player robot
	player_robot = combat_view.get_player_robot()
	
	# Create enemy for this encounter
	current_enemy = _create_enemy_for_encounter(encounter_id)
	combat_view.spawn_enemy(current_enemy)
	
	print("Combat started: Player vs ", current_enemy.name)

func advance_combat_round():
	round_count += 1
	print("Combat round: ", round_count)
	
	# Process robot parts - reduce durability etc.
	for part in player_robot.get_parts():
		reduce_part_durability(part)

func reduce_part_durability(part):
	if part.durability > 0:
		part.durability -= 1
		emit_signal("part_durability_changed", part, part.durability)
		
		if part.durability <= 0:
			emit_signal("part_broken", part)
			player_robot.remove_part(part)

func apply_damage(source, target, amount):
	var actual_damage = amount
	
	# Apply armor reduction if target has armor
	if target.has_method("get_armor"):
		var armor = target.get_armor()
		var damage_reduction = min(0.7, armor * 0.05)  # 5% per armor point, max 70% reduction
		actual_damage = max(1, int(actual_damage * (1 - damage_reduction)))
	
	# Apply damage
	target.take_damage(actual_damage)
	
	emit_signal("damage_dealt", source, target, actual_damage)
	
	# Check for defeat
	if target.is_defeated():
		emit_signal("entity_defeated", target)

func update_robot_heat(new_heat):
	emit_signal("robot_heat_changed", new_heat)
	
	# Check for overheat thresholds
	if new_heat >= 10 and player_robot.heat < 10:
		emit_signal("overheat_started")
	elif new_heat < 8 and player_robot.heat >= 8:
		emit_signal("overheat_ended")

func _create_enemy_for_encounter(encounter_id: int):
	var enemy_data
	
	if encounter_id >= 3:  # Boss encounter
		enemy_data = data_loader.load_boss_data()
	else:
		var enemies = data_loader.load_enemy_data()
		enemy_data = enemies[encounter_id % enemies.size()]
	
	var enemy = Enemy.new()
	enemy.initialize_from_data(enemy_data)
	
	return enemy

func _end_combat(player_won: bool):
	combat_active = false
	
	if player_won:
		print("Player won combat!")
	else:
		print("Player was defeated!")
	
	emit_signal("combat_ended", player_won)
```

## Entity Classes

### Robot.gd
```gdscript
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
var left_leg = null
var right_leg = null

# Part effects cache
var effects = {}

# References
@onready var head_sprite = $Sprite/HeadSprite
@onready var core_sprite = $Sprite/CoreSprite
@onready var left_arm_sprite = $Sprite/LeftArmSprite
@onready var right_arm_sprite = $Sprite/RightArmSprite
@onready var left_leg_sprite = $Sprite/LeftLegSprite
@onready var right_leg_sprite = $Sprite/RightLegSprite
@onready var health_bar = $HealthBar
@onready var heat_bar = $HeatBar

func _ready():
	update_visuals()
	update_bars()

func _physics_process(_delta):
	if get_node("/root/Main/Managers/CombatResolver").combat_active:
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
		"left_leg":
			left_leg = part
			left_leg_sprite.texture = part.sprite
		"right_leg":
			right_leg = part
			right_leg_sprite.texture = part.sprite
	
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
	elif left_leg == part:
		left_leg = null
		left_leg_sprite.texture = null
	elif right_leg == part:
		right_leg = null
		right_leg_sprite.texture = null
	
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
	if left_leg:
		parts.append(left_leg)
	if right_leg:
		parts.append(right_leg)
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
	var _old_heat = heat
	heat = min(heat + amount, max_heat)
	update_bars()
	
	# Report heat change for potential overheat
	var combat_resolver = get_node("/root/Main/Managers/CombatResolver")
	if combat_resolver:
		combat_resolver.update_robot_heat(heat)

func reduce_heat(amount: int):
	var _old_heat = heat
	heat = max(0, heat - amount)
	update_bars()
	
	# Report heat change
	var combat_resolver = get_node("/root/Main/Managers/CombatResolver")
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
```

### Enemy.gd
```gdscript
extends CharacterBody2D
class_name Enemy

var id: String
var enemy_name: String
var hp: int
var max_hp: int
var armor: int
var damage: int
var attack_speed: float
var move_speed: float
var behavior: String
var special_abilities = []

# Combat state
var attack_timer: float = 0.0
var target = null

# References
@onready var sprite = $Sprite
@onready var health_bar = $HealthBar
@onready var animation_player = $AnimationPlayer

func _ready():
	update_health_bar()

func initialize_from_data(data: Dictionary):
	id = data.id
	enemy_name = data.name
	hp = data.hp
	max_hp = data.hp
	armor = data.get("armor", 0)
	damage = data.damage
	attack_speed = data.attack_speed
	move_speed = data.move_speed
	behavior = data.behavior
	
	# Load special abilities if present
	if "special_abilities" in data:
		special_abilities = data.special_abilities
	
	# Load sprite if specified
	if "sprite" in data and data.sprite != "":
		var texture = load(data.sprite)
		if texture:
			sprite.texture = texture
	
	# Add to enemies group
	add_to_group("enemies")

func _physics_process(delta):
	# Only process during combat
	var combat_resolver = get_node("/root/Main/Managers/CombatResolver")
	if not combat_resolver.combat_active:
		return
		
	# Find target if we don't have one
	if not target or not is_instance_valid(target):
		target = find_target()
		
	if target:
		process_behavior(delta)

func find_target():
	# Default targeting - player robot
	var player = get_tree().get_nodes_in_group("player")
	if player.size() > 0:
		return player[0]
	return null

func process_behavior(delta):
	match behavior:
		"aggressive":
			move_to_target(target)
			try_attack(delta)
		"defensive":
			# Stay at mid-range and attack
			keep_distance(target, 150.0)
			try_attack(delta)
		"flanking":
			# Try to circle around target
			circle_target(target)
			try_attack(delta)
		_:  # Default
			move_to_target(target)
			try_attack(delta)

func move_to_target(target_node):
	var direction = (target_node.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

func keep_distance(target_node, ideal_distance):
	var direction = (global_position - target_node.global_position)
	var distance = direction.length()
	
	if distance < ideal_distance * 0.8:
		# Too close, back up
		velocity = direction.normalized() * move_speed
	elif distance > ideal_distance * 1.2:
		# Too far, move closer
		velocity = -direction.normalized() * move_speed
	else:
		# Good distance, strafe
		velocity = direction.normalized().rotated(PI/2) * move_speed * 0.5
	
	move_and_slide()

func circle_target(target_node):
	var to_target = target_node.global_position - global_position
	var circle_direction = to_target.rotated(PI/2).normalized()
	
	# Mix of circling and approaching
	var distance = to_target.length()
	var approach_weight = clamp(distance / 200.0 - 0.5, 0.0, 1.0)
	var final_direction = circle_direction.lerp(-to_target.normalized(), approach_weight)
	
	velocity = final_direction * move_speed
	move_and_slide()

func try_attack(delta):
	attack_timer += delta
	
	# Can attack based on attack speed (attacks per second)
	if attack_timer >= 1.0 / attack_speed:
		attack_timer = 0.0
		attack_target(target)

func attack_target(target_node):
	# Simple direct attack
	if target_node and is_instance_valid(target_node) and global_position.distance_to(target_node.global_position) < 100:
		var combat_resolver = get_node("/root/Main/Managers/CombatResolver")
		combat_resolver.apply_damage(self, target_node, damage)
		play_attack_animation()

func take_damage(amount: int):
	hp -= amount
	update_health_bar()
	play_hurt_animation()
	
	# Check for special ability triggers
	for ability in special_abilities:
		if ability.trigger == "on_damage":
			activate_special_ability(ability)

func activate_special_ability(ability: Dictionary):
	match ability.effect:
		"self_heal":
			hp += int(max_hp * 0.1)  # Heal 10% of max HP
			hp = min(hp, max_hp)
			update_health_bar()
		"speed_boost":
			move_speed *= 1.5
			await get_tree().create_timer(3.0).timeout
			move_speed /= 1.5
		# Add more special abilities as needed

func update_health_bar():
	if health_bar:
		health_bar.value = 100.0 * hp / max_hp

func play_attack_animation():
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	else:
		# Simple feedback without animation
		sprite.scale = Vector2(1.2, 1.2)
		await get_tree().create_timer(0.1).timeout
		sprite.scale = Vector2(1.0, 1.0)

func play_hurt_animation():
	if animation_player and animation_player.has_animation("hurt"):
		animation_player.play("hurt")
	else:
		# Simple feedback without animation
		sprite.modulate = Color(1, 0.5, 0.5)  # Red tint
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)

func get_armor() -> int:
	return armor

func is_defeated() -> bool:
	return hp <= 0
```

## Parts System

### Part.gd (Base Class)
```gdscript
extends Node2D
class_name Part

var id: String
var part_name: String
var type: String  # "head", "core", "arm", "leg", "utility"
var cost: int
var heat_generation: int
var durability: int
var max_durability: int
var effects: Array
var rarity: String
var description: String

var sprite: Texture2D
var is_enhanced: bool = false
var is_exhausted: bool = false

signal durability_changed(new_value)
signal part_broken

func _ready():
	update_visuals()

func initialize_from_data(data: Dictionary):
	id = data.id
	part_name = data.name
	type = data.type
	cost = data.cost
	heat_generation = data.heat
	durability = data.durability
	max_durability = data.durability
	rarity = data.rarity
	description = data.description
	
	# Load effects
	effects = []
	for effect_data in data.effects:
		effects.append(effect_data)
	
	# Load sprite if specified
	if "image" in data and data.image != "":
		sprite = load(data.image)

func update_visuals():
	# Update sprite based on part state
	if is_enhanced:
		# Add glow or effect to indicate enhancement
		modulate = Color(1.2, 1.2, 0.8)  # Slightly yellow glow
	
	if is_exhausted:
		# Gray out to indicate exhausted
		modulate = Color(0.5, 0.5, 0.5)

func enhance(heat_used: int):
	# Apply heat-based enhancement
	is_enhanced = true
	is_exhausted = true
	
	# Enhance effects based on heat used
	for effect in effects:
		if "value" in effect and typeof(effect.value) == TYPE_INT:
			effect.value += heat_used
	
	update_visuals()

func reduce_durability(amount: int = 1):
	durability -= amount
	emit_signal("durability_changed", durability)
	
	if durability <= 0:
		emit_signal("part_broken")
	
	update_visuals()

func restore_durability(amount: int):
	durability = min(durability + amount, max_durability)
	emit_signal("durability_changed", durability)
	update_visuals()

func is_broken() -> bool:
	return durability <= 0
	
# Called when the part is used in combat
# Override in derived classes
func activate():
	pass
```

### Derived Part Classes (Head, Core, Arm, Leg)

**Head.gd**
```gdscript
extends Part
class_name Head

# Special head functionality
var target_bonus = null  # For targeting overrides
var crit_chance = 0.0    # Base crit chance bonus
var sensor_range = 0.0   # Detection range bonus

func _init():
	type = "head"

func activate():
	# Generate heat when used
	if is_instance_valid(get_parent()) and get_parent().has_method("add_heat"):
		get_parent().add_heat(heat_generation)

# Returns the best target based on head functionality
func get_optimal_target(possible_targets: Array):
	if target_bonus == "lowest_hp":
		# Target lowest HP enemy
		var lowest_hp_target = null
		var lowest_hp = INF
		
		for target in possible_targets:
			if target.hp < lowest_hp:
				lowest_hp = target.hp
				lowest_hp_target = target
				
		return lowest_hp_target
	
	# Default targeting
	return null if possible_targets.size() == 0 else possible_targets[0]

# Calculate if an attack crits
func calculate_crit() -> bool:
	return randf() < crit_chance
```

**Core.gd**
```gdscript
extends Part
class_name Core

# Special core functionality
var energy_regen = 0  # Energy regenerated per round
var heat_dissipation = 0  # Heat reduced per round
var bonus_armor = 0  # Additional armor

func _init():
	type = "core"

func activate():
	var parent = get_parent()
	if not is_instance_valid(parent):
		return
	
	# Core passive effects
	if energy_regen > 0 and parent.has_method("heal"):
		parent.heal(energy_regen)
		
	if heat_dissipation > 0 and parent.has_method("reduce_heat"):
		parent.reduce_heat(heat_dissipation)

# Process heat dissipation at end of combat round
func process_end_of_round():
	# Apply additional effects at end of round
	var parent = get_parent()
	if is_instance_valid(parent) and heat_dissipation > 0 and parent.has_method("reduce_heat"):
		parent.reduce_heat(heat_dissipation)
```

**Arm.gd**
```gdscript
extends Part
class_name Arm

# Special arm functionality
var damage = 0        # Base damage
var fire_rate = 1.0   # Attacks per second
var range = 200.0     # Attack range
var pierce = 0        # Number of targets to pierce
var effect_type = ""  # Special effect type (bleed, stagger, etc)
var effect_value = 0  # Value for the effect

var attack_timer = 0.0

func _init():
	type = "arm"

func _process(delta):
	if is_instance_valid(get_parent()) and get_parent().has_method("is_defeated") and not get_parent().is_defeated():
		attack_timer += delta
		
		# Auto-attack when timer expires
		if attack_timer >= 1.0 / fire_rate:
			attack_timer = 0.0
			attack()

func attack():
	if is_exhausted or is_broken():
		return
		
	# Find valid target
	var target = find_target()
	if not target:
		return
		
	# Apply damage
	deal_damage(target)
	
	# Generate heat
	if is_instance_valid(get_parent()) and get_parent().has_method("add_heat"):
		get_parent().add_heat(heat_generation)

func find_target():
	var parent = get_parent()
	if not is_instance_valid(parent) or not parent.has_method("find_target"):
		return null
	
	# Get target from parent robot
	return parent.find_target()

func deal_damage(target):
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	
	# Apply damage modifiers
	var final_damage = damage
	
	# Check for crit if robot has head
	var parent = get_parent()
	if is_instance_valid(parent) and parent.head and parent.head.has_method("calculate_crit"):
		if parent.head.calculate_crit():
			final_damage = int(final_damage * 1.5)  # 50% crit bonus
	
	# Deal damage
	var combat_resolver = get_node("/root/Main/Managers/CombatResolver")
	if is_instance_valid(combat_resolver):
		combat_resolver.apply_damage(get_parent(), target, final_damage)
	else:
		# Fallback if resolver not available
		target.take_damage(final_damage)
	
	# Apply special effects
	apply_special_effect(target)
	
	# Handle pierce
	if pierce > 0:
		# Find additional targets
		# This is simplified - would need more complex targeting in a full implementation
		pass

func apply_special_effect(target):
	if not effect_type or effect_type == "" or effect_value <= 0:
		return
		
	match effect_type:
		"bleed":
			# Apply bleed damage over time
			# Would need a proper DoT system
			pass
		"stagger":
			# Reduce target movement speed temporarily
			if target.has_method("apply_status_effect"):
				target.apply_status_effect("stagger", effect_value, 2.0)  # 2 sec duration
		"armor_shred":
			# Reduce target armor temporarily
			if target.has_method("modify_armor"):
				target.modify_armor(-effect_value, 3.0)  # 3 sec duration
```

**Leg.gd**
```gdscript
extends Part
class_name Leg

# Special leg functionality
var speed_bonus_percent = 0.0  # Movement speed bonus percentage
var dodge_chance = 0.0         # Chance to dodge attacks
var stability = 0.0            # Reduces knockback effects
var dodge_cooldown = 0.0       # Cooldown for dodge abilities
var knockback_resistance = 0.0 # Resistance to knockback as percentage

var dodge_timer = 0.0

func _init():
	type = "leg"

func _process(delta):
	# Process dodge cooldowns
	if dodge_timer > 0:
		dodge_timer -= delta

func activate():
	# Generate heat when used
	if is_instance_valid(get_parent()) and get_parent().has_method("add_heat"):
		get_parent().add_heat(heat_generation)

# Apply movement modifiers to parent robot
func apply_movement_modifiers():
	var parent = get_parent()
	if not is_instance_valid(parent):
		return
	
	# Apply speed bonus
	if speed_bonus_percent != 0 and "move_speed" in parent:
		var base_speed = parent.move_speed / (1 + speed_bonus_percent / 100.0)  # Reverse any previous application
		parent.move_speed = base_speed * (1 + speed_bonus_percent / 100.0)

# Check if an attack is dodged
func try_dodge() -> bool:
	if dodge_chance <= 0 or dodge_timer > 0:
		return false
		
	var roll = randf()
	if roll < dodge_chance:
		# Successful dodge
		dodge_timer = dodge_cooldown  # Start cooldown
		return true
		
	return false

# Handle knockback resistance
func calculate_knockback_resistance() -> float:
	return knockback_resistance / 100.0
```

## UI Components

### Card.gd
```gdscript
extends Control
class_name Card

signal card_dragged(card)
signal card_dropped(card, target)

# Card data
var data: Dictionary = {}
var draggable = true
var dragging = false
var drag_offset = Vector2.ZERO
var original_position = Vector2.ZERO

# References to UI elements
@onready var name_label = $NameLabel
@onready var type_label = $TypeLabel
@onready var cost_label = $StatsContainer/CostLabel
@onready var heat_label = $StatsContainer/HeatLabel
@onready var durability_label = $StatsContainer/DurabilityLabel
@onready var effects_label = $EffectsLabel
@onready var image = $Image
@onready var background = $Background
@onready var highlight = $Highlight

func _ready():
	highlight.visible = false

func initialize(card_data: Dictionary):
	data = card_data
	
	# Set up UI elements
	name_label.text = data.name
	type_label.text = data.type
	cost_label.text = str(data.cost)
	heat_label.text = str(data.heat)
	durability_label.text = str(data.durability)
	
	# Format effects
	var effects_text = ""
	for effect in data.effects:
		if effects_text != "":
			effects_text += "\n"
		effects_text += effect.description
	
	effects_label.text = effects_text
	
	# Set image if available
	if "image" in data and data.image != "":
		var texture = load(data.image)
		if texture:
			image.texture = texture
			
	# Set background based on rarity
	var bg_color = Color(0.3, 0.3, 0.3)
	match data.rarity.to_lower():
		"common":
			bg_color = Color(0.4, 0.4, 0.4)
		"uncommon":
			bg_color = Color(0.2, 0.5, 0.2)
		"rare":
			bg_color = Color(0.2, 0.2, 0.7)
		"epic":
			bg_color = Color(0.6, 0.2, 0.6)
	
	background.modulate = bg_color

func _input(event):
	if not draggable or not dragging:
		return
		
	if event is InputEventMouseMotion:
		# Move card with mouse
		global_position = event.global_position - drag_offset
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		# End drag
		dragging = false
		var target = _get_drop_target()
		
		if target:
			emit_signal("card_dropped", self, target)
		else:
			# Return to original position
			global_position = original_position

func _get_drop_target():
	# Raycast to find potential drop targets
	# This is a placeholder - actual implementation depends on physics setup
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collision_mask = 2  # Assuming drop targets are on layer 2
	
	var result = space_state.intersect_point(query, 1)
	if result.size() > 0:
		return result[0].collider
	return null

func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and draggable:
			# Start drag
			dragging = true
			original_position = global_position
			drag_offset = get_local_mouse_position()
			emit_signal("card_dragged", self)
			# Move card to top of draw order
			get_parent().move_child(self, get_parent().get_child_count() - 1)

func set_highlight(enabled: bool):
	highlight.visible = enabled

func get_card_type() -> String:
	return data.type
```

### DragDrop.gd
```gdscript
extends Node
class_name DragDrop

signal drag_started(draggable)
signal drag_ended(draggable)
signal drop_attempted(draggable, target)
signal drop_succeeded(draggable, target)
signal drop_failed(draggable)

var current_draggable = null
var drag_offset = Vector2.ZERO
var original_position = Vector2.ZERO
var valid_drop_targets = []

func register_draggable(node: Node):
	# Set up input for draggable object
	if not node.is_connected("gui_input", _on_draggable_input.bind(node)):
		node.gui_input.connect(_on_draggable_input.bind(node))

func register_drop_target(node: Node, valid_types: Array = []):
	# Store valid drop target with acceptable types
	valid_drop_targets.append({
		"node": node,
		"valid_types": valid_types
	})

func _on_draggable_input(event, draggable):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Start drag
			start_drag(draggable)
		elif current_draggable == draggable:
			# End drag
			end_drag()

func start_drag(draggable):
	if current_draggable:
		# Already dragging something
		return
	
	current_draggable = draggable
	original_position = draggable.global_position
	drag_offset = draggable.get_local_mouse_position()
	
	# Bring to front
	var parent = draggable.get_parent()
	parent.move_child(draggable, parent.get_child_count() - 1)
	
	emit_signal("drag_started", draggable)
	
	# Update drop targets to show valid ones
	highlight_valid_targets(true)

func end_drag():
	if not current_draggable:
		return
	
	# Find drop target under mouse
	var drop_target = get_drop_target_at_position(get_viewport().get_mouse_position())
	
	if drop_target:
		# Try to drop on target
		emit_signal("drop_attempted", current_draggable, drop_target.node)
		
		# Check if drop is valid
		if is_valid_drop(current_draggable, drop_target):
			emit_signal("drop_succeeded", current_draggable, drop_target.node)
		else:
			# Invalid drop
			current_draggable.global_position = original_position
			emit_signal("drop_failed", current_draggable)
	else:
		# No target found, return to original position
		current_draggable.global_position = original_position
		emit_signal("drop_failed", current_draggable)
	
	# Update drop targets to hide highlights
	highlight_valid_targets(false)
	
	# Reset state
	emit_signal("drag_ended", current_draggable)
	current_draggable = null

func _process(_delta):
	if current_draggable:
		# Move draggable with mouse
		current_draggable.global_position = get_viewport().get_mouse_position() - drag_offset

func get_drop_target_at_position(position: Vector2):
	for target in valid_drop_targets:
		var node = target.node
		if is_position_over_control(position, node):
			return target
	return null

func is_position_over_control(position: Vector2, control: Control) -> bool:
	# Convert global position to control's local space
	var local_pos = control.get_global_transform_with_canvas().affine_inverse() * position
	
	# Check if point is within control bounds
	var rect = Rect2(Vector2.ZERO, control.size)
	return rect.has_point(local_pos)

func is_valid_drop(draggable, drop_target) -> bool:
	# Check if draggable type matches accepted types
	if drop_target.valid_types.size() == 0:
		# No type restrictions
		return true
		
	# Check if draggable has a method to get its type
	if draggable.has_method("get_card_type"):
		var type = draggable.get_card_type()
		return type in drop_target.valid_types
		
	return false

func highlight_valid_targets(highlight: bool):
	if not current_draggable:
		return
		
	var draggable_type = ""
	if current_draggable.has_method("get_card_type"):
		draggable_type = current_draggable.get_card_type()
	
	# Update highlights on drop targets
	for target in valid_drop_targets:
		var is_valid = target.valid_types.size() == 0 or draggable_type in target.valid_types
		
		# Set highlight if target has the method
		if target.node.has_method("set_highlight"):
			target.node.set_highlight(highlight and is_valid)
```

### DataLoader.gd
```gdscript
extends Node
class_name DataLoader

# File paths
const CARDS_PATH = "res://data/cards.json"
const ENEMIES_PATH = "res://data/enemies.json"

func _ready():
	pass

func load_all_cards() -> Array:
	var cards = []
	
	# Load cards from JSON file
	var file = FileAccess.open(CARDS_PATH, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			var data = json.get_data()
			cards = data
	else:
		push_error("Failed to open cards file: " + CARDS_PATH)
		# Fallback to minimal data
		cards = _get_fallback_cards()
	
	return cards

func load_starting_deck() -> Array:
	# For the prototype, just load a subset of cards as starting deck
	var all_cards = load_all_cards()
	var starter_deck = []
	
	# Add some basic cards of each type
	var type_counts = {
		"Head": 0,
		"Core": 0,
		"Arm": 0,
		"Leg": 0,
		"Utility": 0
	}
	
	# Add a balanced starter deck
	for card in all_cards:
		if card.rarity == "Common" and type_counts[card.type] < 2:
			starter_deck.append(card)
			type_counts[card.type] += 1
	
	return starter_deck

func load_enemy_data() -> Array:
	var enemies = []
	
	# Load enemies from JSON file
	var file = FileAccess.open(ENEMIES_PATH, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			var data = json.get_data()
			enemies = data
	else:
		push_error("Failed to open enemies file: " + ENEMIES_PATH)
		# Fallback to minimal data
		enemies = _get_fallback_enemies()
	
	return enemies

func load_boss_data() -> Dictionary:
	var enemies = load_enemy_data()
	
	# Find the boss enemy
	for enemy in enemies:
		if enemy.get("is_boss", false):
			return enemy
	
	# Fallback to final enemy if no boss specified
	return enemies[enemies.size() - 1] if enemies.size() > 0 else _get_fallback_boss()

func load_reward_options() -> Array:
	# For prototype, just use a subset of all cards as rewards
	var all_cards = load_all_cards()
	var reward_options = []
	
	# Filter for uncommon and rare cards
	for card in all_cards:
		if card.rarity == "Uncommon" or card.rarity == "Rare":
			reward_options.append(card)
	
	return reward_options

# Fallback functions in case files can't be loaded
func _get_fallback_cards() -> Array:
	return [
		{
			"id": "scope_visor",
			"name": "Scope Visor",
			"type": "Head",
			"cost": 1,
			"heat": 0,
			"durability": 3,
			"effects": [
				{
					"type": "crit",
					"value": 10,
					"description": "+10% crit chance"
				}
			],
			"rarity": "Common",
			"description": "Basic targeting system with modest crit bonus."
		},
		{
			"id": "pulse_blaster",
			"name": "Pulse Blaster",
			"type": "Arm",
			"cost": 1,
			"heat": 0,
			"durability": 3,
			"effects": [
				{
					"type": "damage",
					"value": 6,
					"description": "6 damage per hit"
				}
			],
			"rarity": "Common",
			"description": "Standard energy weapon with consistent output."
		},
		{
			"id": "heavy_plating",
			"name": "Heavy Plating",
			"type": "Core",
			"cost": 1,
			"heat": 0,
			"durability": 5,
			"effects": [
				{
					"type": "armor",
					"value": 10,
					"description": "+10 Armor"
				},
				{
					"type": "move_speed_percent",
					"value": -5,
					"description": "-5% Move Speed"
				}
			],
			"rarity": "Common",
			"description": "Thick armor plating that slows movement slightly."
		},
		{
			"id": "tracked_legs",
			"name": "Tracked Legs",
			"type": "Leg",
			"cost": 1,
			"heat": 0,
			"durability": 4,
			"effects": [
				{
					"type": "stability",
					"value": 20,
					"description": "+20% stability"
				}
			],
			"rarity": "Common",
			"description": "Basic treads for stable movement."
		}
	]

func _get_fallback_enemies() -> Array:
	return [
		{
			"id": "scavenger_drone",
			"name": "Scavenger Drone",
			"hp": 8,
			"armor": 0,
			"damage": 1,
			"attack_speed": 2.0,
			"move_speed": 120,
			"behavior": "aggressive"
		},
		{
			"id": "guardian_sentry",
			"name": "Guardian Sentry",
			"hp": 15,
			"armor": 5,
			"damage": 3,
			"attack_speed": 0.8,
			"move_speed": 50,
			"behavior": "defensive"
		},
		{
			"id": "striker_unit",
			"name": "Striker Unit",
			"hp": 12,
			"armor": 2,
			"damage": 2,
			"attack_speed": 1.5,
			"move_speed": 100,
			"behavior": "flanking"
		}
	]

func _get_fallback_boss() -> Dictionary:
	return {
		"id": "juggernaut",
		"name": "Juggernaut Prototype",
		"hp": 30,
		"armor": 10,
		"damage": 4,
		"attack_speed": 1.0,
		"move_speed": 70,
		"behavior": "aggressive",
		"is_boss": true,
		"special_abilities": [
			{
				"name": "Adaptive Defense",
				"description": "Changes attack pattern at low health",
				"trigger": "on_health_threshold",
				"effect": "behavior_change"
			}
		]
	}
```

### Main.gd
```gdscript
extends Node
class_name Main

func _ready():
	print("Chassis Lab - Game Initialized")
	
	# Initialize Managers
	$Managers/GameManager.start_new_game()
```

## Example Scene Structure

### Main.tscn
```
Main (Node)
├── ViewportContainer
│   ├── BuildView (Scene instance)
│   └── CombatView (Scene instance, hidden initially)
├── HUD (Scene instance)
├── RewardScreen (Scene instance, hidden initially)
└── Managers (Node)
    ├── GameManager (GameManager.gd)
    ├── DeckManager (DeckManager.gd)
    ├── TurnManager (TurnManager.gd)
    └── CombatResolver (CombatResolver.gd)
```

### BuildView.tscn
```
BuildView (Node2D)
├── Background (Sprite)
├── ChassisView (Node2D)
│   ├── HeadSlot (Area2D)
│   ├── CoreSlot (Area2D)
│   ├── ArmSlotLeft (Area2D)
│   ├── ArmSlotRight (Area2D)
│   ├── LegSlotLeft (Area2D)
│   └── LegSlotRight (Area2D)
├── ScrapperArea (Area2D)
│   ├── ScrapperVisual (Sprite)
│   └── HeatDisplay (Label)
├── HandArea (Control)
└── StartCombatButton (Button)
```

### CombatView.tscn
```
CombatView (Node2D)
├── Arena (Node2D)
│   ├── Background (Sprite)
│   ├── Obstacles (Node2D)
│   ├── PlayerSpawnPoint (Marker2D)
│   └── EnemySpawnPoint (Marker2D)
├── CombatBezel (Node2D)
│   ├── BezelFrame (Sprite)
│   └── ScanlineEffect (Sprite)
└── CombatEffects (Node2D)
    └── Particles (CPUParticles2D)
```

### Robot.tscn
```
Robot (CharacterBody2D)
├── Sprite (Node2D)
│   ├── FrameSprite (Sprite)
│   ├── HeadSprite (Sprite)
│   ├── CoreSprite (Sprite)
│   ├── LeftArmSprite (Sprite)
│   ├── RightArmSprite (Sprite)
│   ├── LeftLegSprite (Sprite)
│   └── RightLegSprite (Sprite)
├── CollisionShape (CollisionShape2D)
├── HealthBar (ProgressBar)
├── HeatBar (ProgressBar)
└── WeaponPositions (Node2D)
    ├── LeftWeaponPos (Marker2D)
    └── RightWeaponPos (Marker2D)
```

### Card.tscn
```
Card (Control)
├── Background (Panel)
├── Image (TextureRect)
├── NameLabel (Label)
├── TypeLabel (Label)
├── StatsContainer (VBoxContainer)
│   ├── CostLabel (Label)
│   ├── HeatLabel (Label)
│   └── DurabilityLabel (Label)
├── EffectsLabel (Label)
└── Highlight (Panel)
```

## Example Usage - Starting Combat

1. Player drags cards onto robot chassis to build their robot
2. Player clicks "Start Combat" button
3. `BuildView` emits `combat_requested` signal
4. `GameManager` catches signal and calls `start_combat_phase()`
5. Combat begins, auto-resolving until one entity is defeated
6. `CombatResolver` emits `combat_ended` signal with result
7. `GameManager` shows reward screen or game over screen

This scaffolding provides the core structure needed for the game while keeping the implementation minimal and focused on getting a working prototype quickly.
