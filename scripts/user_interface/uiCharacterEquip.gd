extends Control
class_name EquipmentInterface

@onready var unequip_button = $PanelContainer/MarginContainer/ScrollContainer/GridContainer/CustomButton
@onready var equipment = $PanelContainer/MarginContainer/ScrollContainer/GridContainer
@onready var animator = $AnimationPlayer
signal equipped_item
## 0 = Charms, 1 = Weapons
func showEquipment(type:int, combatant: ResPlayerCombatant, slot: int):
	clearButtons()
	var inventory = InventoryGlobals.inventory
	inventory.sort_custom(func(a,b): return a.name < b.name)
	if type == 0:
		for item in inventory.filter(func(item): return item is ResCharm):
			addButton(combatant, item, slot)
			
	elif type == 1:
		for item in inventory.filter(func(item): return item is ResWeapon):
			addButton(combatant, item, slot)
	
	unequip_button.grab_focus()
	animator.play("Show")

func addButton(combatant, item, slot):
	if (item is ResWeapon and !item.canUse(combatant)) or (item is ResCharm and combatant.hasCharm(item)):
		return
	var button = OverworldGlobals.createItemButton(item)
	button.pressed.connect(func(): equipItem(combatant, item, slot))
	equipment.add_child(button)

func equipItem(combatant: ResPlayerCombatant, item: ResItem, slot: int):
	if item is ResCharm:
		combatant.equipCharm(item, slot)
	elif item is ResWeapon:
		combatant.equipWeapon(item)
	equipped_item.emit()
	queue_free()

func clearButtons():
	for i in equipment.get_children().size():
		if i == 0: continue
		equipment.get_children()[i].queue_free()

func _on_custom_button_pressed():
	equipped_item.emit()
	queue_free()
