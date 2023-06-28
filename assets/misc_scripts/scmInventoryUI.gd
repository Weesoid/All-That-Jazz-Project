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

func _on_ready():
	$TabContainer/Misc.grab_focus()
	for item in PlayerGlobals.INVENTORY:
		var button = Button.new()
		button.size.x = 272
		button.text = str(item)
		addButtonToTab(item, button)

func showUseContainer():
	description_panel.text = ""
	use_container.show()

func _on_use_pressed():
	if selected_item is ResProjectileAmmo:
		selected_item.equip()
	elif selected_item.EQUIPPED_COMBATANT == selected_combatant:
		PlayerGlobals.getItemFromInventory(selected_item).unequip()
	else:
		PlayerGlobals.getItemFromInventory(selected_item).equip(selected_combatant)

	for child in party_panel.get_children():
		child.free()
	use_container.hide()

func addMembers():
	clearMembers()
		
	for member in OverworldGlobals.getCombatantSquad('Player'):
		var button = Button.new()
		button.size.x = 272
		button.text = member.NAME
		button.pressed.connect(showUseContainer)
		button.pressed.connect(func setSelectedCombatant(): selected_combatant = member)
		party_panel.add_child(button)

func clearMembers():
	for child in party_panel.get_children():
		child.free()

func _on_drop_pressed():
	print(PlayerGlobals.INVENTORY)
	
func isEquipped(item):
	if item is ResConsumable:
		return false
	
	if PlayerGlobals.getItemFromInventory(item).EQUIPPED_COMBATANT != null:
		return true
	else:
		return false

func addButtonToTab(item: ResItem, button: Button):
	if item is ResConsumable or item is ResProjectileAmmo:
		misc_tab.add_child(button)
	elif item is ResWeapon:
		if isEquipped(item): button.text = str('WEAPON EQUIPPED BY ', item.EQUIPPED_COMBATANT)
		weapon_tab.add_child(button)
	elif item is ResArmor:
		if isEquipped(item): button.text = str('ARMOR EQUIPPED BY ', item.EQUIPPED_COMBATANT)
		armor_tab.add_child(button)
	
	button.pressed.connect(
		func setSelectedItem(): 
			clearMembers()
			use_container.hide()
			selected_item = PlayerGlobals.getItemFromInventory(item)
			description_panel.text = item.DESCRIPTION
			if isItemEquippable(item) and !item is ResProjectileAmmo:
				stat_panel.text = item.getStringStats()
			addMembers()
			)
	
func isItemEquippable(item: ResItem):
	return item is ResArmor or item is ResWeapon or item is ResProjectileAmmo
