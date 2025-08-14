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
    
    # Connect sort_children signal
    if not sort_children.is_connected(_on_sort_children):
        sort_children.connect(_on_sort_children)
        
    # Connect child signals
    child_entered_tree.connect(_on_child_entered_tree)
    child_exiting_tree.connect(_on_child_exiting_tree)
    
    # Register self as a drop target for cards returning to hand
    register_as_drop_target()

# Register the hand container as a drop target for all card types
func register_as_drop_target():
    # Find Area2D child if it exists
    var hand_area = find_hand_area()
    
    # Scan for all existing cards and register with their DragDrop components
    for card in cards:
        if card is Card and card.drag_drop != null:
            # Register both the container and its Area2D as drop targets
            card.drag_drop.register_drop_target(self, [])
            if hand_area:
                card.drag_drop.register_drop_target(hand_area, [])

# Find the Area2D child node for hand collision detection
func find_hand_area():
    for child in get_children():
        if child is Area2D:
            print("HandContainer: Found Area2D for collision detection: ", child.name)
            return child
    return null

# Called when a child is added to the container
func _on_child_entered_tree(node):
    if node is Card or node is ColorRect:  # Support both Card scenes and fallback ColorRects
        if not cards.has(node):
            cards.append(node)
            
        # If it's a card, set the hand container reference and register as drop target
        if node is Card:
            # Directly set this HandContainer as the card's hand container
            if node.has_method("set_hand_container"):
                print("HandContainer: Setting self as hand_container for card: ", node.data.get("name", "Unknown"))
                node.set_hand_container(self)
                
            # Also directly register with DragDrop if available
            if node.drag_drop != null:
                print("HandContainer: Registering self as drop target for card: ", node.data.get("name", "Unknown"))
                node.drag_drop.register_drop_target(self, [])
                
                # Also register the Area2D if it exists
                var hand_area = find_hand_area()
                if hand_area:
                    node.drag_drop.register_drop_target(hand_area, [])
            
        # Reposition all cards when a new one is added
        _reposition_cards()

# Called when a child is removed from the container
func _on_child_exiting_tree(node):
    if cards.has(node):
        print("HandContainer: Removing card from tracking: " + (node.data.name if node is Card and node.data else str(node)))
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
func _process(_delta):
    # Update card animations
    for i in range(cards.size()):
        # Skip if we're out of bounds
        if i >= cards.size():
            continue
            
        var card = cards[i]
        
        # Skip invalid cards
        if not is_instance_valid(card):
            continue

        # Skip cards that are attached to chassis slots
        if card.has_meta("attached_to_chassis"):
            continue

        # Check if card is being dragged using its DragDrop component
        var is_dragging = false
        if card is Card and card.drag_drop != null:
            is_dragging = card.drag_drop.is_currently_dragging()
        
        if card is Card and not is_dragging:
            # Skip if card is already at its target position
            if card.target_position == Vector2.ZERO:
                # No target position set, calculate and set it now
                var local_pos = get_target_position(card, i)
                var global_pos = local_pos + global_position
                card.target_position = global_pos
                
                # If card is at origin (0,0), set it directly
                if card.global_position == Vector2.ZERO:
                    card.global_position = global_pos
            # Card.gd handles the actual animation in its _process

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
    var max_offset = max((total_cards - 1) / 2.0, 1.0) # Prevent division by zero
    var y_curve = 30.0 * (1.0 - (center_offset / max_offset))
    
    # Calculate base y position - centered vertically
    var y_base = size.y / 2.0
    
    # Apply curve effect but ensure it stays within boundaries
    # Assume card height is about 200 (based on custom_minimum_size)
    var card_height = 200.0
    var min_y = 10.0 # Minimum padding from top
    var max_y = size.y - (card_height * 0.7) # Keep most of card in view at bottom
    
    var y_pos = clamp(y_base - y_curve, min_y, max_y)
    
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
    
    # Force an update of size if needed
    if size.x < 10 or size.y < 10:
        print("Warning: HandContainer has very small size: ", size)
        # Use reasonable defaults if size is too small
        size = Vector2(600, 220)  # Increased height to accommodate cards
        
    # Reposition all cards
    for i in range(cards.size()):
        var card = cards[i]
        
        # Skip invalid cards
        if not is_instance_valid(card):
            continue
        
        # Skip cards that are attached to chassis slots
        if card.has_meta("attached_to_chassis"):
            continue
            
        # Get local position in container
        var local_pos = get_target_position(card, i)
        
        # Convert to global position properly
        # First get our global rect to ensure we're using the correct origin
        var container_rect = get_global_rect()
        var global_pos = container_rect.position + local_pos
        
        # Debug position info
        print("Container global_position: ", global_position, " rect: ", container_rect)
        
        # Debug output (but less verbose)
        if i == 0 or i == cards.size() - 1:  # Just log first and last card for clarity
            print("Card " + str(i) + " global position: " + str(global_pos))
        
        # If using our Card scene with custom properties
        if card is Card:
            # Check if card is being dragged using its DragDrop component
            var is_dragging = false
            if card.drag_drop != null:
                is_dragging = card.drag_drop.is_currently_dragging()
            
            # If card is being dragged, don't reposition
            if is_dragging:
                print("Card " + str(i) + " is being dragged, skipping")
                continue
                
            # Set the target position for smooth animation (using global position)
            card.target_position = global_pos
            
            # For immediate positioning (helps with initialization)
            if card.global_position == Vector2.ZERO:
                card.global_position = global_pos
            
            # Store original position in DragDrop component if available
            if card.drag_drop != null:
                card.drag_drop.original_position = global_pos
            
            # Ensure card is visible and can receive input
            card.modulate.a = 1.0
            card.mouse_filter = Control.MOUSE_FILTER_STOP
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
        # Get local position for card
        var local_pos = get_card_position(index, cards.size())
        
        # Convert to global position properly using the container's global rect
        var container_rect = get_global_rect()
        var global_pos = container_rect.position + local_pos
        
        print("Card " + str(index) + " global position: " + str(global_pos) + 
              " (container at " + str(container_rect.position) + ")")
        return global_pos
    
    print("WARNING: Card not found in hand container")
    return Vector2.ZERO
    
# Handle drops from DragDrop component
func handle_drop(card):
    # If card is not in our cards array, add it
    if not cards.has(card):
        cards.append(card)
        
    # Make sure the card is our child
    if card.get_parent() != self:
        if card.get_parent():
            card.get_parent().remove_child(card)
        add_child(card)
    
    # Reset the card position
    if card.has_method("reset_position"):
        card.reset_position()
    else:
        # Fallback for non-Card objects
        var index = cards.find(card)
        if index >= 0:
            var pos = get_original_position(card)
            card.global_position = pos
    
    # Reposition all cards
    _reposition_cards()
