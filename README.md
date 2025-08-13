# Chassis Lab - Game Jam Prototype

## Overview
Chassis Lab is a retro-arcade deck-building auto-battler where players drag Head/Core/Arm/Leg cards onto a robot chassis to attach/upgrade parts. The game features heat management, part durability, and auto-combat mechanics in a 2-day game jam scope.

## Project Structure

This project contains the following key components:

1. **Core Game Systems**
   - GameManager.gd - Central game state controller
   - DeckManager.gd - Manages deck, hand, and card operations
   - TurnManager.gd - Controls turn sequence and combat flow
   - CombatResolver.gd - Handles combat interactions
   - DataLoader.gd - Loads game data from JSON/CSV files

2. **Entity Classes**
   - Robot.gd - Player-controlled entity with attachable parts
   - Enemy.gd - Base enemy class with AI behaviors
   - Part.gd, Head.gd, Core.gd, Arm.gd, Legs.gd - Part system
   - Card.gd - Card representation with costs and effects

3. **Data Files**
   - cards.csv/json - Card definitions
   - enemies.csv/json - Enemy definitions
   - balance.json - Game balance parameters

4. **Documentation**
   - content_tables.md - Card and enemy data tables
   - polish_and_risk.md - Polish priorities and risk assessment
   - implementation_summary.md - Implementation overview

## Core Mechanics

### Card System
- Draw cards each turn
- Drag cards to robot chassis to attach parts
- Parts have energy cost, heat generation, and durability

### Heat Management
- Cards generate heat
- Excessive heat decreases performance
- Critical heat causes damage

### Combat System
- Auto-resolved combat based on attached parts
- Parts can break if durability reaches zero
- Enemies have different behaviors and attack patterns

## Implementation Status

This project contains all necessary scaffolding code and data files for the game jam prototype. The next step is implementing the core gameplay mechanics following the implementation priorities outlined in the implementation_summary.md file.

## Development Timeline

The project is designed for a 2-day jam with the following milestones:
1. Day 1 First Half: Design and core systems
2. Day 1 Second Half: Card system and robot mechanics
3. Day 2 First Half: Combat and enemy AI
4. Day 2 Second Half: Polish and testing

## Running the Project

1. Open the project in Godot 4.4
2. Run game.gd as the main scene
3. Follow the implementation priorities in implementation_summary.md

## License

This project is created for educational purposes and game jam submission.
