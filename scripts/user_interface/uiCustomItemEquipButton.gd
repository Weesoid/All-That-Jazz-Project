extends ItemSlot
class_name EquipSlot

@onready var durability = $Durability
@export var combatant:ResPlayerCombatant
@export_range(-1,2) var slot:int

func setCombatant(p_combatant:ResPlayerCombatant):
	combatant = p_combatant
	durability.hide()
	if slot >= 0:
		setItem(combatant.charms[slot])
	else:
		setItem(combatant.equipped_weapon)

func setItem(data: ResItem):
	if item != null:
		item_replaced.emit(item)
	item = data
	if data != null:
		icon = data.icon
		description_text = data.getInformation()
	else:
		icon = empty_icon
		description_text = ''
	if data is ResWeapon: durability.show()

func _get_drag_data(at_position):
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
	return ((slot != -1 and data is ResCharm and !combatant.hasCharm(data) and InventoryGlobals.getCharms(data).size() > 0) or (slot == -1 and data is ResWeapon and data.canUse(combatant)))

func _drop_data(_at_position, data):
	durability.hide()
	var previous_item=item
	setItem(data)
	
	if data is ResCharm:
		combatant.equipCharm(data,slot)
	elif data is ResWeapon:
		combatant.equipWeapon(data)
		durability.setWeapon(data)
		durability.show()
	
	drop_feedback()
	item_received.emit(item, previous_item)
