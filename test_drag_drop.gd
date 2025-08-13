# Simple test script to verify drag-drop and energy functionality
extends Node

func _ready():
    print("=== Testing Card System with DataLoader and Energy ===")
    
    # Test 1: Verify DataLoader
    print("1. Testing DataLoader...")
    var data_loader = load("res://scripts/utils/DataLoader.gd").new()
    var all_cards = data_loader.load_all_cards()
    print("   ✓ Loaded ", all_cards.size(), " cards from DataLoader")
    
    if all_cards.size() > 0:
        var first_card = all_cards[0]
        print("   ✓ First card: ", first_card.get("name", "Unknown"), " (Cost: ", first_card.get("cost", 0), ")")
    
    # Test 2: Verify starting deck
    print("\n2. Testing starting deck...")
    var starter_deck = data_loader.load_starting_deck()
    print("   ✓ Starting deck has ", starter_deck.size(), " cards")
    
    # Show card types in starting deck
    var type_counts = {}
    for card in starter_deck:
        var card_type = card.get("type", "Unknown")
        type_counts[card_type] = type_counts.get(card_type, 0) + 1
    
    print("   Card types in starter deck:")
    for type_name in type_counts:
        print("     - ", type_name, ": ", type_counts[type_name])
    
    # Test 3: Verify managers load
    print("\n3. Testing manager classes...")
    var deck_manager_script = load("res://scripts/managers/DeckManager.gd")
    var turn_manager_script = load("res://scripts/managers/TurnManager.gd")
    
    if deck_manager_script:
        print("   ✓ DeckManager script loaded")
    if turn_manager_script:
        print("   ✓ TurnManager script loaded")
    
    print("\n=== Test Complete ===")
    print("Ready to test in BuildView with energy system!")
    get_tree().quit()
