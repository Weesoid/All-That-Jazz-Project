extends Button
class_name CustomButton

@onready var audio_player = $AudioStreamPlayer
@export var description_text: String
@export var description_offset: Vector2= Vector2.ZERO
@export var focused_entered_sound: AudioStream = preload("res://audio/sounds/421465__jaszunio15__click_5.ogg")
@export var click_sound: AudioStream = preload("res://audio/sounds/421469__jaszunio15__click_149.ogg")

var random_pitch = 0.1

func _on_focus_entered():
	if focused_entered_sound == null: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = focused_entered_sound
	audio_player.play()
	if Input.is_action_pressed("ui_select_arrow") and description_text != '':
		print('blud')
		showDescription()

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
	if Input.is_action_pressed("ui_select_arrow") and description_text != '':
		showDescription()
	grab_focus()

func _on_mouse_exited():
	if has_node('ButtonDescription'):
		get_node('ButtonDescription').remove()

func _input(_event):
	if Input.is_action_just_pressed("ui_select_arrow") and has_focus() and description_text != '':
		showDescription()

func showDescription():
	var side_description = load("res://scenes/user_interface/ButtonDescription.tscn").instantiate()
	add_child(side_description)
	side_description.showDescription(description_text, description_offset)



