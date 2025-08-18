extends Node

# FontManager - Handles font configuration and emoji support
# This singleton manages fonts including emoji support for cross-platform compatibility

# Constants for font paths
const EMOJI_FONT_PATH = "res://assets/fonts/NotoColorEmoji.ttf"
const DEFAULT_FONT_PATH = "res://assets/BoldPixels1.4.ttf"

# Fonts loaded at runtime
var emoji_font: FontFile
var default_font: FontFile
var font_configuration: FontVariation

func _ready():
    # Load fonts
    load_fonts()
    
    # Configure TextServer for emoji support
    configure_text_server()
    
    print("FontManager: Fonts initialized successfully")
    
func load_fonts():
    # Load the emoji font
    if ResourceLoader.exists(EMOJI_FONT_PATH):
        emoji_font = load(EMOJI_FONT_PATH)
        print("FontManager: Emoji font loaded successfully")
    else:
        push_error("FontManager: Failed to load emoji font from " + EMOJI_FONT_PATH)
    
    # Load the default font
    if ResourceLoader.exists(DEFAULT_FONT_PATH):
        default_font = load(DEFAULT_FONT_PATH)
        print("FontManager: Default font loaded successfully")
    else:
        push_error("FontManager: Failed to load default font from " + DEFAULT_FONT_PATH)
    
    # Create font variation for fallback configuration
    setup_font_variation()

func setup_font_variation():
    font_configuration = FontVariation.new()
    font_configuration.base_font = default_font
    
    # Add emoji font as fallback
    if emoji_font:
        font_configuration.fallbacks.append(emoji_font)
        print("FontManager: Emoji fallback font configured")
    
func configure_text_server():
    # Configure any TextServer-specific settings for emoji support
    
    # Apply the emoji-enabled font to the default theme
    var theme = ThemeDB.get_default_theme()
    
    # Apply to common control types
    theme.set_font("font", "Label", font_configuration)
    theme.set_font("font", "Button", font_configuration)
    theme.set_font("normal_font", "RichTextLabel", font_configuration)
    
    # Set default font size
    theme.set_font_size("font_size", "Label", 16)
    theme.set_font_size("font_size", "Button", 16)
    theme.set_font_size("normal_font_size", "RichTextLabel", 16)
    
    print("FontManager: Default theme configured with emoji support")

func get_configured_font() -> FontVariation:
    return font_configuration

# Apply emoji-compatible font to a specific control
func apply_emoji_font_to_control(control: Control):
    if control and font_configuration:
        control.add_theme_font_override("font", font_configuration)
