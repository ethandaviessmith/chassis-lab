# Stage 7: Polish Checklist and Risk Log

This document outlines the polish priorities, risk assessment, feature deferral options, test cases, and jam timeline for the Chassis Lab prototype.

## Polish Checklist - High Priority Items
Sorted by impact/effort ratio - highest first

| Item | Description | Impact | Effort | Status |
|------|-------------|--------|--------|--------|
| Card Hover Feedback | Add visual highlight/enlarge when hovering over cards | High | Low | TODO |
| Sound Effects | Basic SFX for card draw, play, combat hits | High | Low | TODO |
| Card Play Animation | Simple animation when cards are played | High | Medium | TODO |
| Heat Meter Visual | Color-changing meter for heat levels | High | Medium | TODO |
| Part Attachment Visual | Simple visual when part connects to chassis | Medium | Medium | TODO |
| Combat Hit Indicators | Floating damage numbers and hit flashes | Medium | Medium | TODO |
| Card Tooltips | Detailed tooltips showing card effects | Medium | Low | TODO |
| Background Music | Simple looping soundtrack | Medium | Low | TODO |

## Risk Log - Potential Issues
Sorted by (likelihood * impact) - highest risk first

| Risk | Description | Likelihood | Impact | Mitigation |
|------|-------------|------------|--------|------------|
| Combat Balancing Issues | Difficulty spikes or trivial encounters due to insufficient testing | High | High | Create quick balance testing tools; have default 'safe' values that can be quickly reverted to |
| Drag/Drop Jank | Drag and drop operations feel clunky or unresponsive | High | High | Implement with priority; build test scene specifically for drag/drop refinement |
| Performance with Multiple Effects | Slowdown when many card effects trigger simultaneously | Medium | High | Queue and space out effect processing; limit simultaneous visual effects |
| Unclear Heat Consequences | Players don't understand heat mechanics or consequences | Medium | High | Clear UI indicators; tutorial tooltips; visual warning effects |
| Overwhelmed New Players | Too many mechanics introduced at once | Medium | Medium | Simple first encounter; progressive complexity; tooltips |
| Data Loading Failures | JSON/CSV parsing errors or missing data | Low | High | Add error checking and fallback data; unit test the data loading |
| Save State Corruption | Loss of progress due to save failures | Low | High | Backup save files; validate save data before writing |

## Feature Deferral List
Lower priority features that can be cut if time runs out

| Feature | Impact if Cut | Alternative |
|---------|---------------|------------|
| Advanced Tutorial | Low | Simple text tooltips |
| Multiple Robot Chassis Options | Low | Single chassis with clear upgrade paths |
| Achievement System | Low | None needed for prototype |
| Advanced Card Interactions | Medium | Simpler card effects with clear utility |
| Enemy AI Variety | Medium | Basic follow/attack patterns with speed/damage variation |

## Test Cases - Critical Functions
Core functionality that must be tested

| Function | Test |
|----------|------|
| Card Drawing | Draw cards up to hand limit; ensure correct types are drawn |
| Part Attachment | Drag parts to robot; ensure correct stats are applied |
| Heat Generation | Use high-heat cards; verify heat increases correctly |
| Heat Consequences | Reach heat threshold; verify penalties are applied |
| Combat Resolution | Run complete combats; verify damage calculations |
| Durability | Use parts until durability depletes; verify they break |
| Enemy Behavior | Verify each enemy follows its behavior pattern |
| Encounter Progression | Complete encounters; verify difficulty scaling |

## Implementation Plan - Jam Timeline

| Timeframe | Goals |
|-----------|-------|
| Day 1 - First 8 Hours | Complete design doc, Set up Godot project, Create core classes, Implement data loading |
| Day 1 - Second 8 Hours | Implement card system, Build robot part attachment, Create combat mechanics, Implement basic UI |
| Day 2 - First 8 Hours | Implement enemy AI, Build combat resolver, Create heat mechanics, Test core gameplay loop |
| Day 2 - Second 8 Hours | Polish highest impact items, Fix critical bugs, Add basic sound/visuals, Package for submission |
