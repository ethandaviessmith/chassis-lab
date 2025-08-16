extends Node2D

# DiagnosticScene for emoji font debugging
# This scene will help diagnose emoji rendering issues
# and provide more insights about the text server and font capabilities

func _ready():
    print("DiagnosticScene: Starting font diagnostics")
    create_diagnostic_ui()

func create_diagnostic_ui():
    # Create a ScrollContainer with VBoxContainer for the diagnostic info
    var scroll = ScrollContainer.new()
    scroll.anchor_right = 1.0
    scroll.anchor_bottom = 1.0
    scroll.size_flags_horizontal = Control.SIZE_FILL
    scroll.size_flags_vertical = Control.SIZE_FILL
    add_child(scroll)
    
    var container = VBoxContainer.new()
    container.size_flags_horizontal = Control.SIZE_FILL
    container.add_theme_constant_override("separation", 20)
    scroll.add_child(container)
    
    # Add a title
    add_section_title(container, "Emoji Font Diagnostics")
    
    # Platform info
    add_section_title(container, "Platform Information")
    add_info_row(container, "Platform", OS.get_name())
    add_info_row(container, "Engine Version", Engine.get_version_info()["string"])
    
    # Text server info
    add_section_title(container, "Text Server Information")
    var text_server = TextServerManager.get_primary_interface()
    add_info_row(container, "TextServer Name", text_server.get_name())
    add_info_row(container, "TextServer Features", get_text_server_features_string(text_server))
    
    # Font diagnostics
    add_section_title(container, "Font Manager Diagnostics")
    if has_node("/root/FontManager"):
        var font_manager = get_node("/root/FontManager")
        # Default font info
        if font_manager.default_font:
            add_info_row(container, "Default Font", "Loaded")
            add_info_row(container, "Default Font Path", font_manager.DEFAULT_FONT_PATH)
        else:
            add_info_row(container, "Default Font", "Failed to load")
        
        # Emoji font info
        if font_manager.emoji_font:
            add_info_row(container, "Emoji Font", "Loaded")
            add_info_row(container, "Emoji Font Path", font_manager.EMOJI_FONT_PATH if not font_manager.is_web_platform else "System fonts")
        else:
            add_info_row(container, "Emoji Font", "Failed to load")
        
        # Font configuration info
        if font_manager.font_configuration:
            add_info_row(container, "Font Configuration", "Created")
            add_info_row(container, "Fallbacks Count", str(font_manager.font_configuration.fallbacks.size()))
        else:
            add_info_row(container, "Font Configuration", "Failed to create")
    else:
        add_info_row(container, "Font Manager", "Not found as singleton")
    
    # Test emoji rendering
    add_section_title(container, "Emoji Rendering Tests")
    add_emoji_test_row(container, "Standard emoji: 😀 😎 🚀 🎮 🔥", 24)
    add_emoji_test_row(container, "Game emoji: 🎲 🎯 🏆 ⚔️ 🛡️", 24)
    add_emoji_test_row(container, "Mixed text & emoji: Player 1 wins! 🎉", 24)
    
    # Character code display for emoji
    add_section_title(container, "Character Codes")
    add_character_codes(container, "😀", "Grinning Face")
    add_character_codes(container, "🚀", "Rocket")
    add_character_codes(container, "🎮", "Game Controller")

func add_section_title(container, title_text):
    var title = Label.new()
    title.text = title_text
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 24)
    container.add_child(title)
    
    # Add separator
    var sep = HSeparator.new()
    container.add_child(sep)

func add_info_row(container, label_text, value_text):
    var hbox = HBoxContainer.new()
    hbox.size_flags_horizontal = Control.SIZE_FILL
    container.add_child(hbox)
    
    var label = Label.new()
    label.text = label_text + ":"
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.size_flags_stretch_ratio = 0.4
    hbox.add_child(label)
    
    var value = Label.new()
    value.text = value_text
    value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    value.size_flags_stretch_ratio = 0.6
    hbox.add_child(value)

func add_emoji_test_row(container, text_content, font_size = 16):
    var label = Label.new()
    label.text = text_content
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    container.add_child(label)

func add_character_codes(container, character, description):
    var text = "Character: %s (%s)\nUnicode: " % [character, description]
    
    # Get Unicode code points
    var unicode_points = []
    for i in range(character.length()):
        unicode_points.append(character.unicode_at(i))
    
    # Format the code points as hex
    var hex_codes = []
    for code in unicode_points:
        hex_codes.append("U+%04X" % code)
    
    text += ", ".join(hex_codes)
    
    var label = Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    container.add_child(label)

func get_text_server_features_string(text_server) -> String:
    var features = []
    
    # Check for various features
    if text_server.has_feature(TextServer.FEATURE_SIMPLE_LAYOUT):
        features.append("Simple Layout")
    if text_server.has_feature(TextServer.FEATURE_COMPLEX_LAYOUT):
        features.append("Complex Layout")
    if text_server.has_feature(TextServer.FEATURE_CONTEXT_SENSITIVE_CASE_CONVERSION):
        features.append("Context Sensitive Case")
    if text_server.has_feature(TextServer.FEATURE_SHAPING):
        features.append("Text Shaping")
    if text_server.has_feature(TextServer.FEATURE_KASHIDA_JUSTIFICATION):
        features.append("Kashida Justification")
    if text_server.has_feature(TextServer.FEATURE_TRIM_EDGE_SPACES):
        features.append("Trim Edge Spaces")
    if text_server.has_feature(TextServer.FEATURE_TEXT_DIRECTION):
        features.append("Text Direction")
    
    if features.is_empty():
        return "None detected"
    else:
        return ", ".join(features)
