extends CustomButton
class_name CustomAbilityButton

@onready var ability_icon = $TextureRect
@onready var icon_animator = $TextureRect/AnimationPlayer
@onready var description_label = $PanelContainer/RichTextLabel
@onready var description_panel = $PanelContainer
@onready var description_animator = $PanelContainer/AnimationPlayer
@onready var charges = $TextureRect/Charges

@export var ability: ResAbility
@export var descriptions: Dictionary = {
	'title': '',
	'description': '',
	'icon': preload("res://images/ability_icons/default.png")
}
@export var custom_charge: int = -1
@export var outside_combat: bool = false

func _ready():
	$TextureRect/HoldProgress.modulate=hold_color
	if ability != null:
		ability_icon.texture = ability.icon
		description_label.text = ability.getRichDescription(true)
		description_panel.hide()
		if custom_charge > -1:
			charges.text = str(custom_charge)
			charges.show()
		elif ability.charges > 0:
			if !outside_combat:
				charges.text = str(CombatGlobals.getCombatScene().getChargesLeft(CombatGlobals.getCombatScene().active_combatant, ability))
			else:
				charges.text = str(ability.charges)
			charges.show()
		if disabled:
			ability_icon.modulate = Color.DIM_GRAY
		if outside_combat:
			custom_minimum_size = Vector2(48,48)
			ability_icon.size = Vector2(24,24)
			ability_icon.set_anchors_preset(Control.PRESET_CENTER)
	else:
		description_label.text = descriptions['title'].to_upper()+'\n'+descriptions['description']
		ability_icon.texture = descriptions['icon']

func setDisabled(set_to:bool):
	if set_to:
		dimButton()
		disabled=true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		undimButton()
		disabled=false
		mouse_filter = Control.MOUSE_FILTER_STOP

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
		side_description.showDescription(ability.getRichDescription(), Vector2(128,32))
	else:
		description_panel.show()
		description_animator.play("ShowDescription")

func hideDescription():
	description_animator.play_backwards("ShowDescription")
	await description_animator.animation_finished
	description_panel.hide()

func dimButton():
	if ability_icon != null:
		ability_icon.modulate = Color.DIM_GRAY

func undimButton():
	if ability_icon != null:
		ability_icon.modulate = Color.WHITE

func _on_visibility_changed():
	if ability_icon != null:
		ability_icon.self_modulate = Color.WHITE

func focus_feedback():
	if focused_entered_sound == null or focus_mode == FOCUS_NONE: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = focused_entered_sound
	audio_player.play()
	
	z_index = 99
	if outside_combat:
		ability_icon.self_modulate = Color.YELLOW
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
