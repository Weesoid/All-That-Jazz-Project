extends CustomButton
class_name CustomAbilityButton

@onready var ability_icon = $TextureRect
@onready var icon_animator = $TextureRect/AnimationPlayer
@onready var description_label = $PanelContainer/RichTextLabel
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
	if ability != null:
		ability_icon.texture = ability.icon
		description_label.text = ability.getRichDescription(true)
		description_label.hide()
		#print('Cust charge on ', ability, ': ', custom_charge)
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
	#toggle_mode = true

func _on_pressed():
	if click_sound == null: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = click_sound
	audio_player.play()
	ability_icon.self_modulate = Color.WHITE
	icon_animator.play('Pressed')
	#await icon_animator.animation_finished
	#if has_focus(): icon_animator.play("Focus")

func _on_focus_entered():
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
	
	if Input.is_action_pressed("ui_select_arrow"): 
		showDescription()

func _on_mouse_entered():
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
	
	if Input.is_action_pressed("ui_select_arrow"):
		showDescription()
	if focus_mode != Control.FOCUS_NONE:
		grab_focus()

func _on_mouse_exited():
	z_index = 0
	icon_animator.play('RESET')
	if description_label.visible: 
		hideDescription()


func _on_focus_exited():
	z_index = 0
	icon_animator.play('RESET')
	if description_label.visible: 
		hideDescription()

func _input(_event):
	if Input.is_action_just_pressed("ui_select_arrow") and !description_label.visible and has_focus():
		showDescription()
	if Input.is_action_just_released("ui_select_arrow") and description_label.visible:
		hideDescription()

func showDescription():
	if outside_combat:
		var side_description = load("res://scenes/user_interface/ButtonDescription.tscn").instantiate()
		add_child(side_description)
		side_description.showDescription(ability.getRichDescription(), Vector2(12,-28))
	else:
		description_label.show()
		description_animator.play("ShowDescription")

func hideDescription():
	description_animator.play_backwards("ShowDescription")
	await description_animator.animation_finished
	description_label.hide()

func dimButton():
	if ability_icon != null:
		ability_icon.modulate = Color.DIM_GRAY

func undimButton():
	if ability_icon != null:
		ability_icon.modulate = Color.WHITE

func _on_visibility_changed():
	if ability_icon != null:
		ability_icon.self_modulate = Color.WHITE
