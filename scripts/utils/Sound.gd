extends Node

# Audio bus setup
const MASTER_BUS = "Master"
const SFX_BUS = "SFX"
const MUSIC_BUS = "Music"

# Sound effect paths
const SFX_PATH = "res://assets/sfx/"

# Volume levels
var master_volume = 1.0
var sfx_volume = 0.8
var music_volume = 0.7  # Default music volume

# Dictionary to store preloaded audio streams
var sfx = {}

# Music players and tracks
var music_player_a: AudioStreamPlayer
var music_player_b: AudioStreamPlayer
var current_music_player = null
var current_music_mode = ""
var fade_tween: Tween = null
var fade_duration = 0.8  # Fade duration in seconds

# Music tracks
const BUILD_MODE_MUSIC = "res://assets/sfx/factory_a.wav"
const COMBAT_MODE_MUSIC = "res://assets/sfx/factory_b.wav"

# Define sound effects to load with paths
var sound_definitions = {
    # UI sounds
    "click": "res://assets/sfx/click.mp3",
    "hover": "res://assets/sfx/hover.wav",
    "select": "res://assets/sfx/click.mp3",
    "back": "res://assets/sfx/click.mp3",
    
    # Card sounds
    "card_pick": "res://assets/sfx/card_pick.mp3",
    "card_pickup": "res://assets/sfx/card_pick.mp3",
    "card_down": "res://assets/sfx/card_down.mp3",
    "card_place": "res://assets/sfx/card_down.mp3",
    "card_draw": "res://assets/sfx/card_draw.mp3",
    "card_flip": "res://assets/sfx/card_pick.mp3",
    "card_discard": "res://assets/sfx/detach_part.wav",  # Using detach sound for discard
    
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

# AudioStreamPlayers for simultaneous sounds
var audio_players = []
var max_players = 16

func _ready():
    # Set up audio buses if they don't exist
    _setup_audio_buses()
    
    # Create audio players pool
    for i in range(max_players):
        var player = AudioStreamPlayer.new()
        player.bus = SFX_BUS
        add_child(player)
        audio_players.append(player)
    
    # Load sound effects
    _load_sound_effects()
    
    # Set up music players
    _setup_music_players()

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
    # Check which sound files exist and preload them
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

# Play a sound effect by name
func play(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0):
    # Check if sound exists in preloaded sounds
    if sfx.has(sound_name):
        # Use preloaded stream
        _play_stream(sfx[sound_name], volume_db, pitch_scale)
    elif sound_definitions.has(sound_name):
        # Try to load on demand
        var path = sound_definitions[sound_name]
        var stream = load(path)
        
        if stream:
            # Cache for future use
            sfx[sound_name] = stream
            _play_stream(stream, volume_db, pitch_scale)
        else:
            push_warning("Failed to load sound: " + path)
    else:
        push_warning("Sound not found: " + sound_name)
        
# Internal method to play a loaded AudioStream
func _play_stream(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0):
    # Find an available player
    for player in audio_players:
        if not player.playing:
            player.stream = stream
            player.volume_db = volume_db
            player.pitch_scale = pitch_scale
            player.play()
            return
            
    # All players busy, use the first one
    audio_players[0].stream = stream
    audio_players[0].volume_db = volume_db
    audio_players[0].pitch_scale = pitch_scale
    audio_players[0].play()

# Stop all sounds
func stop_all_sounds():
    for player in audio_players:
        if player.playing:
            player.stop()

# UI sound convenience methods
func play_click():
    play("click", -10.0)

func play_hover():
    play("hover", -15.0, 1.2)

func play_select():
    play("select", -8.0)
    
func play_back():
    play("back", -10.0)

# Card sound convenience methods
func play_card_pickup():
    play("card_pickup", -8.0)

func play_card_place():
    play("card_place", -5.0)
    
func play_card_draw():
    play("card_draw", -5.0)
    
func play_card_discard():
    play("card_discard", -5.0)

# Robot/chassis sound convenience methods
func play_attach_part():
    play("attach_part", -3.0)

func play_detach_part():
    play("detach_part", -5.0)

func play_robot_power():
    play("robot_power", 0.0)

func play_robot_complete():
    play("robot_complete", -2.0)

# Combat sound convenience methods
func play_attack():
    play("attack", -5.0)

func play_range_attack():
    play("attack", -5.0, 1.2)
    
func play_damage():
    play("damage", -3.0)
    
func play_shield():
    play("shield", -8.0)

# System sound convenience methods
func play_error():
    play("error", -5.0)

func play_success():
    play("success", -3.0)
    
func play_level_up():
    play("level_up", -2.0)

# ---- Music System Functions ----

# Set up the music players
func _setup_music_players():
    # Create the two music players
    music_player_a = AudioStreamPlayer.new()
    music_player_a.bus = MUSIC_BUS
    music_player_a.volume_db = -80.0  # Start silent
    add_child(music_player_a)
    
    music_player_b = AudioStreamPlayer.new()
    music_player_b.bus = MUSIC_BUS
    music_player_b.volume_db = -80.0  # Start silent
    add_child(music_player_b)
    
    # Preload music tracks
    var build_music = load(BUILD_MODE_MUSIC)
    var combat_music = load(COMBAT_MODE_MUSIC)
    
    if build_music:
        music_player_a.stream = build_music
    else:
        push_error("Failed to load build mode music: " + BUILD_MODE_MUSIC)
    
    if combat_music:
        music_player_b.stream = combat_music
    else:
        push_error("Failed to load combat mode music: " + COMBAT_MODE_MUSIC)

# Switch between build and combat music with crossfade
# Will be called by TurnManager when switching game modes
func switch_game_mode_music(mode: String, sync_position: bool = true):
    Log.pr("Sound: Switching game mode music to " + mode)
    # Don't do anything if we're already in this mode
    if mode == current_music_mode:
        return
    
    print("Sound: Switching music to " + mode + " mode")
    
    # Determine which track to play based on mode
    var next_player: AudioStreamPlayer
    
    if mode == "build":
        next_player = music_player_a
    elif mode == "combat":
        next_player = music_player_b
    else:
        push_error("Invalid music mode: " + mode)
        return
    
    # If we have no current music, just start the new one
    if current_music_player == null:
        current_music_player = next_player
        current_music_mode = mode
        next_player.volume_db = linear_to_db(music_volume)

        ## TODO stopped music manually
        # next_player.play()
        return
    
    # Sync playback position if requested
    if sync_position and current_music_player.playing:
        # Get the current playback position
        var current_position = current_music_player.get_playback_position()
        
        # Find beat-aligned position if possible (assuming 4/4 time at 120 BPM)
        var beat_length = 0.5  # 120 BPM = 0.5 seconds per beat
        var beats = round(current_position / beat_length)
        var aligned_position = beats * beat_length
        
        # Start the new track at the aligned position
        next_player.play(aligned_position)
    else:
        # Just start from the beginning
        next_player.play()
    
    # Cancel any existing fade tween
    if fade_tween:
        fade_tween.kill()
    
    # Create new fade tween
    fade_tween = create_tween()
    fade_tween.set_parallel(true)
    
    # Fade out current track
    fade_tween.tween_property(current_music_player, "volume_db", -80.0, fade_duration)
    
    # Fade in new track
    fade_tween.tween_property(next_player, "volume_db", linear_to_db(music_volume), fade_duration)
    
    # Update state
    current_music_player = next_player
    current_music_mode = mode
    
    # Stop the old player after fade completes
    await fade_tween.finished
    if current_music_player != music_player_a:
        music_player_a.stop()
    if current_music_player != music_player_b:
        music_player_b.stop()

# Start playing background music for the specified mode
func start_background_music(mode: String = "build"):
    switch_game_mode_music(mode, false)

# Set music volume (0.0 to 1.0)
func set_music_volume(volume: float):
    music_volume = clamp(volume, 0.0, 1.0)
    
    # Update current player if it exists
    if current_music_player:
        current_music_player.volume_db = linear_to_db(music_volume)
