extends CanvasLayer

# Help system that shows tutorial screens with highlighted areas and explanations

# References to UI elements
@onready var help_button = $HelpButton
@onready var help_panel = $HelpPanel
@onready var dark_overlay = $DarkOverlay
@onready var highlight_rect = $HighlightRect
@onready var explanation_panel = $ExplanationPanel
@onready var title_label = $ExplanationPanel/TitleLabel
@onready var explanation_text = $ExplanationPanel/ExplanationText
@onready var progress_label = $ExplanationPanel/ProgressLabel
@onready var next_button = $ExplanationPanel/NextButton

# Tutorial data - positions should be adjusted based on actual UI layout
var tutorial_steps = [
	{
		"title": "Building Your Bot",
		"text": "Add parts to the Frame to build your bot. Parts have Energy, Heat, Durability.",
		"highlight_rect": Rect2(326,52,335,370),  # Position for the robot frame
		"step": 0
	},
	{
		"title": "Energy Management",
		"text": "Energy from parts a frame can only charge so much (unless modified by parts).",
		"highlight_rect": Rect2(40, 50, 100, 360),  # Position for the energy bar
		"step": 1
	},
	{
		"title": "Heat Management",
		"text": "Heat from newly added parts. Heavier parts need more heat to be built on a frame.",
		"highlight_rect": Rect2(135, 55, 200, 360),  # Position for the heat bar
		"step": 2
	},
	{
		"title": "Scrapper",
		"text": "If it isn't hot enough (because of amount of heat on your build), add spare parts to scrapper, use durability to heat up the forge.",
		"highlight_rect": Rect2(227,275, 112, 133),  # Position for the scrapper
		"step": 3
	},
	{
		"title": "Durability",
		"text": "Durability lowers in battles of from using the scrapper. Parts don't last forever.",
		"highlight_rect": Rect2(223, 566, 730, 60),  # Position for durability indicator
		"step": 4
	},
	{
		"title": "Work In Progress",
		"text": "(WiP) - Parts will be welded on frame, and require 2 heat to clear the frame of parts (or wait for them to break).",
		"highlight_rect": Rect2(326,52,335,370),  # Position for the robot frame again
		"step": 5
	},
	{
		"title": "Build and Combat",
		"text": "Once you're confident with your bot, start the combat and fight your next Enemy!",
		"highlight_rect": Rect2(995,3,153,50),  # Position for the robot frame again
		"step": 6
	}
]

var current_step = -1  # Start with no step active

func _ready():
	# Hide the help panel initially
	help_panel.visible = false
	dark_overlay.visible = false
	highlight_rect.visible = false
	explanation_panel.visible = false
	
	# Connect signals
	help_button.pressed.connect(_on_help_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	
	# Make the dark overlay clickable
	var dark_overlay_button = Button.new()
	dark_overlay_button.flat = true
	dark_overlay_button.size = dark_overlay.size
	dark_overlay_button.modulate.a = 0  # Transparent but still clickable
	dark_overlay_button.pressed.connect(_on_next_button_pressed)
	dark_overlay.add_child(dark_overlay_button)

# Show the help button in the top left
func show_help_button():
	help_button.visible = true

# Hide the help button
func hide_help_button():
	help_button.visible = false

# Start the help tutorial
func start_tutorial():
	current_step = -1
	_on_next_button_pressed()  # Show the first step

# Show the next tutorial step
func _on_next_button_pressed():
	current_step += 1
	
	# Check if we reached the end of the tutorial
	if current_step >= tutorial_steps.size():
		_hide_tutorial()
		return
	
	# Otherwise show the current step
	_show_tutorial_step(current_step)

# Show a specific tutorial step
func _show_tutorial_step(step_index):
	var step = tutorial_steps[step_index]
	
	# Show the darkened overlay
	dark_overlay.visible = true
	
	# Set up and show the highlight rectangle
	highlight_rect.position = step["highlight_rect"].position
	highlight_rect.size = step["highlight_rect"].size
	highlight_rect.visible = true
	
	# Update the title and explanation text
	title_label.text = step["title"]
	explanation_text.text = step["text"]
	
	# Update the progress indicator
	progress_label.text = str(step_index + 1) + "/" + str(tutorial_steps.size())
	
	# Show the explanation panel
	explanation_panel.visible = true

# Hide the entire tutorial
func _hide_tutorial():
	help_panel.visible = false
	dark_overlay.visible = false
	highlight_rect.visible = false
	explanation_panel.visible = false
	current_step = -1

# When help button is pressed
func _on_help_button_pressed():
	help_panel.visible = true
	start_tutorial()
