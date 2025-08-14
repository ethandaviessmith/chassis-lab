class_name RetroUtils
extends Object

# Retro color palette inspired by classic systems
class Colors:
	# Base colors
	const BLACK = Color("#000000")
	const WHITE = Color("#ffffff")
	
	# Primary colors - saturated for high contrast
	const RED = Color("#ff2121")
	const GREEN = Color("#21ff21")
	const BLUE = Color("#2121ff")
	const YELLOW = Color("#fff221")
	const CYAN = Color("#21ffff")
	const MAGENTA = Color("#ff21ff")
	
	# Secondary colors - more muted but still distinctive
	const ORANGE = Color("#ff8021")
	const PURPLE = Color("#8021ff")
	const BROWN = Color("#7f5400")
	const PINK = Color("#ff80a0")
	
	# UI specific colors
	const UI_BACKGROUND = Color("#2a2a3a")  # Dark blue-gray
	const UI_BORDER = Color("#5555aa")      # Mid blue-purple
	const UI_TEXT = Color("#ccccff")        # Light blue-white
	const UI_HIGHLIGHT = Color("#ffcc00")   # Gold/amber highlight
	const UI_ERROR = Color("#ff3030")       # Bright error red
	
	# Disabled/inactive state
	const UI_DISABLED = Color("#555566")
	
	# Terminal colors
	const TERM_BACKGROUND = Color("#000000")
	const TERM_TEXT = Color("#33ff33")      # Green terminal text
	const TERM_CURSOR = Color("#33ff33")    # Matching cursor
	const TERM_HIGHLIGHT = Color("#ffff33") # Yellow highlight
	
	# Card rarity colors
	const COMMON = Color("#aaaacc")
	const UNCOMMON = Color("#55aa55") 
	const RARE = Color("#5555ff")
	const EPIC = Color("#aa55aa")
	const LEGENDARY = Color("#ffaa00")

# Screen effect settings
class ScreenEffects:
	const SCANLINE_OPACITY = 0.1
	const SCANLINE_WIDTH = 1
	const SCANLINE_SPACING = 3
	const SHAKE_STRENGTH = 5.0
	const SHAKE_DURATION = 0.15

# Sound settings
class Sounds:
	const CLICK_VOLUME_DB = -10.0
	const UI_VOLUME_DB = -5.0
	const MASTER_VOLUME_DB = 0.0

# Font settings
class FontSettings:
	const DEFAULT_SIZE = 12
	const HEADER_SIZE = 16
	const TITLE_SIZE = 24
	const SMALL_SIZE = 10

# Apply a retro theme to a Control node
static func apply_retro_theme(node: Control) -> void:
	if node == null:
		return
		
	# Set colors
	node.modulate = Colors.UI_TEXT
	
	# Set font if it's a label or button
	if node is Label or node is Button or node is RichTextLabel:
		var font_res = load("res://assets/BoldPixels1.4.ttf")
		if font_res != null:
			var font = FontVariation.new()
			font.base_font = font_res
			
			var font_size = FontSettings.DEFAULT_SIZE
			if node.has_meta("font_size"):
				font_size = node.get_meta("font_size")
			
			if node is Label:
				node.add_theme_font_override("font", font)
				node.add_theme_font_size_override("font_size", font_size)
			elif node is Button:
				node.add_theme_font_override("font", font)
				node.add_theme_font_size_override("font_size", font_size)
			elif node is RichTextLabel:
				node.add_theme_font_override("normal_font", font)
				node.add_theme_font_size_override("normal_font_size", font_size)
				
	# Recursively apply to all children
	for child in node.get_children():
		if child is Control:
			apply_retro_theme(child)
