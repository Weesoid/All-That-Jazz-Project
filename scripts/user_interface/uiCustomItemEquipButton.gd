extends ItemSlot
class_name EquipSlot

@onready var durability = $Durability
@export var combatant:ResPlayerCombatant
@export_range(-1,2) var slot:int

func setCombatant(p_combatant:ResPlayerCombatant):
	modulate =Color.WHITE
	combatant = p_combatant
	durability.hide()
	if slot >= 0:
		setItem(combatant.charms[slot])
	else:
		setItem(combatant.equipped_weapon)
		if combatant.equipped_weapon != null: 
			durability.setItem(combatant.equipped_weapon)
			durability.show()
			if combatant.equipped_weapon.canUse(combatant):
				modulate =Color.RED

func _get_drag_data(_at_position):
	modulate = Color.WHITE
	durability.hide()
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
	return combatant != null and ((slot != -1 and data is ResCharm and !combatant.hasCharm(data) and InventoryGlobals.getCharms(data).size() > 0) or (slot == -1 and data is ResWeapon))

func _drop_data(_at_position, data):
	durability.hide()
	modulate =Color.WHITE
	setItem(data)
	
	if data is ResCharm:
		combatant.equipCharm(data,slot)
	elif data.isRepairable():
		combatant.equipWeapon(data)
		durability.setItem(data)
		durability.show()
	if data is ResWeapon and data.canUse(combatant):
		modulate = Color.RED
	
	drop_feedback()
	item_received.emit(item)
	#await get_tree().process_frame
	#grab_focus()

func _input(_event):
	if has_focus() and Input.is_action_pressed("ui_alternate_cancel"):
		setItem(null)
		if slot != -1 and combatant.charms[slot] != null:
			combatant.unequipCharm(slot)
		elif slot == -1 and combatant.hasEquippedWeapon():
			combatant.unequipWeapon()
		modulate =Color.WHITE
