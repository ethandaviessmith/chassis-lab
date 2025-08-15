extends Node

# References to important nodes
var sound_manager = null
var screen_shake = null

# Main viewport
var viewport = null

func _ready():
    print("RetroThemeManager: Initializing...")
    
    # Apply theme to viewport
    viewport = get_viewport()
    if viewport:
        # Apply CRT shader to viewport
        _setup_crt_effect(viewport)
    
    # Load and set default theme
    var theme = load("res://assets/themes/retro_theme.tres")
    if theme:
        print("RetroThemeManager: Setting default theme")
        theme.default_font_size = 12
        theme.default_font = load("res://assets/BoldPixels1.4.ttf")
        get_tree().root.theme = theme
    else:
        push_error("RetroThemeManager: Could not load theme")
    
    # Create sound manager if it doesn't exist
    _initialize_sound_manager()
    
    # Add screen shake to main scene when loaded
    get_tree().root.ready.connect(_setup_screen_shake)
    
    print("RetroThemeManager: Initialization complete")

# Apply CRT shader to viewport
func _setup_crt_effect(viewport_node):
    # Check if we already have a CRT effect
    if viewport_node.get_meta("has_crt_effect", false):
        return
        
    print("RetroThemeManager: Setting up CRT effect")
    
    # Create a new CanvasLayer for the CRT effect
    var canvas_layer = CanvasLayer.new()
    canvas_layer.layer = 100  # On top of everything
    get_tree().root.add_child(canvas_layer)
    
    # Create ColorRect that covers the whole screen
    var color_rect = ColorRect.new()
    color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
    canvas_layer.add_child(color_rect)
    
    # Create and apply shader material
    var shader = load("res://assets/shaders/crt_effect.gdshader")
    if shader:
        var material = ShaderMaterial.new()
        material.shader = shader
        material.set_shader_parameter("scan_opacity", 0.1)
        material.set_shader_parameter("line_spacing", 3)
        material.set_shader_parameter("line_thickness", 1)
        color_rect.material = material
        
        # Mark that we've added the effect
        viewport_node.set_meta("has_crt_effect", true)
    else:
        push_error("RetroThemeManager: Could not load CRT shader")

# Initialize sound manager
func _initialize_sound_manager():
    # Check if sound manager already exists
    if get_node_or_null("/root/SoundManager") != null:
        sound_manager = get_node("/root/SoundManager")
        print("RetroThemeManager: SoundManager already exists")
        return
        
    # Create sound manager
    sound_manager = SoundManager.new()
    sound_manager.name = "SoundManager"
    get_tree().root.add_child(sound_manager)
    print("RetroThemeManager: Created SoundManager")

# Set up screen shake on main scene
func _setup_screen_shake():
    # Wait a bit to ensure scene is fully loaded
    await get_tree().create_timer(0.5).timeout
    
    # Find the main scene
    var main = get_tree().current_scene
    if main == null:
        push_error("RetroThemeManager: No current scene to add screen shake to")
        return
    
    # Check if screen shake already exists
    if main.get_node_or_null("ScreenShake") != null:
        screen_shake = main.get_node("ScreenShake")
        print("RetroThemeManager: ScreenShake already exists")
        return
    
    # Add screen shake node
    screen_shake = load("res://scripts/utils/ScreenShake.gd").new()
    screen_shake.name = "ScreenShake"
    main.add_child(screen_shake)
    print("RetroThemeManager: Added ScreenShake to ", main.name)
