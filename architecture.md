# Stage 3: Technical Architecture (Godot 4.4)

## Folder Structure
```
res://
├── assets/
│   ├── fonts/
│   ├── images/
│   │   ├── cards/
│   │   ├── chassis/
│   │   ├── enemies/
│   │   ├── parts/
│   │   └── ui/
│   ├── sounds/
│   └── themes/
├── data/
│   ├── cards.json
│   └── enemies.json
├── scenes/
│   ├── main/
│   │   ├── Main.tscn
│   │   └── Main.gd
│   ├── build/
│   │   ├── BuildView.tscn
│   │   ├── BuildView.gd
│   │   └── Scrapper.gd
│   ├── combat/
│   │   ├── CombatView.tscn
│   │   ├── CombatView.gd
│   │   └── Arena.gd
│   ├── entities/
│   │   ├── Robot.tscn
│   │   ├── Robot.gd
│   │   ├── Enemy.tscn
│   │   └── Enemy.gd
│   ├── parts/
│   │   ├── Part.tscn
│   │   ├── Part.gd
│   │   ├── Head.gd
│   │   ├── Core.gd
│   │   ├── Arm.gd
│   │   └── Legs.gd
│   └── ui/
│       ├── Card.tscn
│       ├── Card.gd
│       ├── HUD.tscn
│       ├── HUD.gd
│       └── RewardScreen.tscn
├── scripts/
│   ├── managers/
│   │   ├── GameManager.gd
│   │   ├── DeckManager.gd
│   │   ├── TurnManager.gd
│   │   └── CombatResolver.gd
│   ├── utils/
│   │   ├── DragDrop.gd
│   │   └── DataLoader.gd
│   └── effects/
│       └── EffectsManager.gd
├── project.godot
└── default_env.tres
```

## Scene Graph Plan

### Main.tscn
- Root (Node)
  - ViewportContainer
    - BuildView (scene instance)
    - CombatView (scene instance, hidden initially)
  - HUD (scene instance)
  - RewardScreen (scene instance, hidden initially)
  - Managers
    - GameManager
    - DeckManager
    - TurnManager
    - CombatResolver

### BuildView.tscn
- BuildView (Node2D)
  - Background
  - ChassisView
    - HeadSlot
    - CoreSlot
    - ArmSlotLeft
    - ArmSlotRight
    - LegsSlot
  - ScrapperArea
    - ScrapperVisual
    - HeatDisplay
  - HandArea
  - StartCombatButton

### CombatView.tscn
- CombatView (Node2D)
  - Arena
    - Background
    - Obstacles
    - PlayerSpawnPoint
    - EnemySpawnPoint
  - CombatBezel
    - BezelFrame
    - ScanlineEffect
  - CombatEffects
    - Particles
    - Animations
  - DebugOverlay (hidden in release)

### Card.tscn
- Card (Control)
  - Background
  - Image
  - NameLabel
  - TypeLabel
  - StatsContainer
    - CostLabel
    - HeatLabel
    - DurabilityLabel
  - EffectsLabel
  - Highlight (visible when selected)
  - DragComponent (script)

### Robot.tscn
- Robot (CharacterBody2D)
  - Sprite
    - FrameSprite
    - HeadSprite
    - CoreSprite
    - LeftArmSprite
    - RightArmSprite
    - LegsSprite
  - CollisionShape
  - HealthBar
  - HeatBar
  - WeaponPositions
    - LeftWeaponPos
    - RightWeaponPos
  - AnimationPlayer
  - StatusEffects

### Part.tscn (base)
- Part (Node2D)
  - Sprite
  - AttachPoint
  - EffectsContainer
  - DurabilityCounter

## Data Model

### Card JSON Schema
```json
{
  "id": "string",
  "name": "string",
  "type": "string (Head/Core/Arm/Legs/Utility)",
  "cost": "integer",
  "heat": "integer",
  "durability": "integer",
  "effects": [
    {
      "type": "string (damage/defense/utility)",
      "value": "integer/float",
      "description": "string",
      "trigger": "string (optional)"
    }
  ],
  "rarity": "string (Common/Uncommon/Rare)",
  "image": "string (path to image)",
  "description": "string"
}
```

### Enemy JSON Schema
```json
{
  "id": "string",
  "name": "string",
  "hp": "integer",
  "armor": "integer",
  "damage": "integer",
  "attack_speed": "float",
  "move_speed": "float",
  "behavior": "string",
  "special_abilities": [
    {
      "name": "string",
      "description": "string",
      "trigger": "string",
      "effect": "string"
    }
  ],
  "sprite": "string (path to image)"
}
```

### Sample Card Data
```json
{
  "id": "rail_arm",
  "name": "Rail Arm",
  "type": "Arm",
  "cost": 2,
  "heat": 1,
  "durability": 3,
  "effects": [
    {
      "type": "damage",
      "value": 12,
      "description": "12 damage shot with pierce 1"
    }
  ],
  "rarity": "Uncommon",
  "image": "res://assets/images/parts/rail_arm.png",
  "description": "High-powered linear accelerator that fires metal slugs through multiple targets."
}
```

### Sample Enemy Data
```json
{
  "id": "guardian_sentry",
  "name": "Guardian Sentry",
  "hp": 15,
  "armor": 5,
  "damage": 3,
  "attack_speed": 0.8,
  "move_speed": 50,
  "behavior": "defensive",
  "special_abilities": [
    {
      "name": "Reinforced Shell",
      "description": "Reduces incoming damage",
      "trigger": "always",
      "effect": "damage_reduction"
    }
  ],
  "sprite": "res://assets/images/enemies/guardian_sentry.png"
}
```

## Signals and Events

### Game Flow
- `game_started` - Emitted when a new game begins
- `build_phase_started` - Emitted when entering build phase
- `build_phase_ended` - Emitted when build phase ends
- `combat_phase_started` - Emitted when combat begins
- `combat_phase_ended` - Emitted when combat ends
- `reward_phase_started` - Emitted when reward selection begins
- `reward_selected(card_id)` - Emitted when player selects a reward
- `game_over(victory)` - Emitted when game ends (victory or defeat)

### Build Phase
- `card_drawn(card)` - Emitted when a card is drawn to hand
- `card_played(card, slot)` - Emitted when a card is played to a slot
- `card_scrapped(card)` - Emitted when a card is sent to scrapper
- `part_attached(part, slot)` - Emitted when a part is attached to robot
- `part_enhanced(part, heat_used)` - Emitted when a part is enhanced
- `heat_changed(new_heat)` - Emitted when scrapper heat changes

### Combat
- `combat_tick` - Emitted each combat update frame
- `damage_dealt(source, target, amount)` - Emitted when damage is dealt
- `robot_heat_changed(new_heat)` - Emitted when robot heat changes
- `overheat_started` - Emitted when robot overheats
- `overheat_ended` - Emitted when robot cools down
- `part_durability_changed(part, new_durability)` - When part durability changes
- `part_broken(part)` - Emitted when a part breaks (0 durability)
- `entity_defeated(entity)` - Emitted when an entity reaches 0 energy/HP

### Drag and Drop
- `drag_started(card)` - Emitted when card drag begins
- `drag_ended(card)` - Emitted when card drag ends
- `drop_attempted(card, target)` - Emitted when card is dropped on target
- `drop_succeeded(card, target)` - Emitted when drop is valid and accepted
- `drop_failed(card, target)` - Emitted when drop is invalid

## Class Responsibilities

### GameManager
- Controls overall game state and flow
- Manages transitions between game phases
- Tracks player progress through encounters
- Handles game over conditions

### DeckManager
- Manages card collection, deck, hand, and discard pile
- Handles card drawing, shuffling, and discarding
- Tracks card availability and exhaustion

### TurnManager
- Manages turn sequencing in build phase
- Handles energy allocation and usage
- Controls turn transitions

### CombatResolver
- Processes combat logic and physics
- Applies damage, effects, and status changes
- Manages targeting and attack resolution
- Handles collision detection and movement

### BuildView
- Displays robot chassis and slots
- Visualizes card hand and scrapper
- Handles slot highlighting and feedback
- Manages build UI interactions

### CombatView
- Renders the combat arena
- Handles camera control during combat
- Displays combat effects and feedback
- Manages arena obstacles and boundaries

### Robot
- Represents player's robot entity
- Stores attached parts and their states
- Tracks robot stats (energy/HP, heat, etc.)
- Handles robot movement and animations

### Part (and derived classes)
- Base class for all attachable parts
- Stores part stats and effects
- Handles durability tracking
- Specialized behavior in derived classes (Head/Core/Arm/Leg)

### Card
- UI representation of a playable card
- Displays card info and stats
- Handles card interactions and animations
- Supports drag and drop functionality

### Enemy
- Represents enemy entities
- Handles enemy AI and behavior patterns
- Tracks enemy stats and states
- Manages enemy animations and attacks

### Scrapper
- Manages the scrap/forge system
- Handles heat generation and usage
- Processes part enhancements
- Provides feedback on enhancement options

## Memory-Based Run State
- All game state stored in memory during a run
- No save/load functionality for jam version
- GameManager maintains central state references
- Clean reset functionality for new runs
