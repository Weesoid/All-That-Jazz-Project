extends Button
class_name KeybindButton

@onready var audio_player = $AudioStreamPlayer
@onready var action_label = $MarginContainer/HBoxContainer/Action
@onready var input_label = $MarginContainer/HBoxContainer/Input
@export var focused_entered_sound: AudioStream = preload("res://audio/sounds/421465__jaszunio15__click_5.ogg")
@export var click_sound: AudioStream = preload("res://audio/sounds/421469__jaszunio15__click_149.ogg")
var random_pitch = 0.1

func _on_focus_entered():
	if focused_entered_sound == null: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = focused_entered_sound
	audio_player.play()

func _on_pressed():
	if click_sound == null: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = click_sound
	audio_player.play()

func _on_mouse_entered():
	if focused_entered_sound == null: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = focused_entered_sound
	audio_player.play()
