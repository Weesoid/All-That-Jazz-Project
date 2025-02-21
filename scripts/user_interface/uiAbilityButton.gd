extends CustomButton
class_name CustomAbilityButton

@onready var ability_icon = $TextureRect
@onready var icon_animator = $TextureRect/AnimationPlayer
@onready var description_label = $PanelContainer/RichTextLabel
@onready var description_animator = $PanelContainer/AnimationPlayer

@export var ability: ResAbility
@export var outside_combat: bool = false

func _ready():
	ability_icon.texture = ability.ICON
	description_label.text = ability.getRichDescription(true)
	description_label.hide()
	if disabled:
		ability_icon.modulate = Color.DIM_GRAY
	if outside_combat:
		custom_minimum_size = Vector2(48,48)
		ability_icon.size = Vector2(24,24)
		ability_icon.set_anchors_preset(Control.PRESET_CENTER)
	#toggle_mode = true

func _on_pressed():
	if click_sound == null: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = click_sound
	audio_player.play()
	
	icon_animator.play('Pressed')
	#await icon_animator.animation_finished
	#if has_focus(): icon_animator.play("Focus")

func _on_focus_entered():
	if focused_entered_sound == null: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = focused_entered_sound
	audio_player.play()
	z_index = 99
	if outside_combat:
		ability_icon.self_modulate = Color.YELLOW
	else:
		icon_animator.play("Focus")
	
	
	if Input.is_action_pressed("ui_select_arrow") and !outside_combat: 
		description_label.show()
		description_animator.play("ShowDescription")

func _on_mouse_entered():
	if focused_entered_sound == null: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = focused_entered_sound
	audio_player.play()
	z_index = 99
	if outside_combat:
		ability_icon.self_modulate = Color.YELLOW
	else:
		icon_animator.play("Focus")
	
	if Input.is_action_pressed("ui_select_arrow") and !outside_combat:
		description_label.show()
		description_animator.play("ShowDescription")

func _on_mouse_exited():
	z_index = 0
	icon_animator.play('RESET')
	if description_label.visible: 
		description_animator.play_backwards("ShowDescription")
		await description_animator.animation_finished
		description_label.hide()


func _on_focus_exited():
	z_index = 0
	icon_animator.play('RESET')
	if description_label.visible: 
		description_animator.play_backwards("ShowDescription")
		await description_animator.animation_finished
		description_label.hide()

func _input(event):
	if Input.is_action_just_released("ui_select_arrow") and description_label.visible and !outside_combat:
		description_animator.play_backwards("ShowDescription")
		await description_animator.animation_finished
		description_label.hide()
	if Input.is_action_just_pressed("ui_select_arrow") and !description_label.visible and has_focus() and !outside_combat:
		description_label.show()
		description_animator.play("ShowDescription")
