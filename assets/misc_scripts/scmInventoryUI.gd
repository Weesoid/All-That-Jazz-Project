# TO-DO: GENERAL QUALITY CONTROL
extends Control

@onready var use_container = $UseContainer
@onready var party_panel = $PartyPanel/ScrollContainer/VBoxContainer
@onready var misc_tab = $TabContainer/Misc/ScrollContainer/VBoxContainer
@onready var weapon_tab = $TabContainer/Weapons/ScrollContainer/VBoxContainer
@onready var armor_tab = $TabContainer/Armors/ScrollContainer/VBoxContainer
@onready var use_button = $UseContainer/Use
@onready var description_panel = $DescriptionPanel/DescriptionLabel
@onready var stat_panel = $StatPanel/DescriptionLabel

var selected_item: ResItem
var selected_combatant: ResCombatant
var button_item_map: Dictionary

func _on_ready():
	$TabContainer/Misc.grab_focus()
	for item in PlayerGlobals.INVENTORY:
		var button = Button.new()
		button.size.x = 272
		button.text = str(item)
		addButtonToTab(item, button)

func _on_use_pressed():
	if selected_item is ResProjectileAmmo:
		selected_item.equip()
		use_container.hide()
	else:
		use_container.hide()
		addMembers()

func addMembers():
	clearMembers()
		
	for member in OverworldGlobals.getCombatantSquad('Player'):
		var button = Button.new()
		button.size.x = 272
		button.text = member.NAME
		button.pressed.connect(func setSelectedCombatant(): selected_combatant = member)
		button.pressed.connect(
					func useItem():
						if selected_item.EQUIPPED_COMBATANT == member:
							PlayerGlobals.getItemFromInventory(selected_item).unequip()
							button_item_map[selected_item].text = selected_item.NAME
						elif isMemberEquipped(member, selected_item):
							updateButtonUnequip(member, selected_item)
							equipMemberAndUpdateButton(member, selected_item)
						else:
							PlayerGlobals.getItemFromInventory(selected_item).equip(member)
							equipMemberAndUpdateButton(member, selected_item)
						
						for child in party_panel.get_children():
							child.queue_free()
						use_container.hide()
						)
		party_panel.add_child(button)

func isMemberEquipped(member: ResCombatant, slot: ResItem):
	if slot is ResWeapon:
		return member.EQUIPMENT['weapon'] != null
	elif slot is ResArmor:
		if slot.SLOT == 1: 
			return member.EQUIPMENT['armor'] != null
		else:
			return member.EQUIPMENT['charm'] != null

func updateButtonUnequip(member: ResCombatant, item:ResItem):
	if item is ResWeapon:
		button_item_map[member.EQUIPMENT['weapon']].text = member.EQUIPMENT['weapon'].NAME
	elif item is ResArmor:
		if item.SLOT == 1: 
			button_item_map[member.EQUIPMENT['armor']].text = member.EQUIPMENT['armor'].NAME
		else:
			button_item_map[member.EQUIPMENT['charm']].text = member.EQUIPMENT['charm'].NAME

func equipMemberAndUpdateButton(member: ResCombatant, item: ResItem):
	PlayerGlobals.getItemFromInventory(item).equip(member)
	button_item_map[item].text = item.NAME
	button_item_map[item].text += str(" equipped by ", member)

func clearMembers():
	for child in party_panel.get_children():
		child.free()

func _on_drop_pressed():
	if !selected_item is ResStackItem:
		PlayerGlobals.INVENTORY.erase(selected_item)
		button_item_map[selected_item].queue_free()
		selected_item = null
		use_container.hide()
	else:
		selected_item.take(1)
		button_item_map[selected_item].text = str(selected_item)
		if selected_item.STACK <= 0:
			button_item_map[selected_item].queue_free()
			selected_item = null
			use_container.hide()
	
	print(PlayerGlobals.INVENTORY)
	
func isEquipped(item):
	if item is ResConsumable:
		return false
	
	if PlayerGlobals.getItemFromInventory(item).EQUIPPED_COMBATANT != null:
		return true
	else:
		return false

func addButtonToTab(item: ResItem, button: Button):
	button_item_map[item] = button
	if item is ResStackItem:
		misc_tab.add_child(button)
	elif item is ResWeapon:
		if item.EQUIPPED_COMBATANT != null:
			button.text += str(" equipped by ", item.EQUIPPED_COMBATANT)
		weapon_tab.add_child(button)
	elif item is ResArmor:
		if item.EQUIPPED_COMBATANT != null:
			button.text += str(" equipped by ", item.EQUIPPED_COMBATANT)
		armor_tab.add_child(button)
	
	button.pressed.connect(
		func setSelectedItem(): 
			clearMembers()
			showUseContainer(item)
			selected_item = PlayerGlobals.getItemFromInventory(item)
			updateItemInfo(item)
			)
	#button.focus_exited.connect(
	#	func clearInfo():
	#		description_panel.text = ""
	#		stat_panel.text = ""
	#		)

func showUseContainer(item: ResItem):
	use_button.show()
	
	if item is ResWeapon or item is ResArmor:
		use_button.text = "Equip/Unequip"
	elif item is ResProjectileAmmo:
		use_button.text = "Equip Arrow"
	elif item is ResConsumable:
		use_button.text = "Use"
	else:
		use_button.hide()
	
	use_container.show()

func isItemEquippable(item: ResItem):
	return item is ResArmor or item is ResWeapon or item is ResProjectileAmmo

func updateItemInfo(item: ResItem):
	description_panel.text = item.DESCRIPTION
	if isItemEquippable(item) and !item is ResProjectileAmmo:
		stat_panel.text = item.getStringStats()


func _on_tab_container_tab_changed(_tab):
	selected_item = null
	selected_combatant = null
	clearMembers()
	use_container.hide()
	description_panel.text = ""
	stat_panel.text = ""
