extends Node
class_name DeckManager

signal card_drawn(card)
signal card_played(card, slot)
signal card_scrapped(card)
signal deck_updated

var deck = []
var hand = []
var discard_pile = []
var exhausted_pile = []

var max_hand_size = 5
var default_draw_count = 5

# Default distribution of card types
var default_card_distribution = {
    "Arm": 10,
    "Head": 3, 
    "Legs": 2,
    "Core": 2,
    "Utility": 1
}

# Energy management (moved from other managers for centralization)
var current_energy: int = 0
var max_energy: int = 4  # Default 4 per turn
var current_heat: int = 0
var max_heat: int = 10

# Export references - set these in the editor
@export var data_loader: DataLoader
@export var turn_manager: TurnManager

func _ready():
    print("DeckManager ready")
    print("  DataLoader: ", "Set" if data_loader else "Not set")
    print("  TurnManager: ", "Set" if turn_manager else "Not set")
    
    # Load initial deck
    print("DeckManager: About to load starting deck...")
    load_starting_deck()
    
    # Print final status after loading
    var status = get_deck_status()
    print("DeckManager: Final deck status after loading:")
    print("  Deck size: ", status.deck_size)
    print("  Hand size: ", status.hand_size)
    print("  Discard size: ", status.discard_size)

# Force reload the starting deck (useful for debugging)
func reload_deck():
    print("Force reloading deck...")
    load_starting_deck()
    
# Set custom card distribution and reload deck
func set_card_distribution(arm_count: int = 5, head_count: int = 3, legs_count: int = 2, 
                          core_count: int = 2, utility_count: int = 1) -> void:
    var distribution = {
        "Arm": arm_count,
        "Head": head_count,
        "Legs": legs_count,
        "Core": core_count,
        "Utility": utility_count
    }
    
    print("Setting custom card distribution: ", distribution)
    default_card_distribution = distribution
    load_starting_deck(distribution)

# Debug function to check deck status
func get_deck_status() -> Dictionary:
    return {
        "deck_size": deck.size(),
        "hand_size": hand.size(),
        "discard_size": discard_pile.size(),
        "exhausted_size": exhausted_pile.size(),
        "data_loader_exists": data_loader != null
    }

func configure_starting_deck(type_distribution: Dictionary = {}) -> void:
    print("Configuring starting deck with distribution: ", type_distribution)
    
    # Use default distribution if none provided
    if type_distribution.is_empty():
        type_distribution = default_card_distribution.duplicate()
        print("Using default card distribution: ", type_distribution)
    
    # Clear existing cards
    deck.clear()
    hand.clear()
    discard_pile.clear()
    exhausted_pile.clear()
    
    # Get all available cards from data loader
    var all_available_cards = []
    
    if data_loader:
        all_available_cards = data_loader.load_starting_deck()
        print("DataLoader returned ", all_available_cards.size(), " total available cards")
    else:
        print("DataLoader not available, using fallback card pool")
        all_available_cards = _get_fallback_card_pool()
    
    # Group cards by their type
    var cards_by_type = {}
    
    for card in all_available_cards:
        var card_type = card.get("type", "Unknown")
        
        # Initialize array for this type if needed
        if not cards_by_type.has(card_type):
            cards_by_type[card_type] = []
            
        # Add card to its type group
        cards_by_type[card_type].append(card)
    
    # Debug the card types found
    print("Available card types:")
    for card_type in cards_by_type.keys():
        print("  ", card_type, ": ", cards_by_type[card_type].size(), " cards")
    
    # Build deck according to the requested distribution
    for card_type in type_distribution.keys():
        var count = type_distribution[card_type]
        
        # Skip if no cards of this type or count is 0
        if not cards_by_type.has(card_type) or count <= 0:
            print("  Skipping type ", card_type, " - No cards available or count is 0")
            continue
        
        # Get cards of this type
        var type_cards = cards_by_type[card_type]
        
        # Make sure we have at least one card of this type
        if type_cards.size() == 0:
            continue
            
        # Add the requested number of cards, randomly picking from available cards of this type
        var added = 0
        while added < count:
            # Pick a random card of this type
            var random_index = randi() % type_cards.size()
            var random_card = type_cards[random_index].duplicate()
            
            # Add a unique identifier to distinguish duplicates
            if not random_card.has("instance_id"):
                random_card["instance_id"] = randi()
                
            # Add to deck
            deck.append(random_card)
            added += 1
        
        print("  Added ", added, " cards of type ", card_type)
    
    # Shuffle the final deck
    shuffle_deck()
    
    # Debug: Print first few cards in deck
    print("First few cards in configured deck:")
    for i in range(min(5, deck.size())):
        var card = deck[i]
        print("  ", i+1, ": ", card.get("name", "Unknown"), " (", card.get("type", "Unknown"), ")")

func load_starting_deck(type_distribution: Dictionary = {}):
    print("Loading starting deck...")
    
    # Use the new configure_starting_deck function with the provided distribution
    configure_starting_deck(type_distribution)
    
    # Debug: Print first few cards
    print("First 3 cards in deck:")
    for i in range(min(3, deck.size())):
        var card = deck[i]
        print("  ", i+1, ": ", card.get("name", "Unknown"), " (", card.get("type", "Unknown"), ")")

func _get_fallback_card_pool() -> Array:
    # Create a larger pool of sample cards if DataLoader fails
    var sample_cards = [
        # Heads
        {"id": "scope_visor", "name": "Scope Visor", "type": "Head", "cost": 1, "heat": 0, "durability": 3, "rarity": "Common"},
        {"id": "sensor_array", "name": "Sensor Array", "type": "Head", "cost": 2, "heat": 1, "durability": 4, "rarity": "Common"},
        {"id": "targeting_cpu", "name": "Targeting CPU", "type": "Head", "cost": 3, "heat": 2, "durability": 3, "rarity": "Uncommon"},
        {"id": "armored_helm", "name": "Armored Helm", "type": "Head", "cost": 2, "heat": 0, "durability": 5, "rarity": "Common"},
        
        # Cores
        {"id": "fusion_core", "name": "Fusion Core", "type": "Core", "cost": 2, "heat": 1, "durability": 5, "rarity": "Common"},
        {"id": "cooling_system", "name": "Cooling System", "type": "Core", "cost": 2, "heat": -1, "durability": 4, "rarity": "Uncommon"},
        {"id": "power_generator", "name": "Power Generator", "type": "Core", "cost": 3, "heat": 2, "durability": 6, "rarity": "Uncommon"},
        
        # Arms
        {"id": "rail_arm", "name": "Rail Arm", "type": "Arm", "cost": 2, "heat": 1, "durability": 3, "rarity": "Common"},
        {"id": "saw_arm", "name": "Saw Arm", "type": "Arm", "cost": 1, "heat": 1, "durability": 4, "rarity": "Common"},
        {"id": "cannon_arm", "name": "Cannon Arm", "type": "Arm", "cost": 3, "heat": 2, "durability": 3, "rarity": "Uncommon"},
        {"id": "shield_arm", "name": "Shield Arm", "type": "Arm", "cost": 2, "heat": 0, "durability": 5, "rarity": "Common"},
        {"id": "laser_arm", "name": "Laser Arm", "type": "Arm", "cost": 2, "heat": 2, "durability": 3, "rarity": "Uncommon"},
        {"id": "grapple_arm", "name": "Grapple Arm", "type": "Arm", "cost": 1, "heat": 1, "durability": 4, "rarity": "Common"},
        
        # Legs
        {"id": "tracked_legs", "name": "Tracked Legs", "type": "Legs", "cost": 1, "heat": 0, "durability": 4, "rarity": "Common"},
        {"id": "jump_jets", "name": "Jump Jets", "type": "Legs", "cost": 2, "heat": 1, "durability": 3, "rarity": "Uncommon"},
        {"id": "bipedal_legs", "name": "Bipedal Legs", "type": "Legs", "cost": 2, "heat": 0, "durability": 4, "rarity": "Common"},
        
        # Utility
        {"id": "repair_drone", "name": "Repair Drone", "type": "Utility", "cost": 2, "heat": 0, "durability": 2, "rarity": "Uncommon"},
        {"id": "ammo_cache", "name": "Ammo Cache", "type": "Utility", "cost": 1, "heat": 0, "durability": 3, "rarity": "Common"},
        {"id": "stealth_field", "name": "Stealth Field", "type": "Utility", "cost": 3, "heat": 1, "durability": 2, "rarity": "Rare"}
    ]
    
    return sample_cards

func _create_fallback_deck():
    # Use the default card distribution with our fallback pool
    var fallback_pool = _get_fallback_card_pool()
    
    # Group cards by type
    var cards_by_type = {}
    for card in fallback_pool:
        var card_type = card.get("type", "Unknown")
        if not cards_by_type.has(card_type):
            cards_by_type[card_type] = []
        cards_by_type[card_type].append(card)
    
    # Add cards based on default distribution
    for card_type in default_card_distribution.keys():
        var count = default_card_distribution[card_type]
        if cards_by_type.has(card_type) and cards_by_type[card_type].size() > 0:
            var type_cards = cards_by_type[card_type]
            type_cards.shuffle()
            
            # Add requested number or all available if fewer
            for i in range(min(count, type_cards.size())):
                deck.append(type_cards[i])
    
    print("Created fallback deck with ", deck.size(), " cards")

func shuffle_deck():
    # Randomize the deck
    deck.shuffle()
    print("Deck shuffled, contains ", deck.size(), " cards")
    # Notify listeners that deck state has changed
    emit_signal("deck_updated")

func draw_card() -> Dictionary:
    if deck.size() == 0:
        if discard_pile.size() > 0:
            # Shuffle discard pile into deck
            print("DeckManager: Reshuffling discard pile into draw pile")
            for card in discard_pile:
                deck.append(card)
            discard_pile.clear()
            shuffle_deck()
            emit_signal("deck_updated")
        else:
            # No cards to draw!
            print("No cards left to draw!")
            return {}
    
    # Draw top card
    var card = deck.pop_front()
    hand.append(card)
    
    emit_signal("card_drawn", card)
    emit_signal("deck_updated")
    return card

func draw_hand():
    # Draw up to max hand size
    print("Drawing hand - Current state:")
    print("  Hand size: ", hand.size(), "/", max_hand_size)
    print("  Deck size: ", deck.size())
    print("  Discard pile size: ", discard_pile.size())
    
    # Make sure we have a valid deck to draw from
    if deck.is_empty() and not discard_pile.is_empty() and hand.is_empty():
        # If deck is empty but we have cards in discard and no hand, shuffle discard into deck
        print("Initial draw - shuffling discard pile into deck")
        for card in discard_pile:
            deck.append(card)
        discard_pile.clear()
        shuffle_deck()
    
    # Draw cards up to max hand size
    while hand.size() < max_hand_size and (deck.size() > 0 or discard_pile.size() > 0):
        var drawn_card = draw_card()
        if drawn_card.is_empty():
            print("Failed to draw card, breaking loop")
            break
    
    print("Final hand size after drawing: ", hand.size())
    return hand

func play_card(card: Dictionary, slot: String) -> bool:
    # Check if card is in hand
    if not hand.has(card):
        print("Card not in hand!")
        return false
    
    # Check if player has enough energy
    var card_cost = card.get("cost", 0)
    if turn_manager and turn_manager.current_energy < card_cost:
        print("Not enough energy! Need: ", card_cost, ", Have: ", turn_manager.current_energy)
        return false
    
    # Remove from hand
    hand.erase(card)
    
    # Spend energy
    if turn_manager and not turn_manager.spend_energy(card_cost):
        # This shouldn't happen since we checked above, but just in case
        hand.append(card)  # Put card back
        return false
    
    # Emit signal so the BuildView can update
    emit_signal("card_played", card, slot)
    
    # Add to discard pile
    discard_pile.append(card)
    print("Played card: ", card.name, " for ", card_cost, " energy")
    return true

func scrap_card(card: Dictionary) -> bool:
    # Check if card is in hand
    if not hand.has(card):
        print("Card not in hand!")
        return false
    
    # Remove from hand
    hand.erase(card)
    
    # Emit signal for scrapper
    emit_signal("card_scrapped", card)
    
    # Add to discard pile
    discard_pile.append(card)
    return true

func exhaust_card(card: Dictionary):
    # Remove from wherever it is
    if hand.has(card):
        hand.erase(card)
    elif discard_pile.has(card):
        discard_pile.erase(card)
    elif deck.has(card):
        deck.erase(card)
        
    # Add to exhausted pile
    exhausted_pile.append(card)

func generate_rewards(count: int) -> Array:
    # Generate count reward options
    var rewards = []
    var all_rewards = data_loader.load_reward_options()
    
    # Choose random rewards
    all_rewards.shuffle()
    for i in range(min(count, all_rewards.size())):
        rewards.append(all_rewards[i])
    
    return rewards

func add_card_to_deck(card: Dictionary):
    # Add a new card to discard pile
    discard_pile.append(card)
    # Notify listeners that deck state has changed
    emit_signal("deck_updated")

func discard_card(card):
    # Handle discarding both Dictionary data and Card objects
    if card is Dictionary:
        # Add to discard pile directly
        discard_pile.append(card)
        print("DeckManager: Card data added to discard pile")
    elif card is Card and card.data:
        # Extract card data from Card object and add to discard pile
        discard_pile.append(card.data)
        print("DeckManager: Card object's data added to discard pile")
    else:
        print("DeckManager: Unable to discard - invalid card type:", typeof(card))
    
    # Notify listeners that deck state has changed
    emit_signal("deck_updated")
