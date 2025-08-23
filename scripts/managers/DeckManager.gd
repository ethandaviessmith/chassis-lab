extends Node
class_name DeckManager

signal card_drawn(card)
signal card_played(card, slot)
signal card_scrapped(card)
signal deck_updated
signal card_durability_changed(instance_id, new_durability)
signal card_destroyed(instance_id)

var deck = []
var hand = []
var discard_pile = []
var exhausted_pile = []

# Card registry for tracking durability and other persistent properties
var card_registry = {}
var card_instances = {}
# Register a card in the registry for durability tracking

var max_hand_size = 5
var default_draw_count = 5

# Card lifecycle signals - centralized here for better management
signal card_drawn_to_hand(card_data)  # Card data drawn from deck
signal card_added_to_hand(card_data)  # Card instance added to visual hand
signal hand_emptied                   # Hand has been emptied (discarded/played)
signal deck_emptied                   # Deck has no more cards
signal deck_shuffled                  # Deck has been shuffled

# Default distribution of card types
var default_card_distribution = {
    "Arm": 10,
    "Head": 3, 
    "Legs": 2,
    "Core": 2,
    "Utility": 1
}

# Heat management
var current_heat: int = 0
var max_heat: int = 10

# Export references - set these in the editor
@export var data_loader: DataLoader
@export var turn_manager: TurnManager
@export var combat_resolver: CombatResolver

func _ready():
    # Setup signals first
    if combat_resolver:
        combat_resolver.part_durability_changed.connect(_on_part_durability_changed)
    if turn_manager:
        turn_manager.part_durability_changed.connect(_on_part_durability_changed)
        
    print("DeckManager ready")
    print("  DataLoader: ", "Set" if data_loader else "Not set")
    print("  TurnManager: ", "Set" if turn_manager else "Not set")
    
    # We'll only load the deck here but NOT draw cards automatically
    # The initial hand drawing will be done by HandManager when requested
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
    
    # We need to clear all collections before reloading to avoid duplicates
    deck.clear()
    hand.clear()
    discard_pile.clear()
    exhausted_pile.clear()
    
    # Also clear card tracking systems
    card_registry.clear()
    card_instances.clear()
    
    # Now load fresh deck
    load_starting_deck()

func _on_part_durability_changed(part, new_durability):
    print("Part durability changed: ", part, " - New durability: ", new_durability)
    
    # Check if this part has an instance_id
    var instance_id = ""
    
    if part is Part:
        # Handle Part objects directly
        instance_id = part.instance_id
    elif part is Dictionary and part.has("instance_id"):
        # Handle dictionary data
        instance_id = part["instance_id"]
    elif part is Card and part.data:
        # Handle Card objects with data
        if part.data is Part:
            instance_id = part.data.instance_id
        elif part.data.has("instance_id"):
            instance_id = part.data["instance_id"]
    
    if instance_id != "":
        # Update the card's durability in our registry
        update_card_durability(instance_id, new_durability)
    else:
        print("Cannot track durability - no instance_id found for part:", part)


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
        var card_type = ""
        
        if card is Part:
            # Handle Part objects
            card_type = card.type.capitalize()  # Convert "head" to "Head", etc.
        else:
            # Handle dictionary data
            card_type = card.get("type", "Unknown")
        
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
            var random_card
            
            # Properly duplicate the card based on its type
            if type_cards[random_index] is Part:
                # Create a new Part instance and copy all properties
                random_card = Part.new()
                random_card.duplicate_from(type_cards[random_index])
                
                # Add a unique identifier
                if random_card.instance_id.is_empty():
                    random_card.instance_id = str(randi())
            else:
                # For dictionaries, normal duplicate is fine
                random_card = type_cards[random_index].duplicate()
                
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
        
        # Detailed debug output to figure out what's happening
        print("  Card", i+1, "type:", typeof(card), "class:", card.get_class() if card is Object else "N/A")
        
        if card is Part:
            print("  Part properties - ID:", card.id, "Name:", card.part_name, "Type:", card.type, "Instance ID:", card.instance_id)
            var card_name = card.part_name
            var card_type = card.type
            print("  ", i+1, ": ", card_name, " (", card_type, ")")
        else:
            print("  Dictionary keys:", card.keys() if card is Dictionary else "Not a dictionary")
            var card_name = card.get("name", "Unknown")
            var card_type = card.get("type", "Unknown")
            print("  ", i+1, ": ", card_name, " (", card_type, ")")

func load_starting_deck(type_distribution: Dictionary = {}):
    print("Loading starting deck...")
    
    # Use the new configure_starting_deck function with the provided distribution
    configure_starting_deck(type_distribution)
    
    # Debug: Print first few cards
    print("First 3 cards in deck:")
    for i in range(min(3, deck.size())):
        var card = deck[i]
        var card_name = card.part_name if card is Part else card.get("name", "Unknown")
        var card_type = card.type if card is Part else card.get("type", "Unknown") 
        print("  ", i+1, ": ", card_name, " (", card_type, ")")

func _get_fallback_card_pool() -> Array:
    # Create a larger pool of sample cards if DataLoader fails
    var sample_cards = []
    
    # Convert the dictionary data into Part objects
    # Heads
    _add_fallback_part(sample_cards, "scope_visor", "Scope Visor", "head", 1, 0, 3, "Common")
    _add_fallback_part(sample_cards, "sensor_array", "Sensor Array", "head", 2, 1, 4, "Common")
    _add_fallback_part(sample_cards, "targeting_cpu", "Targeting CPU", "head", 3, 2, 3, "Uncommon")
    _add_fallback_part(sample_cards, "armored_helm", "Armored Helm", "head", 2, 0, 5, "Common")
    
    # Cores
    _add_fallback_part(sample_cards, "fusion_core", "Fusion Core", "core", 2, 1, 5, "Common")
    _add_fallback_part(sample_cards, "cooling_system", "Cooling System", "core", 2, -1, 4, "Uncommon")
    _add_fallback_part(sample_cards, "power_generator", "Power Generator", "core", 3, 2, 6, "Uncommon")
    
    # Arms
    _add_fallback_part(sample_cards, "rail_arm", "Rail Arm", "arm", 2, 1, 3, "Common")
    _add_fallback_part(sample_cards, "saw_arm", "Saw Arm", "arm", 1, 1, 4, "Common")
    _add_fallback_part(sample_cards, "cannon_arm", "Cannon Arm", "arm", 3, 2, 3, "Uncommon")
    _add_fallback_part(sample_cards, "shield_arm", "Shield Arm", "arm", 2, 0, 5, "Common")
    _add_fallback_part(sample_cards, "laser_arm", "Laser Arm", "arm", 2, 2, 3, "Uncommon")
    _add_fallback_part(sample_cards, "grapple_arm", "Grapple Arm", "arm", 1, 1, 4, "Common")
    
    # Legs
    _add_fallback_part(sample_cards, "tracked_legs", "Tracked Legs", "legs", 1, 0, 4, "Common")
    _add_fallback_part(sample_cards, "jump_jets", "Jump Jets", "legs", 2, 1, 3, "Uncommon")
    _add_fallback_part(sample_cards, "bipedal_legs", "Bipedal Legs", "legs", 2, 0, 4, "Common")
    
    # Utility
    _add_fallback_part(sample_cards, "repair_drone", "Repair Drone", "utility", 2, 0, 2, "Uncommon")
    _add_fallback_part(sample_cards, "ammo_cache", "Ammo Cache", "utility", 1, 0, 3, "Common")
    _add_fallback_part(sample_cards, "stealth_field", "Stealth Field", "utility", 3, 1, 2, "Rare")
    
    return sample_cards

# Helper function to create a Part and add it to the fallback card pool
func _add_fallback_part(array, part_id, part_name, part_type, cost, heat, durability, rarity):
    var part = Part.new()
    part.id = part_id
    part.part_name = part_name
    part.type = part_type
    part.cost = cost
    part.heat = heat
    part.durability = durability
    part.max_durability = durability
    part.rarity = rarity
    array.append(part)

func _create_fallback_deck():
    # Use the default card distribution with our fallback pool
    var fallback_pool = _get_fallback_card_pool()
    
    # Group cards by type
    var cards_by_type = {}
    for part in fallback_pool:
        var part_type = part.type
        if not cards_by_type.has(part_type):
            cards_by_type[part_type] = []
        cards_by_type[part_type].append(part)
    
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
    emit_signal("deck_shuffled")

func draw_card() -> Part:
    print("DeckManager: Drawing card - deck size:", deck.size(), ", hand size:", hand.size())
    
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
            print("DeckManager: No cards left to draw!")
            return null

    # Draw top card
    var card = deck.pop_front()
    
    # Make sure this card has a unique instance_id
    if card is Part:
        if card.instance_id.is_empty():
            card.instance_id = "card_" + str(randi()) + "_" + str(Time.get_unix_time_from_system())
            print("DeckManager: Added instance_id to Part:", card.instance_id)
    elif not card.has("instance_id") or card["instance_id"] == null or card["instance_id"] == "":
        card["instance_id"] = "card_" + str(randi()) + "_" + str(Time.get_unix_time_from_system())
        print("DeckManager: Added instance_id to card:", card["instance_id"])
    
    # Add to hand array
    hand.append(card)
    
    var card_name = card.part_name if card is Part else card.get("name", "Unknown")
    print("DeckManager: Drew card:", card_name, "- new deck size:", deck.size(), ", new hand size:", hand.size())
    
    emit_signal("card_drawn", card)
    emit_signal("card_drawn_to_hand", card)
    emit_signal("deck_updated")

    Sound.play_card_pickup()
    return card

func draw_hand():
    # Draw up to max hand size
    print("DeckManager: Drawing hand - Current state:")
    print("  Hand size: ", hand.size(), "/", max_hand_size)
    print("  Deck size: ", deck.size())
    print("  Discard pile size: ", discard_pile.size())
    
    # Make sure we have a valid deck to draw from
    if deck.is_empty() and not discard_pile.is_empty() and hand.is_empty():
        # If deck is empty but we have cards in discard and no hand, shuffle discard into deck
        print("DeckManager: Initial draw - shuffling discard pile into deck")
        for card in discard_pile:
            deck.append(card)
        discard_pile.clear()
        shuffle_deck()
    
    # Draw cards up to max hand size
    var cards_drawn = 0
    while hand.size() < max_hand_size and (deck.size() > 0 or discard_pile.size() > 0):
        var drawn_card = draw_card()
        if drawn_card.is_empty():
            print("DeckManager: Failed to draw card, breaking loop")
            break
        cards_drawn += 1
    
    print("DeckManager: Drew " + str(cards_drawn) + " cards. Final hand size: " + str(hand.size()))
    
    # Validate that our counts make sense
    var total_cards = deck.size() + hand.size() + discard_pile.size() + exhausted_pile.size()
    print("DeckManager: Total cards in all collections: " + str(total_cards))
    
    return hand

func play_card(card: Dictionary, slot: String) -> bool:
    # Check if card is in hand
    if not hand.has(card):
        print("Card not in hand!")
        return false
    
    # Check if player has enough energy
    var card_cost = 0
    if card is Dictionary:
        card_cost = card.get("cost", 0)  # Dictionary-based cards only here
    else:
        # Try to access cost property directly
        card_cost = card.cost if "cost" in card else 0
        
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
    
    var card_name = ""
    if card is Dictionary:
        card_name = card.get("name", "Unknown")
    else:
        # Try to access part_name property directly
        card_name = card.part_name if "part_name" in card else "Unknown"
    print("Played card: ", card_name, " for ", card_cost, " energy")
    
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
    
# Discard all cards currently in hand to the discard pile
func discard_all_from_hand():
    print("DeckManager: Discarding all cards from hand to discard pile")
    
    # Safety check
    if hand.size() == 0:
        print("DeckManager: Hand is already empty")
        return
        
    # Copy the hand array since we'll be modifying it during iteration
    var cards_to_discard = hand.duplicate()
    
    # Track how many cards we actually discard
    var discard_count = 0
    
    # Discard each card
    for card_data in cards_to_discard:
        discard_pile.append(card_data)
        
        # Update card registry if we have an instance ID
        var instance_id = ""
        if card_data is Part:
            instance_id = card_data.instance_id
        else:
            instance_id = card_data.get("instance_id", "")
            
        if instance_id != "" and card_registry.has(instance_id):
            card_registry[instance_id].location = "discard"
            
        discard_count += 1
            
    # Clear the hand array
    hand.clear()
    
    print("DeckManager: Discarded %d cards from hand" % discard_count)
    emit_signal("deck_updated")
    emit_signal("hand_emptied")

func discard_card(card):
    # First, get the card data regardless of what type it is
    var card_data = null
    
    # Handle discarding both Dictionary data and Card objects
    if card is Dictionary:
        card_data = card
        # Remove from hand if present
        if hand.has(card):
            hand.erase(card)
            print("DeckManager: Removed card data from hand")
        
    elif card is Card and card.part:
        var card_part = card.part
        # Remove from hand if present
        for i in range(hand.size() - 1, -1, -1):
            if hand[i] is Part and card_part is Part:
                # Compare instance_id if available
                if hand[i].instance_id == card_part.instance_id:
                    hand.remove_at(i)
                    print("DeckManager: Removed card object's part from hand by instance_id")
                    break
                # Fall back to id/name comparison
                elif hand[i].id == card_part.id or hand[i].part_name == card_part.part_name:
                    hand.remove_at(i)
                    print("DeckManager: Removed card object's part from hand by id/name")
                    break
            # Handle legacy dictionary case
            elif hand[i] is Dictionary and card.data is Dictionary:
                # Compare instance_id if available
                if hand[i].has("instance_id") and card.data.has("instance_id") and hand[i].instance_id == card.data.instance_id:
                    hand.remove_at(i)
                    print("DeckManager: Removed card object's data from hand by instance_id")
                    break
                # Fall back to name/id comparison if no instance_id
                elif (hand[i].has("id") and card.data.has("id") and hand[i].id == card.data.id) or \
                     (hand[i].has("name") and card.data.has("name") and hand[i].name == card.data.name):
                    hand.remove_at(i)
                    print("DeckManager: Removed card object's data from hand by name/id")
                    break
    else:
        print("DeckManager: Unable to discard - invalid card type:", typeof(card))
        return
    
    # SIMPLIFIED: Always add to discard pile if we have valid card data
    # No filtering based on instance_id since that was inadvertently removing cards
    if card_data:
        discard_pile.append(card_data)
        print("DeckManager: Card added to discard pile")
    
    # Notify listeners that deck state has changed
    emit_signal("deck_updated")
    
    # Check if hand is now empty
    if hand.size() == 0:
        emit_signal("hand_emptied")

# Register a card in the registry for durability tracking
func register_card(instance_id, card_data, card_instance = null):
    if instance_id == null or instance_id == "":
        print("ERROR: Cannot register card with null or empty instance_id")
        return false
    
    # Store the card data in the registry
    if card_data is Part:
        # For Part objects, create a new instance
        var new_part = Part.new()
        new_part.duplicate_from(card_data)
        card_registry[instance_id] = new_part
    else:
        # For dictionary data, duplicate it
        card_registry[instance_id] = card_data.duplicate()
    
    # If a card instance is provided, store it too
    if card_instance:
        card_instances[instance_id] = card_instance
        
    print("DeckManager: Registered card with instance_id: ", instance_id)
    return true
    
# Update a card's durability in the registry and all locations
func update_card_durability(instance_id, new_durability):
    if instance_id == null or instance_id == "":
        print("ERROR: Cannot update card with null or empty instance_id")
        return false
        
    if not card_registry.has(instance_id):
        print("ERROR: Cannot update durability - card not found in registry: ", instance_id)
        return false
    
    # Update the durability in the registry
    var old_dir = 0
    if card_registry[instance_id] is Part:
        old_dir = card_registry[instance_id].durability
        card_registry[instance_id].durability = new_durability
    else:
        old_dir = card_registry[instance_id]["durability"]
        card_registry[instance_id]["durability"] = new_durability
        
    print("DeckManager: Updated card durability in registry: ", instance_id, old_dir, " -> ", new_durability)
    
    # Update the card instance if it exists
    if card_instances.has(instance_id) and is_instance_valid(card_instances[instance_id]):
        if card_instances[instance_id].data is Part:
            card_instances[instance_id].data.durability = new_durability
        else:
            card_instances[instance_id].data["durability"] = new_durability
        
        # Update the UI if this card has a durability label
        var card_instance = card_instances[instance_id]
        if card_instance and card_instance.has_node("%DurabilityLabel"):
            card_instance.get_node("%DurabilityLabel").text = str(int(new_durability))
            print("DeckManager: Updated card instance UI durability")
    
    # Update the durability in all collections (deck, hand, discard)
    _update_card_in_collection(deck, instance_id, new_durability)
    _update_card_in_collection(hand, instance_id, new_durability)
    _update_card_in_collection(discard_pile, instance_id, new_durability)
    _update_card_in_collection(exhausted_pile, instance_id, new_durability)
    
    # Emit signal for other systems to react to durability change
    emit_signal("card_durability_changed", instance_id, new_durability)
    
    return true
    
# Helper function to update a card's durability in a specific collection
func _update_card_in_collection(collection, instance_id, new_durability):
    for i in range(collection.size()):
        var card = collection[i]
        if card is Part and card.instance_id == instance_id:
            collection[i].durability = new_durability
            print("DeckManager: Updated Part durability in collection: ", instance_id, " -> ", new_durability)
            return true
        elif card is Dictionary and card.has("instance_id") and card["instance_id"] == instance_id:
            collection[i]["durability"] = new_durability
            print("DeckManager: Updated card durability in collection: ", instance_id, " -> ", new_durability)
            return true
    return false
    
# Get a card from the registry by instance_id
func get_card_by_instance_id(instance_id):
    if card_registry.has(instance_id):
        return card_registry[instance_id]
    return null
    
# Get the current durability of a card by instance_id
func get_card_durability(instance_id):
    if card_registry.has(instance_id):
        if card_registry[instance_id] is Part:
            return card_registry[instance_id].durability
        else:
            return card_registry[instance_id].get("durability", 0)
    return 0
