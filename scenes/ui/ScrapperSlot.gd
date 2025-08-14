extends ChassisSlot
class_name ScrapperSlot

# Maximum cards the scrapper can hold
const MAX_SCRAPPER_CARDS = 5

# Array to hold multiple cards
var scrapper_cards: Array[Card] = []

# Visual offset for stacking cards
var stack_offset = Vector2(5, 5)

func _ready():
    super._ready()
    # Override slot type to be more generic
    slot_type = "Scrapper"

# Override set_part to handle multiple cards
func set_part(part):
    if not part is Card:
        super.set_part(part)
        return
    
    var card = part as Card
    
    # Check if we can add more cards
    if scrapper_cards.size() >= MAX_SCRAPPER_CARDS:
        print("Scrapper slot is full! Cannot add more than ", MAX_SCRAPPER_CARDS, " cards")
        return false
    
    # Add the card to our array
    scrapper_cards.append(card)
    
    # Position cards in a stacked layout
    _reposition_stacked_cards()
    
    # Update visual state
    has_part = true
    current_part = scrapper_cards  # Store the array as current_part
    background.color = normal_color.darkened(0.2)
    
    print("ScrapperSlot: Added card to scrapper. Now has ", scrapper_cards.size(), " cards")
    return true

# Override clear_part to handle multiple cards
func clear_part():
    scrapper_cards.clear()
    has_part = false
    current_part = null
    background.color = normal_color
    print("ScrapperSlot: Cleared all cards from scrapper")

# Remove a specific card from the scrapper
func remove_card(card: Card) -> bool:
    var index = scrapper_cards.find(card)
    if index >= 0:
        scrapper_cards.remove_at(index)
        print("ScrapperSlot: Removed card from scrapper. Now has ", scrapper_cards.size(), " cards")
        
        # Update visual state
        if scrapper_cards.is_empty():
            has_part = false
            current_part = null
            background.color = normal_color
        else:
            current_part = scrapper_cards
            _reposition_stacked_cards()
        
        return true
    return false

# Get all cards in the scrapper
func get_all_cards() -> Array[Card]:
    return scrapper_cards.duplicate()

# Get the number of cards in the scrapper
func get_card_count() -> int:
    return scrapper_cards.size()

# Check if the scrapper is full
func is_full() -> bool:
    return scrapper_cards.size() >= MAX_SCRAPPER_CARDS

# Reposition cards in a stacked layout
func _reposition_stacked_cards():
    for i in range(scrapper_cards.size()):
        var card = scrapper_cards[i]
        if not is_instance_valid(card):
            continue
            
        # Make sure the card is a child of this slot
        if card.get_parent() != self:
            if card.get_parent():
                card.get_parent().remove_child(card)
            add_child(card)
        
        # Set card state for chassis slot
        if card.has_method("set_card_state"):
            card.set_card_state(Card.State.CHASSIS_SLOT)
        
        # Position with stacking offset
        var base_pos = Vector2(10, 10)  # Base position within slot
        
        # Account for card visual size (scaled to 0.5 in chassis)
        var card_visual_size = card.size * 0.5
        
        # Calculate stack position
        var stack_pos = base_pos + (stack_offset * i)
        
        # Center vertically within the slot
        var slot_center_y = size.y / 2
        var vertical_offset = slot_center_y - (card_visual_size.y / 2)
        stack_pos.y = vertical_offset
        
        # Apply the calculated position
        card.position = stack_pos
        
        # Set z-index so newer cards appear on top
        card.z_index = i
        
        # Mark as attached to chassis
        card.set_meta("attached_to_chassis", "scrapper")
        
        print("ScrapperSlot: Positioned card ", i + 1, " at ", stack_pos)

# Check if a card can be added to this scrapper
func can_accept_card(_card: Card) -> bool:
    return not is_full()

# Get total heat from all scrapper cards
func get_total_heat() -> int:
    var total_heat = 0
    for card in scrapper_cards:
        if is_instance_valid(card) and "heat" in card.data:
            total_heat += int(card.data.heat)
    return total_heat

# Override highlight to show stack capacity
func highlight(is_compatible: bool = true):
    super.highlight(is_compatible)
    
    # Update label to show capacity
    if label:
        label.text = slot_type + " (" + str(scrapper_cards.size()) + "/" + str(MAX_SCRAPPER_CARDS) + ")"
