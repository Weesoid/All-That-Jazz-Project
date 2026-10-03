@tool
extends CustomButton
class_name CustomTextureButton

@export var texture: Texture: 
	set(p_texture):
		if p_texture == null: return
		texture = p_texture
		if Engine.is_editor_hint() and texture != null: texture_button.texture = texture
@export var auto_resize:bool=true
@export var set_toggled:bool=false
@onready var texture_button = $TextureRect

func _ready():
	$TextureRect/HoldProgress.modulate=hold_color
	if texture != null:
		texture_button.texture = texture
	if auto_resize:
		custom_minimum_size = texture_button.size/2
	setDisabled(disabled)
	texture_button.set_anchors_preset(Control.PRESET_CENTER)
	
	setTooltip()
	if button_group != null:
		toggle_mode = true
	if set_toggled and toggle_mode:
		button_pressed = true

func setTexture(tex:Texture):
	texture_button.texture = tex

func getTexture()-> TextureRect:
	return texture_button

func focus_feedback():
	if focused_entered_sound == null or focus_mode == FOCUS_NONE: return
	playSound(focused_entered_sound)

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
	else:
		undimButton()


func _on_toggled(button_pressed):
	if texture_button == null:
		await ready
		print('ERROR! button_pressed is set to true for path: ', get_path())
		return
	texture_button.modulate = SettingsGlobals.ui_colors['up'] if button_pressed else Color.WHITE 
