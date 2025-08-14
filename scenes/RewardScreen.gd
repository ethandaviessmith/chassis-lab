extends Control
class_name RewardScreen

signal reward_selected(card_data: Dictionary)
signal continue_to_next_encounter

# Export references - set these in the editor
@export var reward_title: Label = null
@export var reward_container: HBoxContainer = null
@export var continue_button: Button = null

@export var data_loader: DataLoader

# Reward options
var available_rewards: Array = []
var selected_reward = null

func _ready():
    # Hide initially
    visible = false
    
    # Connect continue button
    if continue_button:
        continue_button.pressed.connect(_on_continue_pressed)
        continue_button.text = "Continue"
        continue_button.disabled = true  # Enable after selection

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
    
    # Display reward options
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
    """Create UI elements for each reward option"""
    if not reward_container:
        print("RewardScreen: No reward container set!")
        return
    
    # Clear existing rewards
    for child in reward_container.get_children():
        child.queue_free()
    
    # Create reward buttons
    for i in range(available_rewards.size()):
        var reward_data = available_rewards[i]
        var reward_button = create_reward_button(reward_data, i)
        reward_container.add_child(reward_button)

func create_reward_button(reward_data: Dictionary, index: int) -> Button:
    """Create a button for a reward option"""
    var button = Button.new()
    button.custom_minimum_size = Vector2(200, 120)
    
    # Create reward text
    var text = reward_data.get("name", "Unknown") + "\n"
    text += "Type: " + reward_data.get("type", "Unknown") + "\n"
    text += "Cost: " + str(reward_data.get("cost", 0)) + " Energy\n"
    
    # Add first effect if available
    var effects = reward_data.get("effects", [])
    if effects.size() > 0:
        text += effects[0].get("description", "No effect")
    
    button.text = text
    
    # Connect button press
    button.pressed.connect(_on_reward_selected.bind(index))
    
    return button

func _on_reward_selected(index: int):
    """Handle reward selection"""
    if index < 0 or index >= available_rewards.size():
        print("RewardScreen: Invalid reward index: ", index)
        return
    
    selected_reward = available_rewards[index]
    print("RewardScreen: Selected reward: ", selected_reward.get("name", "Unknown"))
    
    # Highlight selected reward (disable other buttons)
    if reward_container:
        for i in range(reward_container.get_child_count()):
            var button = reward_container.get_child(i)
            if button is Button:
                if i == index:
                    button.modulate = Color(0.8, 1.0, 0.8)  # Green tint for selected
                    button.disabled = false
                else:
                    button.disabled = true
                    button.modulate = Color(0.6, 0.6, 0.6)  # Gray out others
    
    # Enable continue button
    if continue_button:
        continue_button.disabled = false
        continue_button.text = "Continue with " + selected_reward.get("name", "Reward")
    
    # Emit selection signal
    emit_signal("reward_selected", selected_reward)

func _on_continue_pressed():
    """Handle continue button press"""
    if not selected_reward:
        print("RewardScreen: No reward selected!")
        return
    
    print("RewardScreen: Continuing with selected reward")
    
    # Hide the reward screen
    hide_screen()
    
    # Signal to continue to next encounter
    emit_signal("continue_to_next_encounter")

func hide_screen():
    """Hide the reward screen and reset state"""
    visible = false
    selected_reward = null
    available_rewards.clear()
    
    # Reset continue button
    if continue_button:
        continue_button.disabled = true
        continue_button.text = "Continue"
    
    # Clear reward container
    if reward_container:
        for child in reward_container.get_children():
            child.queue_free()

# Utility function to get selected reward data
func get_selected_reward() -> Dictionary:
    if selected_reward:
        return selected_reward
    return {}
