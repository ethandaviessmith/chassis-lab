# Project Vision: Chassis Lab

## 1. Elevator Pitch
A deck-building roguelike where you are a mech engineer, strategically assembling a robot from parts to win auto-battles. Juggle your mech's Heat, Energy, and Durability, and even pause combat to reconfigure your build on the fly.

## 2. Core Pillars
*What makes this game unique?*
- **The Engineer's Dilemma:** The core tension comes from balancing the powerful parts you want to add (`Build Heat` cost) with the operational limits of your mech in combat (`Battle Heat` generation, `Energy Capacity`).
- **Reactive Rebuilding:** Combat is not fire-and-forget. The ability to pause the battle and return to Build Mode is a key strategic tool to adapt to enemy behavior or repair damage.
- **Parts are Everything:** Your "deck" is your inventory of parts. The cards you play directly become the components of your robot, defining its stats, abilities, and weaknesses.

## 3. Key Mechanics & Resources
*The three core resources that govern the entire game.*

### Heat
- **Build Heat (Cost):** A budget used in Build Mode. Each part has a `Build Heat` cost. You have a limited amount to spend when initially assembling your robot. Scrapping unwanted parts can recover some `Build Heat`. (Scrapping is to equip a card in the Scrapper chassi slot (like a recycle bin), that costs 1 durability for card heat)
- **Battle Heat (Gauge):** A gauge that fills during combat as parts are used. If it reaches maximum, the robot overheats, causing negative effects (e.g., slower attacks, temporary shutdown). It dissipates over time when parts are not in use.

### Energy
- **Energy Capacity:** The total power your mech's frame and batteries can provide. Each active part consumes a certain amount of energy. You cannot equip parts that exceed your total `Energy Capacity`.
- **Energy Level:** In battle, this functions like a rechargeable shield or mana bar. Certain actions or enemy attacks can drain it, temporarily deactivating parts until it recharges.

### Durability & Scrap
- **Part Durability:** The health of an individual part. When a part is hit in combat, its `Durability` decreases.
- **Chassis Health:** The core health of your robot. Damage is applied to `Part Durability` first. Once a part's `Durability` is 0, it is destroyed.
- **Destroyed Parts:** A destroyed part becomes a `Scrap` card. `Scrap` cards are useless in combat but can be recycled for resources in Build Mode.

## 4. Core Gameplay Loop
*A complete cycle of play.*

**1. The Map:**
- The player navigates a city map, choosing their next encounter.
- Options include: Enemy battles, Shops (buy/mod parts), Repair Bays (spend Scrap to restore Durability), and narrative events.

**2. Build Mode (Pre-Battle Prep):**
- The player enters a build screen with their chassis and hand of part cards.
- **Goal:** Assemble the best possible robot for the upcoming fight using a limited `Build Heat` budget.
- **Actions:**
    - Drag parts from hand onto chassis slots. This consumes `Build Heat` and `Energy Capacity`.
    - Scrap unwanted parts from hand to regain `Build Heat`.
    - Review the final stats (Total Durability, Battle Heat generation, etc.) of the assembled mech.
- Once satisfied, the player clicks "Start Battle".

**3. Battle Mode (Auto-Battler with a Twist):**
- The player's mech and the enemy mech fight automatically based on their equipped parts and stats.
- **Player Agency:** At any time (After a cooldown), the player can **pause the fight** and return to Build Mode.
    - In this mid-battle build phase, they can repair parts (for a cost), re-arrange components, or swap in new ones from their hand to adapt their strategy.
    - Parts are repaired by using Scrapper heat on parts
- **Outcome:** The battle ends when one mech's `Chassis Health` reaches zero.

**4. Reward Screen:**
- If victorious, the player earns rewards.
- Rewards can include: New part cards, Scrap (currency), and Medals (permanent modifiers).

## 5. Target Player Experience
*This section is well-defined and provides a great emotional target.*

"The player should feel like a clever engineer, making calculated risks and finding powerful synergies between managing their mech's volatile systems and the strength weaknesses that work together."

The point of the game is to learn how many and the configuration of parts depending on the stats of the enemy in the next battle.

