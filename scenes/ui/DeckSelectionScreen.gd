@tool
extends Control
class_name DeckSelectionScreen

signal deck_selected(deck_name: String)

@export var deck_config_manager: DeckConfigManager
@export var close_on_selection: bool = true

@onready var deck_list: ItemList = $CenterContainer/Panel/VBoxContainer/DeckList
@onready var select_button: Button = $CenterContainer/Panel/VBoxContainer/SelectButton

var selected_deck: String = ""

func _ready():
    # Connect button signals
    if select_button:
        select_button.pressed.connect(_on_select_button_pressed)
    
    if deck_list:
        deck_list.item_selected.connect(_on_deck_list_item_selected)
        deck_list.item_activated.connect(_on_deck_list_item_activated)
    
    # Load deck names
    if deck_config_manager:
        deck_config_manager.decks_updated.connect(_refresh_deck_list)
        _refresh_deck_list()
    
    # Initially disable select button
    if select_button:
        select_button.disabled = true

# Refresh the list of available decks
func _refresh_deck_list():
    if deck_list and deck_config_manager:
        deck_list.clear()
        
        var deck_names = deck_config_manager.get_deck_names()
        for i in range(deck_names.size()):
            var deck_name = deck_names[i]
            var deck_data = deck_config_manager.get_full_deck_data(deck_name)
            
            # Add the deck to the list
            deck_list.add_item(deck_data.name)
            deck_list.set_item_metadata(i, deck_name)

# Handle deck selection
func _on_deck_list_item_selected(index: int):
    selected_deck = deck_list.get_item_metadata(index)
    if select_button:
        select_button.disabled = false

# Handle double click on deck
func _on_deck_list_item_activated(index: int):
    selected_deck = deck_list.get_item_metadata(index)
    _select_deck()

# Handle select button press
func _on_select_button_pressed():
    _select_deck()

# Select the current deck and emit signal
func _select_deck():
    if selected_deck != "":
        emit_signal("deck_selected", selected_deck)
        
        if close_on_selection:
            hide()

# Show the selection screen
func show_selection():
    show()

# Hide the selection screen
func hide_selection():
    hide()
