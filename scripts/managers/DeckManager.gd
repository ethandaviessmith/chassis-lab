extends Node
class_name DeckManager

signal card_drawn(card)
signal card_played(card, slot)
signal card_scrapped(card)

var deck = []
var hand = []
var discard_pile = []
var exhausted_pile = []

var max_hand_size = 5
var default_draw_count = 5

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

# Debug function to check deck status
func get_deck_status() -> Dictionary:
    return {
        "deck_size": deck.size(),
        "hand_size": hand.size(),
        "discard_size": discard_pile.size(),
        "exhausted_size": exhausted_pile.size(),
        "data_loader_exists": data_loader != null
    }

func load_starting_deck():
    # Clear existing cards
    deck.clear()
    hand.clear()
    discard_pile.clear()
    exhausted_pile.clear()
    
    print("Loading starting deck...")
    
    # Load starting cards from data
    if data_loader:
        print("DataLoader found, loading cards...")
        var starting_cards = data_loader.load_starting_deck()
        print("DataLoader returned ", starting_cards.size(), " cards")
        for card_data in starting_cards:
            deck.append(card_data)
        print("Loaded ", deck.size(), " cards into starting deck")
    else:
        print("DataLoader not available, using fallback deck")
        # Fallback to sample cards
        _create_fallback_deck()
    
    # Shuffle the deck
    shuffle_deck()
    
    # Debug: Print first few cards
    print("First 3 cards in deck:")
    for i in range(min(3, deck.size())):
        var card = deck[i]
        print("  ", i+1, ": ", card.get("name", "Unknown"), " (", card.get("type", "Unknown"), ")")

func _create_fallback_deck():
    # Create some sample cards if DataLoader fails
    var sample_cards = [
        {"id": "scope_visor", "name": "Scope Visor", "type": "Head", "cost": 1, "heat": 0, "durability": 3, "rarity": "Common"},
        {"id": "fusion_core", "name": "Fusion Core", "type": "Core", "cost": 2, "heat": 1, "durability": 5, "rarity": "Common"},
        {"id": "rail_arm", "name": "Rail Arm", "type": "Arm", "cost": 2, "heat": 1, "durability": 3, "rarity": "Common"},
        {"id": "saw_arm", "name": "Saw Arm", "type": "Arm", "cost": 1, "heat": 1, "durability": 4, "rarity": "Common"},
        {"id": "tracked_legs", "name": "Tracked Legs", "type": "Legs", "cost": 1, "heat": 0, "durability": 4, "rarity": "Common"}
    ]
    
    for card in sample_cards:
        deck.append(card)
    
    print("Created fallback deck with ", deck.size(), " cards")

func shuffle_deck():
    # Randomize the deck
    deck.shuffle()
    print("Deck shuffled, contains ", deck.size(), " cards")

func draw_card() -> Dictionary:
    if deck.size() == 0:
        if discard_pile.size() > 0:
            # Shuffle discard pile into deck
            for card in discard_pile:
                deck.append(card)
            discard_pile.clear()
            shuffle_deck()
        else:
            # No cards to draw!
            print("No cards left to draw!")
            return {}
    
    # Draw top card
    var card = deck.pop_front()
    hand.append(card)
    
    emit_signal("card_drawn", card)
    return card

func draw_hand():
    # Draw up to max hand size
    print("Drawing hand - Current state:")
    print("  Hand size: ", hand.size(), "/", max_hand_size)
    print("  Deck size: ", deck.size())
    print("  Discard pile size: ", discard_pile.size())
    
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
