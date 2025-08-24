# Stage 6: Content Tables

This document contains the content tables for Chassis Lab, including card data, enemy data, and balance parameters.

## Cards Table

### CSV Format (cards.csv)
```csv
id,name,type,cost,heat,durability,effects,rarity,description
scope_visor,Scope Visor,Head,1,0,3,"+10% crit; highlight lowest-HP target",Common,"Basic head crit utility"
overseer_ai,Overseer AI,Head,2,1,4,"Prioritize nearest; +5% attack speed",Uncommon,"Light targeting boost"
fusion_core,Fusion Core,Core,2,1,5,"+1 Energy next turn; +2 Heat cap",Uncommon,"Economy core"
coolant_tank,Coolant Tank,Core,1,0,3,"-1 Heat per tick while >0 Heat",Rare,"Enables overclock synergies"
rail_arm,Rail Arm,Arm,2,1,3,"12 dmg shot; pierce 1",Uncommon,"Mainline DPS with pierce"
saw_arm,Saw Arm,Arm,1,1,4,"4 dmg + 2 bleed over 3s",Common,"DoT/armor shred flavor"
pulse_blaster,Pulse Blaster,Arm,1,0,3,"6 dmg; +10% stagger chance",Common,"Reliable cheap arm"
flak_arm,Flak Arm,Arm,2,1,4,"8 dmg; +25% vs shielded",Uncommon,"Anti-shield tech"
heavy_plating,Heavy Plating,Core,1,0,5,"+10 Armor until end of fight; -5% move speed",Common,"Adds a massive durability buffer to protect other parts"
tracked_legs,Tracked Legs,Leg,1,0,4,"+20% stability; -10% knockback",Common,"Baseline stability legs"
jump_jets,Jump Jets,Leg,2,1,3,"+20% dodge burst every 5s",Rare,"Evade window legs"
overclock,Overclock,Utility,1,2,2,"+25% dmg this turn; +3 Heat instantly",Uncommon,"Burst with heat risk"
patch_kit,Patch Kit,Utility,1,0,1,"Restore 3 Durability to a non-Core part. Purge 2 Heat.",Common,"In-combat repair"
auto_loader,Auto-Loader,Head,2,1,4,"+15% attack speed",Rare,"Speed head"
capacitor,Capacitor,Core,0,0,3,"Store 1 unused Energy; release next turn",Common,"Smoothing economy"
reinforced_armature,Reinforced Armature,Leg,1,0,4,"+10% move speed; +5% armor",Uncommon,"Mobility + slight armor"
```

### JSON Format (cards.json)
Contains detailed card data with structured effects, image paths, and descriptions.

## Enemies Table

### CSV Format (enemies.csv)
```csv
id,name,hp,armor,damage,attack_speed,move_speed,behavior,special_abilities,is_boss
scavenger_drone,Scavenger Drone,8,0,1,2.0,120,aggressive,"Attacks in bursts; retreats to recharge",false
guardian_sentry,Guardian Sentry,15,5,3,0.8,50,defensive,"None",false
striker_unit,Striker Unit,12,2,2,1.5,100,flanking,"Can dash to close distance quickly",false
juggernaut_prototype,Juggernaut Prototype,30,10,4,1.0,70,adaptive,"Changes attack patterns at 50% and 25% HP; can overheat and self-repair",true
```

### JSON Format (enemies.json)
Contains detailed enemy data with structured special abilities, behaviors, and sprite paths.

## Balance Parameters (balance.json)

### Player Base Stats
- Starting Energy: 3
- Max Heat: 10
- Base Move Speed: 100
- Base Attack Speed: 1.0
- Base Armor: 0

### Combat Parameters
- **Encounter Multipliers**:
  - Encounter 1: 100% health, 100% damage
  - Encounter 2: 120% health, 110% damage
  - Encounter 3: 150% health, 120% damage
  - Boss: 200% health, 150% damage

- **Overheat Thresholds**:
  - Warning: 8 heat
  - Critical: 10 heat

- **Overheat Effects**:
  - Warning: 80% attack speed, 90% move speed
  - Critical: 50% attack speed, 70% move speed, 1 durability damage per second to a random part

- **Heat Management**:
  - Natural Dissipation: -1 every 3 seconds
  - Cooldown Time: 3 seconds

- **Armor Efficiency**:
  - Damage Reduction: 5% per armor point
  - Maximum Reduction: 70%

- **Critical Hits**:
  - Base Chance: 5%
  - Damage Multiplier: 150%

### Reward System
- Cards per Encounter: 3 options
- Rarity Distribution:
  - Encounter 1: 70% Common, 25% Uncommon, 5% Rare
  - Encounter 2: 50% Common, 40% Uncommon, 10% Rare
  - Encounter 3: 30% Common, 50% Uncommon, 20% Rare

### Hangar & Repair System
- **Resource**: Scrap (used for repairs)
- **Scrap Conversion**: At end of combat, gain 1 Scrap for every point of Heat below the Warning threshold (8).
- **Repair Cost**: 1 Scrap restores 1 Durability to any part.

### Scrapper/Forge System
- **Resource**: Upgrade Materials (gained by scrapping unwanted cards)
- **Scrap Value**: 1 Material per card scrapped
- Enhancement Values:
  - Cost 1 Material: +1 damage, +1 durability
  - Cost 3 Materials: +3 damage, +2 durability
  - Cost 5 Materials: +5 damage, +3 durability

## Card Distribution by Type

| Type    | Common | Uncommon | Rare | Total |
|---------|--------|----------|------|-------|
| Head    | 1      | 1        | 1    | 3     |
| Core    | 2      | 1        | 1    | 4     |
| Arm     | 2      | 2        | 0    | 4     |
| Legs    | 1      | 1        | 1    | 3     |
| Utility | 1      | 1        | 0    | 2     |
| Total   | 7      | 6        | 3    | 16    |

## Enemy Progression

| Encounter | Enemy Type        | Health | Damage | Special Trait                   |
|-----------|-------------------|--------|--------|--------------------------------|
| 1         | Scavenger Drone   | 8      | 1      | Fast, burst attacks            |
| 2         | Striker Unit      | 12     | 2      | Medium speed, can dash         |
| 3         | Guardian Sentry   | 15     | 3      | Slow, heavily armored          |
| Boss      | Juggernaut Proto  | 30     | 4      | Adaptive AI, self-repair       |

This content provides a balanced progression with appropriate scaling of challenge and rewards throughout the game.
