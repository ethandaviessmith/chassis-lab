extends Container
class_name HandContainer

# Spacing between cards
@export var card_spacing: float = 120
# Vertical offset when card is hovered/selected
@export var hover_offset: float = -20
# Animation speed for card movement (higher = faster)
@export var animation_speed: float = 10.0

# Reference to cards in the hand
var cards = []

# Called when the node enters the scene tree for the first time
func _ready():
    # Make sure we handle resizing
    resized.connect(_on_resized)
    sort_children.connect(_on_sort_children)

# Called when a child is added to the container
func _on_child_entered_tree(node):
    if node is Card or node is ColorRect:  # Support both Card scenes and fallback ColorRects
        if not cards.has(node):
            cards.append(node)
        # Reposition all cards when a new one is added
        _reposition_cards()

# Called when a child is removed from the container
func _on_child_exiting_tree(node):
    if cards.has(node):
        cards.erase(node)
        # Reposition remaining cards
        _reposition_cards()

# Handle container resize events
func _on_resized():
    _reposition_cards()

# Handle sort children event
func _on_sort_children():
    _reposition_cards()
    
# Process animation each frame
func _process(delta):
    # Update card animations
    for i in range(cards.size()):
        # Skip if we're out of bounds
        if i >= cards.size():
            continue
            
        var card = cards[i]
        
        # Skip invalid cards
        if not is_instance_valid(card):
            continue
            
        if card is Card and not card.is_being_dragged:
            # Skip if card is already at its target position
            if card.target_position == Vector2.ZERO:
                continue
                
            # We don't need to animate here as Card has its own animation logic
            # in _process that uses target_position
            pass

# Calculate position for a card at specific index
func get_card_position(index: int, total_cards: int) -> Vector2:
    # For a single card, just center it
    if total_cards == 1:
        return Vector2(size.x / 2.0, size.y / 2.0)
    
    # Calculate the total width needed for all cards
    var total_width = (total_cards - 1) * card_spacing
    
    # Starting x position to center the hand
    var start_x = (size.x - total_width) / 2.0
    
    # Fan cards out horizontally with a slight vertical curve
    var x_pos = start_x + (index * card_spacing)
    
    # Add a slight vertical arc for visual appeal
    # Cards in the middle are slightly higher than those at the edges
    var center_offset = abs(index - (total_cards - 1) / 2.0)
    var max_offset = (total_cards - 1) / 2.0
    var y_curve = 30.0 * (1.0 - (center_offset / max_offset))
    
    var y_pos = size.y / 2.0 - y_curve
    
    return Vector2(x_pos, y_pos)

# Calculate target position for the card at index
func get_target_position(card, index: int) -> Vector2:
    var base_pos = get_card_position(index, cards.size())
    
    # If card is being hovered or dragged, apply offset
    if card.has_meta("hover") and card.get_meta("hover"):
        base_pos.y += hover_offset
    
    return base_pos

# Position all cards in the hand
func _reposition_cards():
    if cards.is_empty():
        return
    
    # Debug output
    print("Repositioning " + str(cards.size()) + " cards in hand")
    
    # First clean up any null references
    var valid_cards = []
    for card in cards:
        if is_instance_valid(card):
            valid_cards.append(card)
    
    # Update our cards array if we removed any invalid references
    if valid_cards.size() != cards.size():
        cards = valid_cards
        
    # If all cards were invalid, exit
    if cards.is_empty():
        return
        
    # Reposition all cards
    for i in range(cards.size()):
        var card = cards[i]
        
        # Skip invalid cards
        if not is_instance_valid(card):
            continue
            
        # Get local position in container
        var local_pos = get_target_position(card, i)
        
        # Convert to global position - Container doesn't have to_global so we need to use the position
        var global_pos = local_pos + global_position
        
        # Debug output
        print("Card " + str(i) + " local position: " + str(local_pos))
        print("Card " + str(i) + " global position: " + str(global_pos))
        
        # If using our Card scene with custom properties
        if card is Card:
            # If card is being dragged, don't reposition
            if card.is_being_dragged:
                print("Card " + str(i) + " is being dragged, skipping")
                continue
                
            # Set the target position for smooth animation (using global position)
            card.target_position = global_pos
            
            # For immediate positioning (helps with initialization)
            if card.global_position == Vector2.ZERO:
                card.global_position = global_pos
                
            # Store original position (global)
            card.original_position = global_pos
            
            # Ensure card is visible and can receive input
            card.modulate.a = 1.0
            card.mouse_filter = Control.MOUSE_FILTER_STOP
            
            print("Card " + str(i) + " target set to: " + str(card.target_position))
        else:
            # For fallback ColorRect cards, set position directly
            # Skip if card is being dragged
            if card.has_meta("dragging") and card.get_meta("dragging"):
                continue
                
            card.global_position = global_pos
            
            # Store original position
            card.set_meta("original_position", global_pos)
                
# Cards can call this to get their position in the hand
func get_original_position(card) -> Vector2:
    var index = cards.find(card)
    if index >= 0:
        # Convert local position to global position by adding container's global position
        var local_pos = get_card_position(index, cards.size())
        var global_pos = local_pos + global_position
        print("Card " + str(index) + " global position: " + str(global_pos))
        return global_pos
    
    print("WARNING: Card not found in hand container")
    return Vector2.ZERO
