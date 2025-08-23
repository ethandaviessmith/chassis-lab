 # Current State Audit

 ## 1. What Works
 *A list of features from the Project Vision that are considered implemented, even if imperfectly.*

 ### **Game Flow & Map**
 - The player can navigate a city map to select their next encounter. (not implemented)
 - Reward screens appear after battle, granting new parts and scrap. (scrap not implemented)

 ### **Build Mode**
 - Players can drag Part cards from their hand onto Chassis slots to build a mech.
 - A `Build Heat` resource is used as a budget for adding parts.
 - An `Energy Capacity` stat limits the total energy consumption of equipped parts.
 - Unwanted cards can be moved to a scrapper to regain `Build Heat`.
 - Player stats display updates based on the parts equipped.

 ### **Battle Mode**
 - The core auto-battler sequence is in place: mechs approach and attack each other.
 - `Battle Heat` is generated as parts are used, with an overheat state at max.
 - `Part Durability` and `Chassis Health` function as armor and core health.
 - The ability to pause combat and return to a mid-battle Build Mode exists.

 ## 2. Known Bugs & Inconsistencies
 *A specific list of what is currently broken or not working as intended. This is based on the primary development pain points.*
 - **Deck & Discard Count:** The UI counters for the number of cards in the deck and discard pile are frequently incorrect, especially after multiple actions.
 - **Card State Management:** Cards do not reliably move between states (Hand, Deck, Chassis, Scrapper, Discard). References to cards persist after they are moved, causing data inconsistencies and crashes.
 - **Drag-and-Drop Instability:** Dragging a card from a Chassis slot back to the hand is unreliable; the card can get stuck or become unresponsive.
 - **Stat Scaling:** The logic for how part stats combine and apply to the final mech is difficult to trace and modify, making balancing a challenge.
 - **Enemy Pacing:** The difficulty curve is broken. Early fights are too easy, followed by an extreme difficulty spike.

 ## 3. Architectural Pain Points
 - **Fragile Implementation:** The codebase feels like a patchwork of generated code and specific fixes. Building new features on top of this foundation often overwrites or breaks previous work.
 - **Blocked Experimentation:** As a result of the above, the current structure is not flexible. Modifying core mechanics like `Heat`, `Energy`, or `Durability` is a major, risky overhaul. This is the primary blocker to iterating on game dynamics and finding what's fun.

