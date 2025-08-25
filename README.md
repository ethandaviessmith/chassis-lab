# Chassis Lab - Game Jam Prototype

## Overview
Chassis Lab is a retro-arcade deck-building auto-battler where players drag Head/Core/Arm/Leg cards onto a robot chassis to attach/upgrade parts. The game features heat management, part durability, and auto-combat mechanics, all developed within a 2-day game jam scope.

## How to Run

1.  Ensure you have Godot Engine v4.x installed.
2.  Open the project in the Godot editor.
3.  Run the main scene (e.g., `main.tscn`).

## Core Mechanics

### Card System
- Draw cards from your deck each turn.
- Drag and drop cards onto the robot chassis to attach or upgrade parts.
- Parts have an energy cost, generate heat, and have a durability rating.

### Heat Management
- Using parts generates heat.
- Excessive heat can decrease robot performance.
- Reaching critical heat levels will cause damage to the robot.

### Combat System
- Combat is auto-resolved based on the parts currently attached to your robot.
- Parts can break and become unusable if their durability reaches zero.
- Enemies feature different behaviors and attack patterns.

## Project Structure

This project is organized into the following key areas:

-   **`scripts/`**: Core game logic and entity classes.
    -   `GameManager.gd`: Central game state controller.
    -   `DeckManager.gd`: Manages the player's deck, hand, and card operations.
    -   `TurnManager.gd`: Controls the turn sequence and combat flow.
    -   `CombatResolver.gd`: Handles all combat calculations and interactions.
    -   `DataLoader.gd`: Loads game data from JSON/CSV files.
    -   `Robot.gd`: The player-controlled robot with attachable parts.
    -   `Enemy.gd`: Base class for enemy entities.
    -   `Part.gd`: Represents individual robot parts.
    -   `Card.gd`: Represents the cards that grant parts.
-   **`data/`**: Game data files (definitions for cards, enemies, etc.).
    -   `cards.json`
    -   `enemies.json`
    -   `balance.json`
-   **`addons/`**: Godot editor plugins.
    -   **Aseprite Wizard**: Used for importing Aseprite files.

## Documentation

Key design and implementation documents:

-   **Implementation Summary**: An overview of the implementation plan and development timeline.
-   **Content Tables**: Data tables for cards and enemies.
-   **Polish & Risk Assessment**: A list of polish priorities and potential risks.

## License

This project is created for educational purposes and as a game jam submission.
