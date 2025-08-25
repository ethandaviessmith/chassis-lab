@tool
extends Control
class_name CardQuantityItem

# UI elements
@onready var card_info: RichTextLabel = $VBoxContainer/CardInfo
@onready var card_preview: Card = %Card
@onready var quantity_label: Label = $VBoxContainer/QuantityContainer/QuantityLabel
@onready var decrease_button: Button = $VBoxContainer/QuantityContainer/DecreaseButton
@onready var increase_button: Button = $VBoxContainer/QuantityContainer/IncreaseButton

# Signals
signal quantity_changed(card_id: String, new_count: int)

# Card data
var card_data = null
var quantity: int = 0
var card_id: String = ""

func _ready():
    # Connect buttons
    decrease_button.pressed.connect(_on_decrease)
    increase_button.pressed.connect(_on_increase)
    
    # Update UI
    _update_display()

# Initialize with card data
func initialize(data, count: int = 0):
    card_data = data
    card_id = data.id
    quantity = count
    _update_display()

# Update the display
func _update_display():
    if card_data:
        # Format card info with rarity color
        var rarity_color = _get_rarity_color(card_data.rarity)
        var type_color = _get_type_color(card_data.type)
        
        # Update card info label
        card_info.text = "[color=%s]%s[/color] - [color=%s]%s[/color]" % [
            rarity_color.to_html(),
            card_data.name,
            type_color.to_html(),
            card_data.type
        ]
        
        # Update card preview
        if card_preview:
            card_preview.initialize(card_data, null, null)
        
        # Update quantity
        quantity_label.text = str(quantity)
        
        # Enable/disable buttons as needed
        decrease_button.disabled = quantity <= 0
        
        # Apply color styling based on card rarity
        var frame_color = _get_rarity_color(card_data.rarity)
        modulate = Color.WHITE.lerp(frame_color, 0.2)
    
# Get color based on rarity
func _get_rarity_color(rarity: String) -> Color:
    match rarity:
        "Common": 
            return Color.WHITE
        "Uncommon": 
            return Color(0.5, 1.0, 0.5)  # Light green
        "Rare": 
            return Color(0.5, 0.5, 1.0)  # Light blue
        _: 
            return Color.WHITE

# Get color based on card type
func _get_type_color(type: String) -> Color:
    match type:
        "Head": 
            return Color(1.0, 0.7, 0.3)  # Orange
        "Core": 
            return Color(1.0, 0.5, 0.5)  # Red
        "Arm": 
            return Color(0.3, 0.7, 1.0)  # Light blue
        "Legs": 
            return Color(0.5, 1.0, 0.5)  # Green
        "Utility": 
            return Color(0.8, 0.8, 0.8)  # Grey
        _: 
            return Color.WHITE

# Decrease quantity
func _on_decrease():
    if quantity > 0:
        quantity -= 1
        _update_display()
        quantity_changed.emit(card_id, quantity)

# Increase quantity
func _on_increase():
    # Consider a max limit if needed
    quantity += 1
    _update_display()
    quantity_changed.emit(card_id, quantity)
    
# Update the card preview texture and styling
func _update_card_preview():
    if card_data and card_preview:
        # Set background color based on card type
        var bg_color = _get_type_color(card_data.type)
        
        # Set border color based on rarity
        var border_color = _get_rarity_color(card_data.rarity)
        
        # If we have a frame texture, use it
        var texture_path = _get_card_texture_path()
        if texture_path:
            var texture = load(texture_path)
            if texture:
                card_preview.texture = texture
                
        # Set a custom stylebox for the card frame
        var frame_style = StyleBoxFlat.new()
        frame_style.bg_color = bg_color.darkened(0.7)
        frame_style.border_color = border_color
        frame_style.border_width_top = 2
        frame_style.border_width_right = 2
        frame_style.border_width_bottom = 2
        frame_style.border_width_left = 2
        frame_style.corner_radius_top_left = 4
        frame_style.corner_radius_top_right = 4
        frame_style.corner_radius_bottom_left = 4
        frame_style.corner_radius_bottom_right = 4
        
        # Apply the style to the card preview
        if card_preview.get("custom_minimum_size"):
            card_preview.custom_minimum_size = Vector2(120, 160)
            
        # If no texture was loaded, set a fallback color
        if not card_preview.texture:
            card_preview.modulate = bg_color

# Get the appropriate texture path based on card type
func _get_card_texture_path() -> String:
    if not card_data:
        return ""
        
    # Default path format for card images
    var base_path = "res://assets/card_bg.png"
    
    # For more advanced implementations, you could have different 
    # background images based on card type or rarity
    return base_path
