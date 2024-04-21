extends Button
class_name CustomButton

@onready var audio_player = $AudioStreamPlayer

var random_pitch = 0.1
var focused_entered_sound: AudioStream = preload("res://audio/sounds/567054__sheyvan__clicking-skateboard-wheel.ogg")
var click_sound: AudioStream = preload("res://audio/sounds/524232__sheyvan__button-clicking-9.ogg")

func _on_focus_entered():
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = focused_entered_sound
	audio_player.play()

func _on_pressed():
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = click_sound
	audio_player.play()

func _on_mouse_entered():
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = focused_entered_sound
	audio_player.play()
