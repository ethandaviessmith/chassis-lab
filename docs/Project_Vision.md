# Project Vision: Chassis Lab (JunkBots)

## 1. Elevator Pitch
Manage a mech's heat, energy, durability systems to outlast your opponents
A deck-building roguelike where you build a bot by adding parts that have heat and energy costs, with durability. 
Robots fight in rounds lowering part durability then health, players collect cards, medals that give modifiers to scale to fight a boss


## 2. Core Gameplay Loop
Views in the game:
1. Build Mode
Cards (parts) are added to a robot frame that equipe a fighting robot into battle
These 3 types heat, energy, durability are shared across the game
2. Battle Mode
In battle energy remains how many parts are in operation (when part is used it adds heat to the robot)
When hit remove 1 durability from an attached slot
As heat goes up to max robot overheats (slows down until heat returns back to 0)
Heat when building is 
3. Reward Screen
(later)
4. Map (city battle map), player picks next enemy to fight (or can go to store, repair shop, etc), has cutins and dialogue
5. Main menu

How mechanics interact
Heat is used to build robots (card's cost to summon), and affects battle (overheat is bad)
Energy is amount of battery capacity robot has, frame can only charge so many parts, in battle keeps stats active on robot (stats tied to pieces) e.g. shields needs a battery to run, and if battery is lowered (from drain or usage) robot loses battery - works like an energy shield has delay then rescharges
Durability is the part (and the card's life), once it reaches zero the card turns into a Scrap card (can only be used for heat), in battle durability is like the armor before robot health is lost
Cards can be modded in shop (lower energy/heat, add effect), or repaired for scrap
Scrap (money) can be used to buy random parts 

*A simple, numbered list describing a single turn from the player's perspective.*
Build Mode
1.  Start of Turn: Draw cards up to 5, set energy level, heat based on card energy cost that are on the chassis (slot)
2.  Player Action: Play cards by spending Heat to add parts to a frame
2.a Player adds parts to scrapper to ensure enough heat to start (based on card card/part heat)
3. (click start battle)

Battle Mode
0.  Robot and enemy get stats from cards in frame
1.  Auto battler where robots approach and then continue to hit each other
2.  After set amount of time (ticks), player can freeze battle to go back to build mode
3.  Repeat until one side's Durability (HP) reaches zero.
Map
1. tbd.

## 3. Target Player Experience
Feeling like at the beginning learning how basic parts on robot makes it fight better
The point of the game is to learn how many and the configuration of parts depending on the stats of the enemy in the next battle

"The player should feel like a clever engineer, making calculated risks and finding powerful synergies between managing their mech's volatile systems and the strength weaknesses that work together"

