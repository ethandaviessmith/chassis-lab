extends Node
class_name DeckConfigManager

# File path for saved decks
const DECKS_CONFIG_PATH = "user://decks.cfg"

# Signal for when decks are loaded or saved
signal decks_updated()

@export var deck_manager: DeckManager

# Dictionary of saved decks
var saved_decks = {}

func _ready():
    load_decks()

# Load all saved decks from config file
func load_decks():
    var file = FileAccess.open(DECKS_CONFIG_PATH, FileAccess.READ)
    if file:
        var json_string = file.get_as_text()
        var parse_result = JSON.parse_string(json_string)
        if parse_result:
            saved_decks = parse_result
        else:
            push_error("DeckConfigManager: Failed to parse decks config file")
            saved_decks = {}
        file.close()
    else:
        # Create a default deck configuration if none exists
        saved_decks = {
            "default": {
                "name": "Default Deck",
                "description": "The default robot building deck",
                "cards": []
                # Cards will be filled with default deck when first saved
            }
        }
    
    # Emit signal that decks have been loaded
    emit_signal("decks_updated")
    
    return saved_decks

# Save all decks to config file
func save_decks():
    var file = FileAccess.open(DECKS_CONFIG_PATH, FileAccess.WRITE)
    if file:
        var json_string = JSON.stringify(saved_decks, "  ")
        file.store_string(json_string)
        file.close()
        emit_signal("decks_updated")
        return true
    else:
        push_error("DeckConfigManager: Failed to save decks config file")
        return false

# Save a specific deck
func save_deck(deck_name: String, deck_data: Dictionary):
    # Ensure deck_data has all required fields
    if not deck_data.has("name"):
        deck_data["name"] = deck_name
    if not deck_data.has("description"):
        deck_data["description"] = ""
    if not deck_data.has("cards"):
        deck_data["cards"] = []
    
    # Update or create the deck
    saved_decks[deck_name] = deck_data
    
    # Save to file
    return save_decks()

# Load a specific deck
func load_deck(deck_name: String) -> Dictionary:
    if saved_decks.has(deck_name):
        return saved_decks[deck_name]
    else:
        push_warning("DeckConfigManager: Deck not found: " + deck_name)
        if saved_decks.has("default"):
            return saved_decks["default"]
        return {"name": "Empty Deck", "description": "", "cards": []}

func set_deck(deck_name: String):
    if deck_manager:
        var deck_data = load_deck(deck_name)
        var card_list = convert_saveable_to_deck(deck_data.cards, deck_manager.data_loader)
        deck_manager.set_current_deck(card_list)
        deck_manager.current_deck_name = deck_name
    else:
        push_error("DeckConfigManager: No DeckManager assigned")

# Get a list of all saved deck names
func get_deck_names() -> Array:
    return saved_decks.keys()

# Get a full deck by name including card counts
func get_full_deck_data(deck_name: String) -> Dictionary:
    return load_deck(deck_name)

# Convert current deck to saveable format
func convert_deck_to_saveable(deck: Array) -> Array:
    var card_counts = {}
    
    # Count cards in the deck
    for card in deck:
        var card_id = card.id
        if card_counts.has(card_id):
            card_counts[card_id] += 1
        else:
            card_counts[card_id] = 1
    
    # Convert to array of card entries with counts
    var result = []
    for card_id in card_counts.keys():
        result.append({
            "id": card_id,
            "count": card_counts[card_id]
        })
    
    return result

# Convert saved deck format to array of card data
func convert_saveable_to_deck(deck_data: Array, data_loader: DataLoader) -> Array:
    var result = []
    
    for card_entry in deck_data:
        var card_id = card_entry.id
        var count = card_entry.count
        
        # Get full card data from DataLoader
        var card_data = data_loader.get_card_by_id(card_id)
        if card_data:
            # Add the card multiple times based on count
            for i in range(count):
                result.append(card_data)
        else:
            push_warning("DeckConfigManager: Card not found: " + card_id)
    
    return result
