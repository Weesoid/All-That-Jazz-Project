@tool
extends CustomButton
class_name CustomTextureButton

@export var texture: Texture: 
	set(p_texture):
		texture = p_texture
		if Engine.is_editor_hint():
			_ready()
@onready var texture_button = $TextureRect

func _ready():
	$TextureRect/HoldProgress.modulate=hold_color
	if texture != null:
		texture_button.texture = texture
		
	custom_minimum_size = texture_button.size/2
	setDisabled(disabled)
	texture_button.set_anchors_preset(Control.PRESET_CENTER)

func focus_feedback():
	if focused_entered_sound == null or focus_mode == FOCUS_NONE: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = focused_entered_sound
	audio_player.play()
	texture_button.self_modulate = Color.YELLOW

func exit_focus_feedback():
	delay_timer.stop()
	if hold_time > 0 and audio_player.stream == hold_sound:
		hold_timer.stop()
		audio_player.stop()
	if has_node('ButtonDescription'):
		get_node('ButtonDescription').remove()
#	texture_button.scale = Vector2(1,1)
#	texture_button.rotation_degrees = 0
	if !has_focus():
		texture_button.self_modulate = Color.WHITE

func dimButton():
	texture_button.modulate = Color(Color.DIM_GRAY, 0.5)

func undimButton():
	texture_button.modulate = Color.WHITE

func setDisabled(set_to: bool):
	disabled = set_to
	if disabled:
		dimButton()
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_NONE
	else:
		undimButton()
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_ALL
