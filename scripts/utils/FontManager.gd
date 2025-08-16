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

# Platform detection
var is_web_platform: bool = false

func _ready():
    # Detect platform
    detect_platform()
    
    # Load fonts
    load_fonts()
    
    # Configure TextServer for emoji support
    configure_text_server()
    
    print("FontManager: Fonts initialized successfully")
    
func detect_platform():
    # Check if running on web platform
    is_web_platform = OS.get_name() == "Web"
    print("FontManager: Detected platform: " + OS.get_name() + " (is_web=" + str(is_web_platform) + ")")
    
    # Print text server info
    var text_server = TextServerManager.get_primary_interface()
    print("FontManager: Using text server: " + text_server.get_name())
    
func load_fonts():
    # Load the default font first (needed in both cases)
    if ResourceLoader.exists(DEFAULT_FONT_PATH):
        default_font = load(DEFAULT_FONT_PATH)
        print("FontManager: Default font loaded successfully")
    else:
        push_error("FontManager: Failed to load default font from " + DEFAULT_FONT_PATH)
    
    # Special handling for web platform
    if is_web_platform:
        load_web_platform_fonts()
    else:
        # Load the emoji font for desktop platforms
        if ResourceLoader.exists(EMOJI_FONT_PATH):
            emoji_font = load(EMOJI_FONT_PATH)
            print("FontManager: Emoji font loaded successfully")
        else:
            push_error("FontManager: Failed to load emoji font from " + EMOJI_FONT_PATH)
    
    # Create font variation for fallback configuration
    setup_font_variation()

func load_web_platform_fonts():
    # For web platform, we'll attempt a different approach
    # We'll try to use system fonts as fallbacks
    
    # Create a SystemFont resource
    var sys_font = SystemFont.new()
    sys_font.font_names = ["Arial", "Segoe UI Emoji", "Segoe UI Symbol", "Apple Color Emoji", "Noto Color Emoji"]
    sys_font.oversampling = 2.0  # Increase quality
    
    print("FontManager: Using system fonts for web platform")
    emoji_font = sys_font

func setup_font_variation():
    font_configuration = FontVariation.new()
    font_configuration.base_font = default_font
    
    # Add emoji font as fallback
    if emoji_font:
        # Different approach based on platform
        if is_web_platform:
            # For web, try to use the fallbacks array with the system font
            font_configuration.fallbacks.append(emoji_font)
            print("FontManager: Web platform emoji fallback configured")
        else:
            # Desktop platforms
            font_configuration.fallbacks.append(emoji_font)
            print("FontManager: Desktop emoji fallback configured")
    
func configure_text_server():
    # Get the text server interface
    var text_server = TextServerManager.get_primary_interface()
    
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
    
    # Platform-specific configuration
    if is_web_platform:
        # For web platform, we need to configure additional settings
        
        # Try to enable font hinting which can help with emoji rendering
        if font_configuration:
            font_configuration.hinting = TextServer.HINTING_LIGHT
            print("FontManager: Web platform - configured font hinting")
            
        # Try to access some text server features - these might help with text layout
        if text_server.has_feature(TextServer.FEATURE_SIMPLE_LAYOUT):
            # The BiDi function requires specific parameters, but we'll skip that
            # Just note that we have this feature available
            print("FontManager: Web platform - text server supports simple layout")
            
        print("FontManager: Web platform theme configured")
    else:
        print("FontManager: Desktop theme configured")
        
    print("FontManager: Default theme configured with emoji support")

func get_configured_font() -> FontVariation:
    return font_configuration

# Apply emoji-compatible font to a specific control
func apply_emoji_font_to_control(control: Control):
    if control and font_configuration:
        control.add_theme_font_override("font", font_configuration)
