class_name ScreenShake
extends Node

# Export variables for customization
@export var default_duration: float = 0.15
@export var default_strength: float = 4.0
@export var default_decay: float = 2.0  # How quickly the shake effect decays

# Internal variables
var _duration: float = 0.0
var _strength: float = 0.0
var _decay: float = 0.0   # How quickly the shake effect decays
var _shake_offset: Vector2 = Vector2.ZERO

var noise: FastNoiseLite
var noise_y = 0

# Node to shake (should be a parent canvas)
var target_canvas: CanvasItem = null

# Original position of the target
var _original_position: Vector2 = Vector2.ZERO

func _ready():
	# Set up noise for more natural shake
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 20
	noise.fractal_octaves = 1
	
	# Find the parent canvas to shake
	target_canvas = get_parent() if get_parent() is CanvasItem else null
	
	if target_canvas:
		# Store the original position to return to after shaking
		_original_position = target_canvas.position
	else:
		push_warning("ScreenShake: No valid CanvasItem parent found")

func _process(delta):
	# If shake duration is active
	if _duration > 0:
		_duration -= delta
		
		# Shake decays over time
		var current_strength = _strength * pow((_duration / default_duration), _decay)
		
		# Calculate shake offset using noise for more natural movement
		noise_y += 1
		var shake_x = current_strength * noise.get_noise_2d(noise.seed, noise_y)
		var shake_y = current_strength * noise.get_noise_2d(noise.seed * 2, noise_y)
		_shake_offset = Vector2(shake_x, shake_y)
		
		# Apply shake
		if target_canvas:
			target_canvas.position = _original_position + _shake_offset
	else:
		# Reset when done
		if _duration <= 0 and _shake_offset != Vector2.ZERO:
			_shake_offset = Vector2.ZERO
			if target_canvas:
				target_canvas.position = _original_position

# Start shake with default values
func start_shake():
	start_shake_with_params(default_strength, default_duration, default_decay)

# Start shake with custom parameters
func start_shake_with_params(strength: float, duration: float, decay: float = 2.0):
	# Only start if target is valid
	if target_canvas == null:
		return
	
	# Store original position if not already stored
	if _original_position == Vector2.ZERO:
		_original_position = target_canvas.position
	
	# Set shake parameters
	_duration = duration
	_strength = strength
	_decay = decay
	
	# Reset noise for variation
	noise_y = 0
