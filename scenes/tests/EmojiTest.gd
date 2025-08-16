extends Node2D

# Simple test script for emoji rendering

func _ready():
	create_test_ui()
	print("EmojiTest: Scene loaded, creating test UI with emoji characters")

func create_test_ui():
	# Create a container for our UI
	var container = VBoxContainer.new()
	container.name = "EmojiTestContainer"
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.size_flags_horizontal = Control.SIZE_FILL
	container.size_flags_vertical = Control.SIZE_FILL
	container.add_theme_constant_override("separation", 20)
	add_child(container)
	
	# Add a title
	var title = Label.new()
	title.text = "Emoji Test Scene"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	container.add_child(title)
	
	# Test with standard emoji
	add_emoji_test_row(container, "Standard emoji: 😀 😎 🚀 🎮 🔥")
	
	# Test with game-related emoji
	add_emoji_test_row(container, "Game emoji: 🎲 🎯 🏆 ⚔️ 🛡️")
	
	# Test with mixed text and emoji
	add_emoji_test_row(container, "Mixed text & emoji: Player 1 wins! 🎉 (+5 points 🌟)")
	
	# Test with multiple emoji in sequence
	add_emoji_test_row(container, "Emoji sequence: 🔴🔵🟢🟡")
	
	# Add a RichTextLabel test
	var rich_text = RichTextLabel.new()
	rich_text.bbcode_enabled = true
	rich_text.text = "[center]Rich Text with emoji: [wave]🌊[/wave] [rainbow]🌈[/rainbow][/center]"
	rich_text.fit_content = true
	rich_text.custom_minimum_size = Vector2(0, 50)
	container.add_child(rich_text)
	
	# Add a button with emoji
	var button = Button.new()
	button.text = "Click me! 👆"
	button.pressed.connect(func(): print("Button clicked!"))
	container.add_child(button)
	
	# Apply retro theme to all elements
	RetroUtils.apply_retro_theme(container)

func add_emoji_test_row(container, text_content):
	var label = Label.new()
	label.text = text_content
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(label)
