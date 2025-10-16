extends CustomTextureButton
class_name CustomCharacterButton

@export var character: ResPlayerCombatant
@onready var character_portrait = $TextureRect/TextureRect
@onready var character_frame = $TextureRect

func _ready():
	if character == null:
		character_portrait.modulate = Color(Color.DARK_GRAY,0.5)
		return
	
	$TextureRect/HoldProgress.modulate=hold_color
	character_portrait.texture = character.rest_sprite
	character_portrait.modulate = Color(Color.DARK_GRAY,0.5)

func focus_feedback():
	if focused_entered_sound == null or focus_mode == FOCUS_NONE: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = focused_entered_sound
	audio_player.play()
	character_frame.self_modulate = Color.YELLOW
	character_portrait.modulate = Color.WHITE

func exit_focus_feedback():
	delay_timer.stop()
	if hold_time > 0 and audio_player.stream == hold_sound:
		hold_timer.stop()
		audio_player.stop()
	if has_node('ButtonDescription'):
		get_node('ButtonDescription').remove()
	if !has_focus():
		character_frame.self_modulate = Color.WHITE
		character_portrait.modulate = Color(Color.DARK_GRAY,0.5)

func dimButton():
	texture_button.modulate = Color(Color.DIM_GRAY, 0.5)

func undimButton():
	texture_button.modulate = Color.WHITE

func setDisabled(set_to: bool):
	disabled = set_to
	if disabled:
		dimButton()
	else:
		undimButton()
