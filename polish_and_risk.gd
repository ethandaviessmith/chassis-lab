extends Node

# Stage 7: Polish Checklist and Risk Log

# Polish Checklist - High Priority Items
# These are sorted by impact/effort ratio - highest first

var polish_checklist = [
	{
		"item": "Card Hover Feedback",
		"description": "Add visual highlight/enlarge when hovering over cards",
		"impact": "High",
		"effort": "Low",
		"status": "TODO"
	},
	{
		"item": "Sound Effects",
		"description": "Basic SFX for card draw, play, combat hits",
		"impact": "High", 
		"effort": "Low",
		"status": "TODO"
	},
	{
		"item": "Card Play Animation",
		"description": "Simple animation when cards are played",
		"impact": "High",
		"effort": "Medium",
		"status": "TODO"
	},
	{
		"item": "Heat Meter Visual",
		"description": "Color-changing meter for heat levels",
		"impact": "High",
		"effort": "Medium",
		"status": "TODO"
	},
	{
		"item": "Part Attachment Visual",
		"description": "Simple visual when part connects to chassis",
		"impact": "Medium",
		"effort": "Medium",
		"status": "TODO"
	},
	{
		"item": "Combat Hit Indicators",
		"description": "Floating damage numbers and hit flashes",
		"impact": "Medium",
		"effort": "Medium",
		"status": "TODO"
	},
	{
		"item": "Card Tooltips",
		"description": "Detailed tooltips showing card effects",
		"impact": "Medium",
		"effort": "Low",
		"status": "TODO"
	},
	{
		"item": "Background Music",
		"description": "Simple looping soundtrack",
		"impact": "Medium",
		"effort": "Low",
		"status": "TODO"
	}
]

# Risk Log - Potential Issues
# These are sorted by (likelihood * impact) - highest risk first

var risk_log = [
	{
		"risk": "Combat Balancing Issues",
		"description": "Difficulty spikes or trivial encounters due to insufficient testing",
		"likelihood": "High",
		"impact": "High",
		"mitigation": "Create quick balance testing tools; have default 'safe' values that can be quickly reverted to"
	},
	{
		"risk": "Drag/Drop Jank",
		"description": "Drag and drop operations feel clunky or unresponsive",
		"likelihood": "High",
		"impact": "High",
		"mitigation": "Implement with priority; build test scene specifically for drag/drop refinement"
	},
	{
		"risk": "Performance with Multiple Effects",
		"description": "Slowdown when many card effects trigger simultaneously",
		"likelihood": "Medium",
		"impact": "High",
		"mitigation": "Queue and space out effect processing; limit simultaneous visual effects"
	},
	{
		"risk": "Unclear Heat Consequences",
		"description": "Players don't understand heat mechanics or consequences",
		"likelihood": "Medium",
		"impact": "High",
		"mitigation": "Clear UI indicators; tutorial tooltips; visual warning effects"
	},
	{
		"risk": "Overwhelmed New Players",
		"description": "Too many mechanics introduced at once",
		"likelihood": "Medium",
		"impact": "Medium",
		"mitigation": "Simple first encounter; progressive complexity; tooltips"
	},
	{
		"risk": "Data Loading Failures",
		"description": "JSON/CSV parsing errors or missing data",
		"likelihood": "Low",
		"impact": "High",
		"mitigation": "Add error checking and fallback data; unit test the data loading"
	},
	{
		"risk": "Save State Corruption",
		"description": "Loss of progress due to save failures",
		"likelihood": "Low",
		"impact": "High",
		"mitigation": "Backup save files; validate save data before writing"
	}
]

# Feature Deferral List
# Lower priority features that can be cut if time runs out

var feature_deferral = [
	{
		"feature": "Advanced Tutorial",
		"impact_if_cut": "Low",
		"alternative": "Simple text tooltips"
	},
	{
		"feature": "Multiple Robot Chassis Options",
		"impact_if_cut": "Low", 
		"alternative": "Single chassis with clear upgrade paths"
	},
	{
		"feature": "Achievement System",
		"impact_if_cut": "Low",
		"alternative": "None needed for prototype"
	},
	{
		"feature": "Advanced Card Interactions",
		"impact_if_cut": "Medium",
		"alternative": "Simpler card effects with clear utility"
	},
	{
		"feature": "Enemy AI Variety",
		"impact_if_cut": "Medium",
		"alternative": "Basic follow/attack patterns with speed/damage variation"
	}
]

# Test Cases - Critical Functions
# Core functionality that must be tested

var test_cases = [
	{
		"function": "Card Drawing",
		"test": "Draw cards up to hand limit; ensure correct types are drawn"
	},
	{
		"function": "Part Attachment",
		"test": "Drag parts to robot; ensure correct stats are applied"
	},
	{
		"function": "Heat Generation",
		"test": "Use high-heat cards; verify heat increases correctly"
	},
	{
		"function": "Heat Consequences",
		"test": "Reach heat threshold; verify penalties are applied"
	},
	{
		"function": "Combat Resolution",
		"test": "Run complete combats; verify damage calculations"
	},
	{
		"function": "Durability",
		"test": "Use parts until durability depletes; verify they break"
	},
	{
		"function": "Enemy Behavior",
		"test": "Verify each enemy follows its behavior pattern"
	},
	{
		"function": "Encounter Progression",
		"test": "Complete encounters; verify difficulty scaling"
	}
]

# Implementation Plan - Jam Timeline

var jam_timeline = [
	{
		"timeframe": "Day 1 - First 8 Hours",
		"goals": ["Complete design doc", "Set up Godot project", "Create core classes", "Implement data loading"]
	},
	{
		"timeframe": "Day 1 - Second 8 Hours",
		"goals": ["Implement card system", "Build robot part attachment", "Create combat mechanics", "Implement basic UI"]
	},
	{
		"timeframe": "Day 2 - First 8 Hours",
		"goals": ["Implement enemy AI", "Build combat resolver", "Create heat mechanics", "Test core gameplay loop"]
	},
	{
		"timeframe": "Day 2 - Second 8 Hours",
		"goals": ["Polish highest impact items", "Fix critical bugs", "Add basic sound/visuals", "Package for submission"]
	}
]

func _ready():
	print("Polish Checklist and Risk Log loaded")
	# This file serves as documentation but can also be used
	# as a runtime checklist if needed
