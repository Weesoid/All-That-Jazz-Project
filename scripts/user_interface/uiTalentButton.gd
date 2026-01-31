extends CustomButton
class_name CustomTalentButton

@onready var talent_icon = $TextureRect
@onready var icon_animator = $TextureRect/AnimationPlayer
@onready var description_label = $PanelContainer/RichTextLabel
@onready var description_panel = $PanelContainer
@onready var description_animator = $PanelContainer/AnimationPlayer
@onready var charges = $TextureRect/Charges

@export var combatant: ResPlayerCombatant
@export var talent: ResTalent
@export var descriptions: Dictionary = {
	'title': '',
	'description': '',
	'icon': preload("res://images/talent_icons/default.png")
}
@export var custom_charge: int = -1
@export var outside_combat: bool = true


#func _init(p_talent:ResTalent, p_combtant:ResPlayerCombatant):
#	talent = p_talent
#	combatant = p_combtant

func _ready():
	if talent == null:
		return
	$TextureRect/HoldProgress.modulate=hold_color
	updateRank()
	talent_icon.texture = talent.icon
	if disabled:
		talent_icon.modulate = Color.DIM_GRAY
	if outside_combat:
		custom_minimum_size = Vector2(48,48)
		talent_icon.size = Vector2(24,24)
		talent_icon.set_anchors_preset(Control.PRESET_CENTER)

func updateRank():
	if combatant.active_talents.has(talent):
		var current_rank = combatant.active_talents[talent]
		charges.text = str(current_rank)+'/'+str(talent.max_rank)
		if current_rank >= talent.max_rank:
			charges.modulate = Color.YELLOW
		else:
			charges.modulate = Color.WHITE
	else:
		charges.modulate = Color.DIM_GRAY
		charges.text = str('0/'+str(talent.max_rank))

func _on_pressed():
	press_feedback()
	icon_animator.play('Pressed')

func _on_focus_entered():
	focus_feedback()
	if Input.is_action_pressed("ui_select_arrow") and has_focus(): 
		showDescription()

func _on_mouse_entered():
	focus_feedback()
	if focus_mode != Control.FOCUS_NONE:
		grab_focus()
	if Input.is_action_pressed("ui_select_arrow") and has_focus(): 
		
		showDescription()

func _on_mouse_exited():
	exit_focus_feedback()

func _on_focus_exited():
	exit_focus_feedback()

func _input(_event):
	if Input.is_action_just_pressed("ui_select_arrow") and !description_panel.visible and has_focus():
		showDescription()
	if Input.is_action_just_released("ui_select_arrow") and description_panel.visible:
		hideDescription()
	
	checkHoldInputs()

func showDescription():
	if description_label.text.replace('\n','') == '':
		return
	
	if outside_combat:
		var side_description = load("res://scenes/user_interface/ButtonDescription.tscn").instantiate()
		add_child(side_description)
		side_description.showDescription('[center]'+talent.getRichDescription(), Vector2(128,32))
	else:
		description_panel.show()
		description_animator.play("ShowDescription")

func hideDescription():
	description_animator.play_backwards("ShowDescription")
	await description_animator.animation_finished
	description_panel.hide()

func dimButton():
	if talent_icon != null:
		talent_icon.modulate = Color.DIM_GRAY

func undimButton():
	if talent_icon != null:
		talent_icon.modulate = Color.WHITE

func _on_visibility_changed():
	if talent_icon != null:
		talent_icon.self_modulate = Color.WHITE

func focus_feedback():
	if focused_entered_sound == null or focus_mode == FOCUS_NONE: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = focused_entered_sound
	audio_player.play()
	
	z_index = 99
	if outside_combat:
		talent_icon.self_modulate = Color.YELLOW
	else:
		icon_animator.play("Focus")

func exit_focus_feedback():
	delay_timer.stop()
	if hold_time > 0 and audio_player.stream == hold_sound:
		hold_timer.stop()
		audio_player.stop()
	if has_node('ButtonDescription'):
		get_node('ButtonDescription').remove()
	z_index = 0
	icon_animator.play('RESET')
	if description_panel.visible: 
		hideDescription()

func setDisabled(set_to:bool):
	if set_to:
		dimButton()
		disabled=true
		#mouse_filter = Control.MOUSE_FILTER_IGNORE
		#focus_mode = Control.FOCUS_NONE
	else:
		undimButton()
		disabled=false
		#mouse_filter = Control.MOUSE_FILTER_STOP
		#focus_mode = Control.FOCUS_ALL

func press_feedback():
	if click_sound == null: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = click_sound
	audio_player.play()
	pulseSize()

func pulseSize():
	var size_tween = create_tween()
	size_tween.tween_property(talent_icon, 'scale', Vector2(1.5,1.5),0.05).set_ease(Tween.EASE_IN)
	size_tween.tween_property(talent_icon, 'scale', Vector2(1.0,1.0),0.1).set_ease(Tween.EASE_OUT)
