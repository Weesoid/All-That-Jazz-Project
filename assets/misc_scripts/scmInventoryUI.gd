extends Control

var selected_item

func _on_ready():
	$TabContainer/Misc.grab_focus()
	for item in PlayerGlobals.INVENTORY.values():
		var button = Button.new()
		button.text = str(item)
		button.size.x = 384
		if item is ResConsumable:
			$TabContainer/Misc.add_child(button)
		elif item is ResWeapon:
			button.pressed.connect(showUseContainer)
			$TabContainer/Weapons.add_child(button)
		elif item is ResArmor:
			$TabContainer/Armors.add_child(button)
		button.pressed.connect(func setSelectedItem(): selected_item = PlayerGlobals.INVENTORY[item.NAME])

func showUseContainer():
	$UseContainer.show()

func _on_use_pressed():
	print('Equipping on squad member: ', OverworldGlobals.getCombatantSquad('Player')[0].NAME)
	print('Before:', OverworldGlobals.getCombatantSquad('Player')[0].EQUIPMENT)
	PlayerGlobals.INVENTORY[selected_item.NAME].equip(OverworldGlobals.getCombatantSquad('Player')[0])
	print('After:', OverworldGlobals.getCombatantSquad('Player')[0].EQUIPMENT)

func _on_drop_pressed():
	print(selected_item)
