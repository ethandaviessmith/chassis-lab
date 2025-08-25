@tool
extends Control
class_name DeckEditorView

# UI Elements
@onready var deck_name_input: LineEdit = $TitleBar/DeckNameInput
@onready var save_button: Button = $TitleBar/SaveButton
@onready var deck_dropdown: OptionButton = $TitleBar/DeckDropdown
@onready var card_grid: GridContainer = $CardScrollContainer/CardGrid
@onready var close_button: Button = $TitleBar/CloseButton
@onready var total_cards_label: Label = $TitleBar/TotalCardsLabel

# External references
@export var deck_config_manager: DeckConfigManager
@export var data_loader: DataLoader
@export var deck_manager: DeckManager
@export var card_quantity_scene: PackedScene

# State tracking
var current_deck_name: String = ""
var current_card_counts: Dictionary = {}
var all_cards: Array = []
var original_position: Vector2

func _ready():
    # Store the original position before hiding
    original_position = position
    
    # Hide the editor initially
    visible = false
    
    # Connect buttons
    if save_button:
        save_button.pressed.connect(_on_save_button_pressed)
    
    if deck_dropdown:
        deck_dropdown.item_selected.connect(_on_deck_dropdown_item_selected)
    
    if close_button:
        close_button.pressed.connect(_on_close_button_pressed)
    
    # Load all available cards
    if data_loader:
        all_cards = data_loader.load_all_cards()
    
    # Update dropdown with available decks
    if deck_config_manager:
        deck_config_manager.decks_updated.connect(_update_deck_dropdown)
        _update_deck_dropdown()

# Show the deck editor with optional preset deck
func show_editor(deck_name: String = ""):
    # Make visible but fully transparent
    visible = true
    modulate.a = 0.0
    
    # Reset to the original saved position
    var target_position = original_position
    
    # Start from bottom of screen
    position.y = get_viewport_rect().size.y
    
    # Animate appearance with sliding and fading
    var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    tween.parallel().tween_property(self, "position:y", target_position.y, 1.0)
    tween.parallel().tween_property(self, "modulate:a", 1.0, 0.7)
    
    # Load selected deck or default to current
    if deck_name != "":
        _load_deck(deck_name)
    else:
        # Use current deck from deck_manager
        _use_current_deck()

# Hide the deck editor
func hide_editor():
    # Get the bottom of screen position
    var bottom_position = get_viewport_rect().size.y
    
    # Animate disappearance with sliding and fading
    var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
    tween.parallel().tween_property(self, "position:y", bottom_position, 1.0)
    tween.parallel().tween_property(self, "modulate:a", 0.0, 0.7)
    
    # Hide when animation completes
    tween.tween_callback(func(): visible = false)

# Update the dropdown with saved decks
func _update_deck_dropdown():
    if deck_dropdown and deck_config_manager:
        deck_dropdown.clear()
        
        var deck_names = deck_config_manager.get_deck_names()
        for i in range(deck_names.size()):
            var deck_name = deck_names[i]
            var deck_data = deck_config_manager.get_full_deck_data(deck_name)
            var display_name = deck_data.name
            
            deck_dropdown.add_item(display_name, i)
            deck_dropdown.set_item_metadata(i, deck_name)
        
        # Add an option for creating a new deck
        deck_dropdown.add_item("+ Create New Deck", deck_names.size())

# Load a deck by name
func _load_deck(deck_name: String):
    if deck_config_manager:
        var deck_data = deck_config_manager.get_full_deck_data(deck_name)
        current_deck_name = deck_name
        deck_name_input.text = deck_data.name
        
        # Reset card counts
        current_card_counts.clear()
        
        # Set counts based on deck data
        for card_entry in deck_data.cards:
            current_card_counts[card_entry.id] = card_entry.count
        
        # Update UI
        _populate_card_grid()
        _update_total_cards()
        
        # Select in dropdown
        for i in range(deck_dropdown.item_count):
            if deck_dropdown.get_item_metadata(i) == deck_name:
                deck_dropdown.select(i)
                break

# Use the current deck from deck_manager
func _use_current_deck():
    if deck_manager:
        var current_deck = deck_manager.get_full_deck()
        
        # Convert to card counts
        current_card_counts.clear()
        for card in current_deck:
            var card_id = card.id
            if current_card_counts.has(card_id):
                current_card_counts[card_id] += 1
            else:
                current_card_counts[card_id] = 1
        
        # Set default name if creating new
        current_deck_name = ""
        deck_name_input.text = "New Deck"
        
        # Update UI
        _populate_card_grid()
        _update_total_cards()

# Populate the card grid with all available cards
func _populate_card_grid():
    # Clear existing items
    for child in card_grid.get_children():
        child.queue_free()
    
    # Sort cards by type and rarity
    all_cards.sort_custom(func(a, b): 
        if a.type != b.type:
            # Order by type: Head, Core, Arm, Legs, Utility
            var type_order = {"head": 1, "core": 2, "arm": 3, "legs": 4, "utility": 5, 
                             "Head": 1, "Core": 2, "Arm": 3, "Legs": 4, "Utility": 5}
            
            # Get types in lowercase for consistent comparison
            var a_type = a.type.to_lower()
            var b_type = b.type.to_lower()
            
            # Use default order for unknown types
            if not type_order.has(a_type):
                return false
            if not type_order.has(b_type):
                return true
                
            return type_order[a_type] < type_order[b_type]
        else:
            # Order by rarity: Rare, Uncommon, Common
            var rarity_order = {"rare": 1, "uncommon": 2, "common": 3,
                               "Rare": 1, "Uncommon": 2, "Common": 3}
            
            # Get rarities in lowercase for consistent comparison
            var a_rarity = a.rarity.to_lower()
            var b_rarity = b.rarity.to_lower()
            
            if not rarity_order.has(a_rarity):
                return false
            if not rarity_order.has(b_rarity):
                return true
                
            return rarity_order[a_rarity] < rarity_order[b_rarity]
    )
    
    # Add items for each card
    for card_data in all_cards:
        var card_id = card_data.id
        var count = current_card_counts.get(card_id, 0)
        
        var quantity_item = card_quantity_scene.instantiate()
        card_grid.add_child(quantity_item)
        
        # Set up the item
        quantity_item.initialize(card_data, count)
        quantity_item.quantity_changed.connect(func(id, new_count): _on_card_quantity_changed(id, new_count))

# Update the total card count label
func _update_total_cards():
    var total = 0
    for count in current_card_counts.values():
        total += count
    
    total_cards_label.text = "Total Cards: " + str(total)

# Handle card quantity changes
func _on_card_quantity_changed(card_id: String, new_count: int):
    if new_count > 0:
        current_card_counts[card_id] = new_count
    else:
        current_card_counts.erase(card_id)
    
    _update_total_cards()

# Save the current deck
func _on_save_button_pressed():
    var deck_name = deck_name_input.text.strip_edges()
    if deck_name.length() == 0:
        # TODO: Show error message
        return
    
    # Create deck data
    var card_entries = []
    for card_id in current_card_counts.keys():
        var count = current_card_counts[card_id]
        if count > 0:
            card_entries.append({
                "id": card_id,
                "count": count
            })
    
    var deck_data = {
        "name": deck_name,
        "description": "",
        "cards": card_entries
    }
    
    # Generate unique key if this is a new deck
    var deck_key = current_deck_name
    if deck_key == "":
        # Use the name but convert to a valid key
        deck_key = deck_name.to_lower().replace(" ", "_")
        var base_key = deck_key
        var counter = 1
        
        # Ensure unique key
        while deck_config_manager.saved_decks.has(deck_key):
            deck_key = base_key + "_" + str(counter)
            counter += 1
    
    # Save the deck
    if deck_config_manager.save_deck(deck_key, deck_data):
        current_deck_name = deck_key
        
        # Show success message
        var success_label = Label.new()
        success_label.text = "Deck saved!"
        success_label.add_theme_color_override("font_color", Color(0, 1, 0))
        add_child(success_label)
        success_label.position = Vector2(deck_name_input.global_position.x, deck_name_input.global_position.y + 30)
        
        # Auto-hide after 2 seconds
        var timer = get_tree().create_timer(2.0)
        timer.timeout.connect(func(): success_label.queue_free())
        
        # If connected to deck_manager, update current deck
        if deck_manager and data_loader:
            # Use the DeckConfigManager to set the current deck
            deck_config_manager.set_deck(deck_key)

# Handle deck selection from dropdown
func _on_deck_dropdown_item_selected(index: int):
    if index < deck_dropdown.item_count - 1:  # Not the "Create New" option
        var deck_key = deck_dropdown.get_item_metadata(index)
        _load_deck(deck_key)
        
        # Also apply the deck to the game if we're editing during gameplay
        if deck_config_manager and deck_manager:
            deck_config_manager.set_deck(deck_key)
    else:
        # Create new deck option
        current_deck_name = ""
        deck_name_input.text = "New Deck"
        current_card_counts.clear()
        _populate_card_grid()
        _update_total_cards()

    

# Handle close button press
func _on_close_button_pressed():
    hide_editor()
