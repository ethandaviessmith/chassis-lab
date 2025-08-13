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

@onready var data_loader = $"../../Utils/DataLoader"

func _ready():
    # Load initial deck
    load_starting_deck()

func load_starting_deck():
    # Clear existing cards
    deck.clear()
    hand.clear()
    discard_pile.clear()
    exhausted_pile.clear()
    
    # Load starting cards from data
    var starting_cards = data_loader.load_starting_deck()
    for card_data in starting_cards:
        deck.append(card_data)
    
    # Shuffle the deck
    shuffle_deck()

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
    while hand.size() < max_hand_size and (deck.size() > 0 or discard_pile.size() > 0):
        draw_card()

func play_card(card: Dictionary, slot: String) -> bool:
    # Check if card is in hand
    if not hand.has(card):
        print("Card not in hand!")
        return false
    
    # Check if player has enough energy
    if turn_manager.current_energy < card.cost:
        print("Not enough energy!")
        return false
    
    # Remove from hand
    hand.erase(card)
    
    # Spend energy
    turn_manager.spend_energy(card.cost)
    
    # Emit signal so the BuildView can update
    emit_signal("card_played", card, slot)
    
    # Add to discard pile
    discard_pile.append(card)
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

# Reference to other managers
@onready var turn_manager = $"../TurnManager"
