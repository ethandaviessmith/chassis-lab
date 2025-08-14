extends Control
class_name RewardScreen

signal reward_selected(card_data: Dictionary)
signal continue_to_next_encounter

# Export references - set these in the editor
@export var reward_title: Label = null
@export var reward_container: HBoxContainer = null
@export var card_scene: PackedScene = preload("res://scenes/ui/Card.tscn")

@export var data_loader: DataLoader

# Reward options
var available_rewards: Array = []
var selected_reward = null
var reward_cards: Array = []

func _ready():
    # Hide initially
    visible = false
    
    # Make sure we have a card scene
    if not card_scene:
        card_scene = preload("res://scenes/ui/Card.tscn")

func show_rewards(victory: bool = true):
    """Show the reward screen with appropriate rewards"""
    print("RewardScreen: Showing rewards (Victory: ", victory, ")")
    
    # Set title based on victory
    if reward_title:
        if victory:
            reward_title.text = "Victory! Choose Your Reward:"
        else:
            reward_title.text = "Defeat! Take a Consolation Prize:"
    
    # Generate rewards
    generate_rewards(victory)
    
    # Display reward options - the available_rewards are already filled by generate_rewards
    display_reward_options()
    
    # Show the screen
    visible = true

func generate_rewards(victory: bool):
    """Generate 3 reward options"""
    available_rewards.clear()
    
    # Load card data for potential rewards
    if not data_loader:
        # Create fallback rewards if DataLoader not available
        generate_fallback_rewards(victory)
        return
    
    var all_cards = data_loader.get_all_cards()
    if all_cards.is_empty():
        generate_fallback_rewards(victory)
        return
    
    # Generate 3 random card rewards
    var num_rewards = 3
    var used_indices = []
    
    for i in range(num_rewards):
        var attempts = 0
        var card_index = -1
        
        # Try to get a unique card (avoid duplicates)
        while attempts < 10:
            card_index = randi() % all_cards.size()
            if not card_index in used_indices:
                break
            attempts += 1
        
        used_indices.append(card_index)
        var card_data = all_cards[card_index].duplicate()
        
        # Add reward type info
        card_data["reward_type"] = "card"
        available_rewards.append(card_data)
        
        print("RewardScreen: Generated reward ", i+1, ": ", card_data.get("name", "Unknown"))

func generate_fallback_rewards(_victory: bool):
    """Generate simple fallback rewards if DataLoader is unavailable"""
    available_rewards = [
        {
            "name": "Basic Core",
            "type": "Core",
            "cost": 2,
            "heat": 1,
            "durability": 3,
            "effects": [{"description": "+2 Energy"}],
            "reward_type": "card"
        },
        {
            "name": "Steel Arm",
            "type": "Arm",
            "cost": 1,
            "heat": 0,
            "durability": 2,
            "effects": [{"description": "+1 Damage"}],
            "reward_type": "card"
        },
        {
            "name": "Quick Legs",
            "type": "Legs",
            "cost": 1,
            "heat": 1,
            "durability": 2,
            "effects": [{"description": "+20% Move Speed"}],
            "reward_type": "card"
        }
    ]

func display_reward_options():
    """Create card elements for each reward option"""
    if not reward_container:
        print("RewardScreen: No reward container set!")
        return
    
    # First, clear all existing cards
    reward_cards.clear()
    for child in reward_container.get_children():
        child.queue_free()
    
    # Make sure the reward container is visible and properly configured
    reward_container.visible = true
    reward_container.alignment = BoxContainer.ALIGNMENT_CENTER
    reward_container.add_theme_constant_override("separation", 10) # Reduced separation since we use margins
    
    # Create reward cards
    for i in range(available_rewards.size()):
        var reward_data = available_rewards[i]
        create_reward_card(reward_data, i)
        
    # Let the cards position properly in the container
    await get_tree().process_frame

func create_reward_card(reward_data: Dictionary, index: int):
    """Create a card instance for a reward option"""
    if not card_scene:
        print("RewardScreen: No card scene available!")
        return
    
    # Create card instance
    var card_instance = card_scene.instantiate()
    if not card_instance:
        print("RewardScreen: Failed to instantiate card!")
        return
    
    # Set initial visibility to hidden until card is ready
    card_instance.modulate.a = 0
    
    # Add directly to reward_cards array first
    reward_cards.append(card_instance)
    
    # Make sure the card has a proper size for the container
    card_instance.custom_minimum_size = Vector2(150, 220)
    card_instance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card_instance.size_flags_vertical = Control.SIZE_EXPAND_FILL
    
    # Add margin container around the card for spacing
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_child(card_instance)
    
    # Add the margin container to reward_container
    reward_container.add_child(margin)
    
    # Set card data and initialize UI
    var card_data = reward_data.duplicate()
    
    # Make sure the card data has all required fields
    if not "name" in card_data:
        card_data["name"] = "Unknown Card"
    if not "type" in card_data:
        card_data["type"] = "Unknown"
    if not "cost" in card_data:
        card_data["cost"] = 0
    if not "heat" in card_data:
        card_data["heat"] = 0
    if not "durability" in card_data:
        card_data["durability"] = 1
    if not "effects" in card_data:
        card_data["effects"] = [{"description": "No effect"}]
        
    # Initialize the card with the data
    card_instance.initialize(card_data)
    
    # Disable drag_drop component (we just want clicks, not drag and drop)
    if card_instance.has_node("DragDrop"):
        var drag_drop = card_instance.get_node("DragDrop")
        drag_drop.enabled = false
    
    # Connect to mouse events directly
    if not card_instance.is_connected("gui_input", Callable(self, "_on_card_gui_input").bind(card_instance, index)):
        card_instance.gui_input.connect(_on_card_gui_input.bind(card_instance, index))
        
    # Make the card clickable
    card_instance.focus_mode = Control.FOCUS_ALL
    card_instance.mouse_filter = Control.MOUSE_FILTER_STOP
    
    # Use a timer to fade in the card after a short delay
    var timer = get_tree().create_timer(0.1 * index)  # Staggered appearance
    await timer.timeout
    
    # Fade in card
    var tween = create_tween()
    tween.tween_property(card_instance, "modulate:a", 1.0, 0.3)

func _on_card_gui_input(event: InputEvent, card: Card, index: int):
    """Handle card click events"""
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        print("RewardScreen: Card clicked: ", card.data.get("name", "Unknown"), " at index ", index)
        # Play click sound
        Sound.play_click()
        # Use call_deferred to avoid errors during signal processing
        call_deferred("_on_reward_selected", index)

func _on_reward_selected(index: int):
    """Handle reward selection"""
    if index < 0 or index >= available_rewards.size():
        print("RewardScreen: Invalid reward index: ", index)
        return
    
    selected_reward = available_rewards[index]
    print("RewardScreen: Selected reward: ", selected_reward.get("name", "Unknown"))
    
    # Play success sound
    Sound.play_success()
    
    # Highlight selected reward (disable other cards)
    if reward_container:
        for i in range(reward_cards.size()):
            var card = reward_cards[i]
            if card is Card:
                if i == index:
                    # Scale up and highlight selected card
                    var tween = create_tween()
                    tween.tween_property(card, "scale", Vector2(1.2, 1.2), 0.2)
                    
                    # Make card glow
                    if card.has_node("Highlight"):
                        card.get_node("Highlight").visible = true
                else:
                    # Fade out non-selected cards
                    var tween = create_tween()
                    tween.tween_property(card, "modulate:a", 0.4, 0.3)
    
    # Show brief highlight animation then continue
    # Don't emit the reward_selected signal here - it will be emitted by _on_continue()
    await get_tree().create_timer(0.3).timeout
    _on_continue()

func _on_continue():
    """Handle continuing to next encounter"""
    if not selected_reward:
        print("RewardScreen: No reward selected!")
        return
    
    print("RewardScreen: Continuing with selected reward:", selected_reward.get("name", "Unknown"))
    
    # Store the selected reward locally before hiding the screen
    var reward = selected_reward.duplicate()
    
    # First emit the reward selected signal so GameManager can add it to deck
    emit_signal("reward_selected", reward)
    
    # Then emit continue signal after a short delay
    await get_tree().create_timer(0.1).timeout
    emit_signal("continue_to_next_encounter")
    
    # Hide the reward screen
    hide_screen()

func hide_screen():
    """Hide the reward screen and reset state"""
    # Create a tween to fade out the entire screen
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.3)
    
    # Wait for animation to complete before fully hiding
    tween.tween_callback(func():
        visible = false
        modulate.a = 1.0  # Reset alpha for next time
        selected_reward = null
        available_rewards.clear()
        # Note: We don't clear reward_cards here because the children
        # will be properly cleared next time display_reward_options is called
    )

# Utility function to get selected reward data
func get_selected_reward() -> Dictionary:
    if selected_reward:
        return selected_reward
    return {}
