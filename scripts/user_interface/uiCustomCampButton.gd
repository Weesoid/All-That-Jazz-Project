extends CustomDragDropButton
class_name CustomCampButton

@onready var action_texture = $ActionTexture
@onready var cross_out_texture = $ActionTexture/TextureRect
@onready var empty_gradient = $EmptyGradient
@export var combatant: ResPlayerCombatant
#@export_range(0,3) var rank:int = 0
signal item_received(item, combatant_recepient)
signal party_wide_item_hovered(item)
signal combatant_changed(combatant)


func _can_drop_data(_at_position, data):
	if combatant == null and !data is CharacterButton:
		return false
	
	if data is ResCampItem:
		showAction(data)
		if data.party_wide: party_wide_item_hovered.emit(data)
	
	return (isValidCampItem(data) or isValidCharacterButton(data))

func isValidCampItem(data):
	return data is ResCampItem and data.canApply(combatant) and combatant != null

func isValidCharacterButton(data):
	var current_squad = OverworldGlobals.getCombatantSquad('Player')
	return data is CharacterButton and !current_squad.has(data.combatant) and (combatant == null or !combatant.mandatory) and !data.combatant.isDead()

func _drop_data(_at_position, data):
	if data is ResCampItem:
		data.applyEffects(combatant)
		data.take(1)
		item_received.emit(data)
	elif data is CharacterButton:
		var p_combatant = data.combatant
		PlayerGlobals.addCombatantToSquad(data.combatant, combatant)
		combatant = p_combatant
		combatant_changed.emit(p_combatant)
		#print(OverworldGlobals.getCombatantSquad('Player'))
	updateGradient()

func updateGradient():
	empty_gradient.visible = combatant == null

func focus_feedback():
	if focused_entered_sound != null and focus_mode != FOCUS_NONE:
		playSound(focused_entered_sound)

func showAction(item:ResCampItem):
	if combatant == null:
		return
	
	if item == null:
		action_texture.texture = null
		#action_texture_animator.play_backwards("Show")
		action_texture.hide()
		return
	
	action_texture.texture = item.icon
	#action_texture_animator.play("Show")
	action_texture.show()
	if item.canApply(combatant):
		cross_out_texture.hide()
	else:
		cross_out_texture.show()

func exit_focus_feedback():
	delay_timer.stop()
	if hold_time > 0 and audio_player.stream == hold_sound:
		hold_timer.stop()
		audio_player.stop()
	if has_node('ButtonDescription'):
		get_node('ButtonDescription').remove()
	showAction(null)

func test():
	print(combatant)

#func _unhandled_input(event):
#	if Input.is_action_just_pressed("ui_alternate_cancel") and has_focus():
#

func _on_tree_entered():
	pass
	#$EmptyGradient/AnimationPlayer.play('Loop')
