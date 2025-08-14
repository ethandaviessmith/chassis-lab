class_name SoundManager
extends Node

# Audio bus setup
const MASTER_BUS = "Master"
const SFX_BUS = "SFX"
const MUSIC_BUS = "Music"

# Sound effect paths
const SFX_PATH = "res://assets/sfx/"

# Sound effects will be stored here
var sfx = {}

# Define sound effects to load
var sound_definitions = {
	# UI sounds
	"click": "res://assets/sfx/click.mp3",
	"hover": "res://assets/sfx/hover.wav",
	"select": "res://assets/sfx/click.mp3",
	"back": "res://assets/sfx/click.mp3",
	
	# Card sounds
	"card_pickup": "res://assets/sfx/card_pick.mp3",
	"card_place": "res://assets/sfx/card_down.mp3",
	"card_flip": "res://assets/sfx/card_pick.mp3",
	
	# Robot/chassis sounds
	"attach_part": "res://assets/sfx/attach_part.wav",
	"detach_part": "res://assets/sfx/detach_part.wav",
	"robot_complete": "res://assets/sfx/robot_start.mp3",
	"robot_power": "res://assets/sfx/robot_power.wav",
	
	# Combat sounds
	"attack": "res://assets/sfx/hit.mp3",
	"damage": "res://assets/sfx/attack.mp3",
	"shield": "res://assets/sfx/bomb.mp3",
	
	# System sounds
	"error": "res://assets/sfx/bomb.mp3",
	"success": "res://assets/sfx/click.mp3",
	"level_up": "res://assets/sfx/card_draw.mp3",
}

# Sound player nodes
var sound_players = []
var max_players = 16

# Singleton instance
static var instance = null

func _init():
	# Set up singleton pattern
	instance = self

func _ready():
	# Create audio players pool
	for i in range(max_players):
		var player = AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		sound_players.append(player)
	
	# Set up audio buses if they don't exist
	_setup_audio_buses()
	
	# Try to load sound effects
	_load_sound_effects()

# Set up audio buses
func _setup_audio_buses():
	var audio_bus_count = AudioServer.bus_count
	
	# Check if SFX bus exists
	var sfx_bus_idx = AudioServer.get_bus_index(SFX_BUS)
	if sfx_bus_idx == -1:
		# Create SFX bus
		AudioServer.add_bus()
		sfx_bus_idx = audio_bus_count
		AudioServer.set_bus_name(sfx_bus_idx, SFX_BUS)
		AudioServer.set_bus_send(sfx_bus_idx, MASTER_BUS)
		# Set default volume
		AudioServer.set_bus_volume_db(sfx_bus_idx, -5)
	
	# Check if Music bus exists
	var music_bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if music_bus_idx == -1:
		# Create Music bus
		AudioServer.add_bus()
		music_bus_idx = audio_bus_count + 1
		AudioServer.set_bus_name(music_bus_idx, MUSIC_BUS)
		AudioServer.set_bus_send(music_bus_idx, MASTER_BUS)
		# Set default volume
		AudioServer.set_bus_volume_db(music_bus_idx, -10)
		
# Load sound effect files
func _load_sound_effects():
	var dir = DirAccess.open(SFX_PATH)
	
	# Create directory if it doesn't exist
	if dir == null:
		DirAccess.make_dir_recursive_absolute(SFX_PATH)
		print("Created SFX directory: ", SFX_PATH)
		return
	
	# First check which sound files actually exist
	for sound_name in sound_definitions:
		var path = sound_definitions[sound_name]
		var file = FileAccess.file_exists(path)
		
		if file:
			# Load the sound file
			var stream = load(path)
			if stream != null:
				sfx[sound_name] = stream
				print("Loaded sound: ", sound_name, " from ", path)
		else:
			# File doesn't exist, skip it
			print("Sound file not found: ", path)

# Play a sound effect
func play_sound(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0):
	if not sfx.has(sound_name):
		push_warning("SoundManager: Sound '%s' not found" % sound_name)
		return
		
	for player in sound_players:
		if not player.playing:
			player.stream = sfx[sound_name]
			player.volume_db = volume_db
			player.pitch_scale = pitch_scale
			player.play()
			return
	
	# If all players are busy, use the first one (least noticeable)
	sound_players[0].stream = sfx[sound_name]
	sound_players[0].volume_db = volume_db
	sound_players[0].pitch_scale = pitch_scale
	sound_players[0].play()

# Stop all sounds
func stop_all_sounds():
	for player in sound_players:
		if player.playing:
			player.stop()

# Play UI click sound
func play_click():
	play_sound("click", -10.0)

# Play UI hover sound  
func play_hover():
	play_sound("hover", -15.0, 1.2)

# Play card pickup sound
func play_card_pickup():
	play_sound("card_pickup", -8.0)

# Play card place sound
func play_card_place():
	play_sound("card_place", -5.0)

# Play part attachment sound
func play_attach_part():
	play_sound("attach_part", -3.0)

# Play part detachment sound  
func play_detach_part():
	play_sound("detach_part", -5.0)

# Robot power up sound
func play_robot_power():
	play_sound("robot_power", 0.0)

# Error sound
func play_error():
	play_sound("error", -5.0)

# Success sound
func play_success():
	play_sound("success", -3.0)

# Create a global instance if necessary
static func get_instance() -> SoundManager:
	if instance == null:
		instance = SoundManager.new()
	return instance
