# Game Design Document

# Core Loop
## Build Phase

Draw 5 cards from deck
Spend energy to play cards onto chassis slots
Use Scrapper/Forge to enhance parts using heat
When ready, initiate combat

## Combat Phase
Auto-resolves in real-time
Robots move and attack autonomously
Heat builds up during combat
Parts lose durability (1 per round)
Combat ends when player or enemies reach 0 energy/health


## Reward Phase
Choose 1 of 3 new parts/cards
Continue to next encounter

# Resource Systems
- Energy
Functions as both resource and health
Starting value: 10 units
Spend to play cards during build phase
Damage in combat reduces energy
0 energy = defeat

- Heat
Build Phase Heat (Scrapper/Forge)
Scrapper Heat level determines mod potential
Adding parts with heat will use heat to activate improved effects
Activated parts are exhausted for the fight
No energy cost for heat activation

- Combat Heat
Accumulates during combat from part usage
At 8+ heat: -20% attack speed
At 10 heat: "Overheated" status, -50% attack speed, 1 damage per tick
Core pieces have heat sync cooldowns to manage heat

- Durability
Parts have durability rating (typically 3-5)
Decreases by 1 per combat round
At 0 durability, part breaks and is discarded

- Slot Rules & Upgrades
Head (x1): Controls targeting, critical hits, sensors
Core (x1): Energy generation, heat management, armor
Arms (x2): Weapons, damage output, special attacks
Legs (x2): Movement, dodge, stability

- Upgrade Rules:
New parts replace existing parts in the same slot
Replaced parts return to discard pile
Scrapper can enhance parts by applying heat-based modifications
Enhanced parts gain +effects but are exhausted for the current fight


# Enemy Roster
## Regular Enemies
Scavenger Drone

HP: 8
Damage: 1 per hit (rapid fire)
Speed: Fast
Quirk: Attacks in bursts, retreats to recharge
Guardian Sentry

HP: 15
Damage: 3 per hit (slow rate)
Speed: Slow
Quirk: Has 5 armor, reducing incoming damage
Striker Unit

HP: 12
Damage: 2 per hit (medium rate)
Speed: Medium
Quirk: Can dash to close distance quickly
## Boss
### Juggernaut Prototype
HP: 30
Damage: 4 per hit (medium rate)
Speed: Variable
Quirk: Changes attack patterns at 50% and 25% HP; can overheat and self-repair
Balancing Targets (Day 1)
Player starting energy/HP: 10
Player damage per turn: 3-6 (basic loadout)
Heat generation: 1-3 per combat round
Durability loss: 1 per combat round
Average combat length: 30-45 seconds
Overheat recovery time: ~10 seconds

# UI Layout
┌───────────────────────┬───────────────────────┐
│                       │                       │
│  BUILD AREA           │  COMBAT VIEWPORT      │
│  ┌───────┐            │  ┌─────────────────┐  │
│  │ HEAD  │            │  │                 │  │
│  └───────┘            │  │                 │  │
│  ┌───────┐            │  │                 │  │
│  │ CORE  │            │  │                 │  │
│  └───────┘            │  │                 │  │
│  ┌───┐ ┌───┐          │  │                 │  │
│  │ARM│ │ARM│          │  │                 │  │
│  └───┘ └───┘          │  └─────────────────┘  │
│  ┌────┐               │  ┌─────────┬─────────┐│
│  │LEGs│               │  │DECK: 12 │ENERGY:10││
│  └────┘               │  ├─────────┼─────────┤│
│                       │  │HEAT: 3/10│ROUND: 1││
│  ┌─────────────────┐  │  └─────────┴─────────┘│
│  │    SCRAPPER     │  │                       │
│  │    HEAT: 0/5    │  │                       │
│  └─────────────────┘  │                       │
│                       │                       │
├───────────────────────┴───────────────────────┤
│             HAND (DRAWN CARDS)                │
│  ┌────┐  ┌────┐  ┌────┐  ┌────┐  ┌────┐       │
│  │Card│  │Card│  │Card│  │Card│  │Card│       │
│  └────┘  └────┘  └────┘  └────┘  └────┘       │
└───────────────────────────────────────────────┘


# Interaction Rules
Drag & Drop: Cards from hand to chassis slots or scrapper
Tooltip: Hover over cards/parts to see details and stats
Preview: When hovering a card over a slot, show stat changes
Heat Application: Click scrapper, then target part to enhance
Combat Start: Button appears when build phase complete
Reward Selection: Click on desired card from 3 options

# Starter 16-Card List
Name	Type	Cost	Heat	Durability	Effects	Rarity	Notes
Scope Visor	Head	1	0	3	+10% crit; highlight lowest-HP target	Common	Basic head crit utility
Overseer AI	Head	2	1	4	Prioritize nearest; +5% attack speed	Uncommon	Light targeting boost
Fusion Core	Core	2	1	5	+1 Energy next turn; +2 Heat cap	Uncommon	Economy core
Coolant Tank	Core	1	0	3	-1 Heat per tick while >0 Heat	Rare	Enables overclock synergies
Rail Arm	Arm	2	1	3	12 dmg shot; pierce 1	Uncommon	Mainline DPS with pierce
Saw Arm	Arm	1	1	4	4 dmg + 2 bleed over 3s	Common	DoT/armor shred flavor
Pulse Blaster	Arm	1	0	3	6 dmg; +10% stagger chance	Common	Reliable cheap arm
Flak Arm	Arm	2	1	4	8 dmg; +25% vs shielded	Uncommon	Anti-shield tech
Heavy Plating	Core	1	0	5	+10 Armor until end of fight; -5% move speed	Common	Survivability tradeoff
Tracked Legs	Legs	1	0	4	+20% stability; -10% knockback	Common	Baseline stability legs
Jump Jets	Legs	2	1	3	+20% dodge burst every 5s	Rare	Evade window legs
Overclock	Utility	1	2	2	+25% dmg this turn; +3 Heat instantly	Uncommon	Burst with heat risk
Patch Kit	Utility	1	0	1	Heal 15 HP; purge 2 Heat	Common	Emergency sustain
Auto-Loader	Head	2	1	4	+15% attack speed	Rare	Speed head
Capacitor	Core	0	0	3	Store 1 unused Energy; release next turn	Common	Smoothing economy
Reinforced Armature	Legs	1	0	4	+10% move speed; +5% armor	Uncommon	Mobility + slight armor
