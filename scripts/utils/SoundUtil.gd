extends Node
# This file exists for backward compatibility
# Use Sound autoload directly instead

func _ready():
	push_warning("SoundUtil is deprecated. Please use Sound autoload directly.")
	
func play(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0):
	Sound.play(sound_name, volume_db, pitch_scale)
	
func play_click():
	Sound.play_click()
	
func play_hover():
	Sound.play_hover()
