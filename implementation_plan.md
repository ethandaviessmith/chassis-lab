# Stage 4: Implementation Plan (Day 1/Day 2)

## Day 1: Core Functionality

### Morning (4 hours)
1. **Project Setup & Core Systems (1 hour)**
   - Create project and folder structure
   - Set up base scenes (Main, BuildView, CombatView)
   - Implement GameManager with basic state transitions
   - ✓ Checkpoint: Game can switch between build and combat views

2. **Data Structure & Loading (1 hour)**
   - Create card and enemy data structures
   - Implement DataLoader for parsing JSON files
   - Set up initial card and enemy datasets
   - ✓ Checkpoint: Game can load and instantiate cards/enemies

3. **Build Phase UI (2 hours)**
   - Create chassis slots and visual representation
   - Implement card UI with stats display
   - Set up drag and drop system for cards
   - Create basic Scrapper UI
   - ✓ Checkpoint: Can drag cards to slots and see visual change

### Afternoon (4 hours)
4. **Parts System (1.5 hours)**
   - Implement Part base class
   - Create derived classes (Head, Core, Arm, Legs)
   - Set up part attachment and effects system
   - ✓ Checkpoint: Parts correctly modify robot stats

5. **Deck Management (1 hour)**
   - Implement DeckManager for deck/hand/discard
   - Set up card drawing and energy system
   - Create basic UI for deck status
   - ✓ Checkpoint: Draw cards, spend energy, discard

6. **Basic Combat (1.5 hours)**
   - Create simple Robot and Enemy controllers
   - Implement basic movement and targeting
   - Set up collision detection
   - Create simple attack mechanics
   - ✓ Checkpoint: Robots can attack each other in combat

### Cut Line A (if behind schedule):
- Reduce initial card set from 16 to 8 (2 of each type)
- Simplify enemy behaviors to basic follow-and-attack

## Day 2: Polish and Expansion

### Morning (4 hours)
7. **Combat Expansion (1.5 hours)**
   - Implement all weapon types and effects
   - Add heat system and overheat mechanics
   - Create part durability system
   - Add combat animations and feedback
   - ✓ Checkpoint: All combat mechanics working

8. **Scrapper Enhancement (1 hour)**
   - Implement heat-based part enhancement
   - Create UI feedback for enhancements
   - Set up part exhaustion system
   - ✓ Checkpoint: Can enhance parts with heat

9. **Enemy Roster (1.5 hours)**
   - Implement all enemy types
   - Create boss behavior and special abilities
   - Balance enemy stats
   - ✓ Checkpoint: All enemies functioning correctly

### Afternoon (4 hours)
10. **Reward System (1 hour)**
    - Create reward selection screen
    - Implement reward generation logic
    - Connect rewards to progress system
    - ✓ Checkpoint: Can select rewards after combat

11. **Audio & Visual Polish (1.5 hours)**
    - Add sound effects for key actions
    - Implement CRT shader effect
    - Create combat particle effects
    - Add UI animations and transitions
    - ✓ Checkpoint: Game has basic audiovisual polish

12. **Balancing & Bug Fixes (1.5 hours)**
    - Playtest all encounters
    - Adjust card/enemy balance
    - Fix critical bugs
    - Fine-tune difficulty curve
    - ✓ Checkpoint: Game is playable start to finish

### Cut Line B (if behind schedule):
- Remove CRT effects and focus on core gameplay
- Reduce enemy variety (keep 2 types + boss)
- Simplify card rewards (fixed rewards instead of choices)

## Time Allocation

- **Core Systems**: ~30% (6 hours)
- **Combat**: ~30% (6 hours) 
- **Content/Polish**: ~40% (8 hours)

## Test Checkpoints

1. **Card Play Test**: Can draw cards, drag to slots, see changes on robot
2. **Combat Loop Test**: Robot and enemy can fight to completion
3. **Heat System Test**: Combat generates heat, can overheat
4. **Progression Test**: Win fight, get reward, progress to next encounter
5. **Full Run Test**: Complete a full 3-encounter + boss run

## Cut Lines (in priority order)

1. Reduce visual polish (effects, animations, CRT shader)
2. Simplify combat (fewer weapon types, simpler behaviors)
3. Reduce content variety (fewer cards, enemy types)
4. Remove heat enhancement system
5. Remove part durability system
6. Simplify reward system (fixed rewards vs. choices)
7. Cut boss fight (end after 3 regular encounters)

## Minimal Viable Product

- Drag-and-drop card play to robot chassis
- Energy cost for cards
- Simple auto-combat with enemies
- Win/loss conditions
- At least 8 different cards (2 per slot type)
- At least 2 enemy types
- Basic progression through 3 encounters

This implementation plan ensures focus on core gameplay first, with polish added incrementally. If time constraints become an issue, the cut lines provide clear decision points to ensure a playable prototype by the deadline.
