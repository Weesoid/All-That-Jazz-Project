# TO-DO: GENERAL QUALITY CONTROL
extends Control

@onready var use_container = $UseContainer
@onready var party_panel = $PartyPanel/ScrollContainer/VBoxContainer
@onready var misc_tab = $TabContainer/Misc
@onready var weapon_tab = $TabContainer/Weapons/ScrollContainer/VBoxContainer
@onready var armor_tab = $TabContainer/Armors
@onready var use_button = $UseContainer/Use
@onready var description_panel = $DescriptionPanel/DescriptionLabel
@onready var stat_panel = $StatPanel/DescriptionLabel

var selected_item: ResItem
var selected_combatant: ResCombatant

func _on_ready():
	misc_tab.grab_focus()
	for item in PlayerGlobals.INVENTORY:
		var button = Button.new()
		button.size.x = 272
		button.text = str(item)
		if isEquipped(item): button.text = str('EQUIPPED BY ', item.EQUIPPED_COMBATANT)
		addButtonToTab(item, button)

func showUseContainer():
	use_container.show()

func _on_use_pressed():
	if selected_item.EQUIPPED_COMBATANT == selected_combatant:
		PlayerGlobals.getItemFromInventory(selected_item).unequip()
	else:
		PlayerGlobals.getItemFromInventory(selected_item).equip(selected_combatant)

	for child in party_panel.get_children():
		child.free()
	use_container.hide()

func addMembers():
	for child in party_panel.get_children():
		child.free()
		
	for member in OverworldGlobals.getCombatantSquad('Player'):
		var button = Button.new()
		button.size.x = 272
		button.text = member.NAME
		button.pressed.connect(showUseContainer)
		button.pressed.connect(func setSelectedCombatant(): selected_combatant = member)
		party_panel.add_child(button)

func _on_drop_pressed():
	print(selected_item)
	
func isEquipped(item):
	if item is ResConsumable:
		return false
	
	if PlayerGlobals.getItemFromInventory(item).EQUIPPED_COMBATANT != null:
		return true
	else:
		return false

func addButtonToTab(item: ResItem, button: Button):
	if item is ResConsumable:
		misc_tab.add_child(button)
	elif item is ResWeapon:
		weapon_tab.add_child(button)
	elif item is ResArmor:
		armor_tab.add_child(button)
	
	button.pressed.connect(
		func setSelectedItem(): 
			selected_item = PlayerGlobals.getItemFromInventory(item)
			description_panel.text = item.DESCRIPTION
			if !selected_item is ResConsumable:
				stat_panel.text = item.getStringStats()
			addMembers()
			)
	
