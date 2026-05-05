extends CustomDragDropButton
class_name EquipSlot

@export var combatant:ResPlayerCombatant
@export_range(-1,2) var slot:int
@export var empty_icon:Texture = preload("res://images/sprites/icon_charm_trans.png")
@export var drop_sound: AudioStream = preload("res://audio/sounds/421461__jaszunio15__click_46.ogg")
@export var pickup_sound: AudioStream = preload("res://audio/sounds/421418__jaszunio15__click_200.ogg")

var item: ResEquippable
#signal item_dragging(item)
signal item_received(received_item, last_item)

func ready():
	icon = empty_icon
	description_offset = Vector2(0,-32)

func _get_drag_data(at_position):
	if item == null:
		return
		
	var item_copy = item
	set_drag_preview(getPreview())
	if slot != -1 and combatant.charms[slot] != null:
		combatant.unequipCharm(slot)
	elif slot == -1 and combatant.hasEquippedWeapon():
		combatant.unequipWeapon()
	
	setItem(null)
	pick_up_feedback()
	
	return item_copy

func _can_drop_data(_at_position, data):
	return ((slot != -1 and data is ResCharm and !combatant.hasCharm(data) and InventoryGlobals.getCharms(data).size() > 0) or (slot == -1 and data is ResWeapon and data.canUse(combatant)))

func _drop_data(_at_position, data):
	var previous_item=item
	setItem(data)
	
	if data is ResCharm:
		combatant.equipCharm(data,slot)
	elif data is ResWeapon:
		combatant.equipWeapon(data)
	
	drop_feedback()
	item_received.emit(item, previous_item)

func setItem(data: ResEquippable):
	item = data
	if data != null:
		icon = data.icon
		description_text = data.getInformation()
	else:
		icon = empty_icon
		description_text = ''

# TODO Turn this into a reusable func, playButtonSound() or smth
func drop_feedback():
	if focused_entered_sound == null or focus_mode == FOCUS_NONE: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = drop_sound
	audio_player.play()

func pick_up_feedback():
	if focused_entered_sound == null or focus_mode == FOCUS_NONE: return
	audio_player.pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	audio_player.stop()
	audio_player.stream = pickup_sound
	audio_player.play()

#func _notification(what):
#	if what == NOTIFICATION_DRAG_END:
#	if is_drag_successful():
#		print("The item was dropped successfully!")
#	else:
#	    print("The drag was canceled or dropped in an invalid area.")
