extends CustomDragDropButton
class_name CustomCampButton

@onready var action_texture = $ActionTexture
@onready var cross_out_texture = $ActionTexture/TextureRect
@export var combatant: ResPlayerCombatant
signal item_received(item, combatant_recepient)
signal party_wide_item_hovered(item)

func _can_drop_data(_at_position, data):
	if data is ResCampItem:
		showAction(data)
		if data.party_wide: party_wide_item_hovered.emit(data)
	
	return combatant != null and data is ResCampItem and data.canApply(combatant) and (!combatant.isDead() or (combatant.isDead() and data.hasHeal()))

func _drop_data(_at_position, data):
	data.applyEffects(combatant)
	data.take(1)
	item_received.emit(data)
	#print(data.stack)

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
