@tool
extends Control
class_name DeckControl

# Use preload to avoid circular dependencies
const DeckEditorViewClass = preload("res://scenes/ui/DeckEditorView.gd")

# References to UI elements
@onready var draw_pile_button = $DrawPileButton
@onready var draw_pile_count = $DrawPileButton/CountLabel
@onready var discard_pile_button = $DiscardPileButton
@onready var discard_pile_count = $DiscardPileButton/CountLabel
@onready var deck_button = $DeckButton
@onready var new_button = $NewButton
@onready var deck_count = $DeckButton/CountLabel
@onready var deck_view_container = $DeckViewContainer
@onready var deck_grid = $DeckViewContainer/ScrollContainer/GridContainer
@onready var back_button = $DeckViewContainer/BackButton
@onready var redraw_button = $RedrawButton

# External references
@export var deck_manager: DeckManager
@export var hand_manager: HandManager
@export var card_scene: PackedScene
@export var deck_editor_view: Control  # Will be cast to DeckEditorView

# State tracking
var is_deck_view_open = false

func _ready():
    # Hide deck view initially
    if deck_view_container:
        deck_view_container.visible = false
        
        # Set up proper mouse filtering for components
        # When hidden, the container shouldn't capture input
        deck_view_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
        
        # Make sure the ScrollContainer can receive mouse events (scroll wheel)
        var scroll_container = deck_view_container.get_node_or_null("ScrollContainer")
        if scroll_container:
            scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
            
            # Make sure the GridContainer passes mouse events to the ScrollContainer
            if deck_grid:
                deck_grid.mouse_filter = Control.MOUSE_FILTER_PASS
    
    # Connect button signals
    if draw_pile_button:
        draw_pile_button.pressed.connect(_on_draw_pile_button_pressed)
    if discard_pile_button:
        discard_pile_button.pressed.connect(_on_discard_pile_button_pressed)
    if deck_button:
        deck_button.pressed.connect(_on_deck_button_pressed)
    if back_button:
        back_button.pressed.connect(_on_back_button_pressed)
    if redraw_button:
        redraw_button.pressed.connect(_on_redraw_button_pressed)
    if new_button:
        new_button.pressed.connect(_on_new_button_pressed)
    
    # Connect to deck manager signals
    if deck_manager:
        deck_manager.connect("deck_updated", _update_counters)
        _update_counters()  # Initial update

func _update_counters():
    if not deck_manager:
        return
    
    var status = deck_manager.get_deck_status()
    
    # Update draw pile count
    if draw_pile_count:
        draw_pile_count.text = str(status.deck_size)
    
    # Update discard pile count
    if discard_pile_count:
        discard_pile_count.text = str(status.discard_size)
        
    # Update total deck count
    if deck_count:
        # Calculate the total number of unique cards
        # IMPORTANT: Make sure to include hand_size in total count to keep it consistent
        var total_cards = status.deck_size + status.discard_size + status.exhausted_size + status.hand_size
        
        # Debug log to track card counts
        print("DeckControl: Updating counters - Draw: ", status.deck_size, 
              ", Discard: ", status.discard_size, 
              ", Exhausted: ", status.exhausted_size, 
              ", Hand size: ", status.hand_size,
              ", Total: ", total_cards)
              
        deck_count.text = str(total_cards)

func _on_draw_pile_button_pressed():
    _show_deck_view("draw")

func _on_discard_pile_button_pressed():
    _show_deck_view("discard")

func _on_deck_button_pressed():
    _show_deck_view("all")

func _on_back_button_pressed():
    _hide_deck_view()

func _on_redraw_button_pressed():
    
    if hand_manager:
        # Optionally play a sound when redrawing
        if Sound and Sound.has_method("play_sfx"):
            Sound.play_sfx("card_shuffle")
            
        # Redraw the hand
        hand_manager.discard_hand()
        deck_manager.draw_hand()
        
func _on_new_button_pressed():
    if deck_editor_view:
        # Cast to DeckEditorView if needed
        var editor = deck_editor_view as DeckEditorViewClass
        if editor:
            editor.show_editor()
            
func _show_deck_view(pile_type = "all"):
    if not deck_view_container or not deck_manager:
        return
    
    # Start with the container invisible but activate it
    deck_view_container.visible = true
    deck_view_container.modulate.a = 0.0  # Start transparent for fade-in
    is_deck_view_open = true
    
    # MOUSE_FILTER_STOP = intercepts all mouse events, blocks anything beneath
    deck_view_container.mouse_filter = Control.MOUSE_FILTER_STOP

    # Create fade-in effect
    var tween = create_tween()
    tween.tween_property(deck_view_container, "modulate:a", 1.0, 0.2)
    
    # Play sound effect
    Sound.play_card_draw()
    
    # Clear existing cards
    for child in deck_grid.get_children():
        child.queue_free()
    
    # Get cards based on pile type
    var cards_to_show = []
    match pile_type:
        "draw":
            cards_to_show = deck_manager.deck
        "discard":
            cards_to_show = deck_manager.discard_pile
        "all":
            # Show all cards including draw pile, discard pile, hand, and exhausted cards
            cards_to_show = deck_manager.deck + deck_manager.discard_pile
            cards_to_show += deck_manager.hand
            if deck_manager.exhausted_pile:
                cards_to_show += deck_manager.exhausted_pile
    
    # Update the title based on which pile is being viewed
    var title_label = deck_view_container.get_node_or_null("Label")
    if title_label:
        match pile_type:
            "draw":
                title_label.text = "Draw Pile"
            "discard":
                title_label.text = "Discard Pile"
            "all":
                title_label.text = "All Cards"
    
    # Create card instances for each card with a staggered animation
    var delay = 0.0
    for card_data in cards_to_show:
        var card = card_scene.instantiate()
        deck_grid.add_child(card)
        card.initialize(card_data, null, null)

        # Disable drag/drop in deck view
        if card.drag_drop:
            card.drag_drop.set_enabled(false)
                        
        # Animate each card with a slight delay
        card.modulate.a = 0.0
        var card_tween:Tween = create_tween()
        card_tween.tween_property(card, "modulate:a", 1.0, delay)
        
        # Increase delay for next card, but use a smaller increment for larger decks
        if cards_to_show.size() > 20:
            delay += 0.02  # 20ms stagger for large decks
        else:
            delay += 0.05  # 50ms stagger for small decks
        if delay > 1.5:
            delay = 1.5

func _hide_deck_view():
    if not deck_view_container:
        return
    
    # Optionally play a sound when closing
    if Sound and Sound.has_method("play_back"):
        Sound.play_back()
    
    # Create fade-out effect
    var tween = create_tween()
    tween.tween_property(deck_view_container, "modulate:a", 0.0, 0.2)
    tween.tween_callback(func():
        # After fade completes, hide the container and reset properties
        deck_view_container.visible = false
        is_deck_view_open = false
        
        # Reset mouse filter when hiding
        deck_view_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
        
        # Clear existing cards to free memory
        for child in deck_grid.get_children():
            child.queue_free()
    )

# Handle input to close deck view with Escape key
func _input(event):
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ESCAPE and is_deck_view_open:
            _hide_deck_view()
            get_viewport().set_input_as_handled()
