@tool
extends Control
class_name NextEnemyDisplay

# UI Elements
var enemy_name_label: Label
var enemy_hp_label: Label
var enemy_damage_label: Label
var enemy_armor_label: Label
var enemy_speed_label: Label
var enemy_image: TextureRect
var boss_indicator: Label

# Reference to EnemyManager
@export var enemy_manager: Node

# Preview options for editor
@export var show_preview_in_editor: bool = true
@export_group("Preview Enemy Data")
@export var preview_enemy_name: String = "Preview Enemy"
@export var preview_enemy_hp: int = 15
@export var preview_enemy_damage: int = 3
@export var preview_enemy_armor: int = 2
@export var preview_enemy_speed: int = 100
@export var preview_is_boss: bool = false

# Enemy data
var enemy_data = null

func _enter_tree():
	# Create UI elements when entering the tree (works in editor)
	setup_ui()
	
	# Show preview in editor
	if Engine.is_editor_hint() and show_preview_in_editor:
		_show_editor_preview()

func _ready():
	# Only run game code when not in editor
	if not Engine.is_editor_hint():
		# Connect to enemy manager signals
		if enemy_manager and enemy_manager.has_signal("next_enemy_determined"):
			enemy_manager.next_enemy_determined.connect(_on_next_enemy_determined)
			
			# Try to get initial enemy data if already available
			if enemy_manager.has_method("get_next_enemy"):
				var initial_enemy = enemy_manager.get_next_enemy()
				if initial_enemy:
					update_display(initial_enemy)
					
# Show preview values in the editor
func _show_editor_preview():
	var preview_data = {
		"name": preview_enemy_name,
		"hp": preview_enemy_hp,
		"damage": preview_enemy_damage,
		"armor": preview_enemy_armor,
		"move_speed": preview_enemy_speed,
		"is_boss": preview_is_boss
	}
	update_display(preview_data)

# Set up the UI elements
func setup_ui():
	# Create background panel
	# var panel = Panel.new()
	# panel.name = "BackgroundPanel"
	# panel.anchor_right = 1.0
	# panel.anchor_bottom = 1.0
	# add_child(panel)
	
	# # Create title label
	# var title_label = Label.new()
	# title_label.name = "TitleLabel"
	# title_label.text = "NEXT ENEMY"
	# title_label.add_theme_font_size_override("font_size", 16)
	# title_label.position = Vector2(10, 10)
	# add_child(title_label)
	
	# Create enemy image placeholder
	enemy_image = TextureRect.new()
	enemy_image.name = "EnemyImage"
	enemy_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_image.position = Vector2(10, 40)
	enemy_image.size = Vector2(80, 80)
	# Use a placeholder colored rect until we have an actual image
	var placeholder_image = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	placeholder_image.fill(Color(0.6, 0.3, 0.3))
	var placeholder_texture = ImageTexture.create_from_image(placeholder_image)
	enemy_image.texture = placeholder_texture
	add_child(enemy_image)
	
	# Create boss indicator (hidden by default)
	boss_indicator = Label.new()
	boss_indicator.name = "BossIndicator"
	boss_indicator.text = "BOSS"
	boss_indicator.add_theme_font_size_override("font_size", 18)
	boss_indicator.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	boss_indicator.position = Vector2(110, 40)
	boss_indicator.visible = false
	add_child(boss_indicator)
	
	# Create enemy stats container
	var stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.position = Vector2(100, 70)
	stats_container.size = Vector2(size.x - 110, size.y - 80)
	add_child(stats_container)
	
	# Create enemy name label
	enemy_name_label = Label.new()
	enemy_name_label.name = "NameLabel"
	enemy_name_label.text = "Unknown Enemy"
	enemy_name_label.add_theme_font_size_override("font_size", 14)
	stats_container.add_child(enemy_name_label)
	
	# Create enemy HP label
	enemy_hp_label = Label.new()
	enemy_hp_label.name = "HPLabel"
	enemy_hp_label.text = "HP: ??"
	enemy_hp_label.add_theme_font_size_override("font_size", 12)
	stats_container.add_child(enemy_hp_label)
	
	# Create enemy damage label
	enemy_damage_label = Label.new()
	enemy_damage_label.name = "DamageLabel"
	enemy_damage_label.text = "DMG: ??"
	enemy_damage_label.add_theme_font_size_override("font_size", 12)
	stats_container.add_child(enemy_damage_label)
	
	# Create enemy armor label
	enemy_armor_label = Label.new()
	enemy_armor_label.name = "ArmorLabel"
	enemy_armor_label.text = "ARM: ??"
	enemy_armor_label.add_theme_font_size_override("font_size", 12)
	stats_container.add_child(enemy_armor_label)
	
	# Create enemy speed label
	enemy_speed_label = Label.new()
	enemy_speed_label.name = "SpeedLabel"
	enemy_speed_label.text = "SPD: ??"
	enemy_speed_label.add_theme_font_size_override("font_size", 12)
	stats_container.add_child(enemy_speed_label)

# Update the display with new enemy data
func update_display(data):
	self.enemy_data = data
	
	# Update labels with enemy data
	enemy_name_label.text = data.name
	enemy_hp_label.text = "HP: " + str(data.hp)
	enemy_damage_label.text = "DMG: " + str(data.damage)
	enemy_armor_label.text = "ARM: " + str(data.armor)
	enemy_speed_label.text = "SPD: " + str(data.move_speed)
	
	# Show boss indicator if this is a boss
	boss_indicator.visible = data.is_boss
	
	# Load enemy image if available
	if data.has("sprite") and data.sprite.length() > 0:
		var enemy_texture = load(data.sprite)
		if enemy_texture:
			enemy_image.texture = enemy_texture
	
	# Adjust colors based on enemy type/power
	if enemy_data.is_boss:
		enemy_name_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	else:
		enemy_name_label.remove_theme_color_override("font_color")
		
	# Animate the display update
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.2), 0.3)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.3)

# Handle next enemy determined signal
func _on_next_enemy_determined(data):
	update_display(data)
