# Simple test script to verify drag-drop functionality
extends Node

func _ready():
    print("=== Testing Card Drag-Drop Functionality ===")
    
    # Test 1: Verify BuildView has the required methods
    print("1. Checking BuildView methods...")
    var build_view_script = load("res://scenes/BuildView.gd")
    if build_view_script:
        print("   ✓ BuildView.gd loaded successfully")
        
        # Check if key methods exist
        var test_instance = build_view_script.new()
        if test_instance.has_method("_attach_part_to_slot"):
            print("   ✓ _attach_part_to_slot method exists")
        else:
            print("   ✗ _attach_part_to_slot method missing")
            
        if test_instance.has_method("_handle_card_drop"):
            print("   ✓ _handle_card_drop method exists")
        else:
            print("   ✗ _handle_card_drop method missing")
            
        test_instance.queue_free()
    else:
        print("   ✗ Failed to load BuildView.gd")
    
    # Test 2: Check DragDrop component
    print("\n2. Checking DragDrop component...")
    var drag_drop_script = load("res://scripts/utils/DragDrop.gd")
    if drag_drop_script:
        print("   ✓ DragDrop.gd loaded successfully")
    else:
        print("   ✗ Failed to load DragDrop.gd")
    
    # Test 3: Check Card scene
    print("\n3. Checking Card scene...")
    var card_scene = load("res://scenes/ui/Card.tscn")
    if card_scene:
        print("   ✓ Card.tscn loaded successfully")
        var card_instance = card_scene.instantiate()
        if card_instance.has_method("initialize"):
            print("   ✓ Card initialize method exists")
        else:
            print("   ✗ Card initialize method missing")
        card_instance.queue_free()
    else:
        print("   ✗ Failed to load Card.tscn")
    
    print("\n=== Test Complete ===")
    get_tree().quit()
