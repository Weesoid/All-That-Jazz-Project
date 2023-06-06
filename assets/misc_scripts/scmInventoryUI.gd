extends Control

@onready var party_panel = $PartyPanel/ScrollContainer/VBoxContainer

var state = 0
var selected_item: ResItem
var selected_combatant: ResCombatant

func _on_ready():
	$TabContainer/Misc.grab_focus()
	for item in PlayerGlobals.INVENTORY.values():
		var button = Button.new()
		if isEquipped(item):
			button.text = str('EQUIPPED BY ', item.EQUIPPED_COMBATANT)
		else:
			button.text = str(item)
		button.size.x = 272
		if item is ResConsumable:
			$TabContainer/Misc.add_child(button)
		elif item is ResWeapon:
			$TabContainer/Weapons.add_child(button)
		elif item is ResArmor:
			$TabContainer/Armors.add_child(button)
		button.pressed.connect(
			func setSelectedItem(): 
				selected_item = PlayerGlobals.INVENTORY[item.NAME] 
				if selected_item is ResArmor or selected_item is ResWeapon:
					$UseContainer/Use.text = "Equip"
				else:
					$UseContainer/Use.text = "Use"
				$DescriptionPanel/DescriptionLabel.text = item.DESCRIPTION
				$StatPanel/DescriptionLabel.text = item.getStringStats()
				addMembers()
				)

func showUseContainer():
	$UseContainer.show()

func _on_use_pressed():
	if selected_item.EQUIPPED_COMBATANT == selected_combatant:
		PlayerGlobals.INVENTORY[selected_item.NAME].unequip(selected_combatant)
	else:
		PlayerGlobals.INVENTORY[selected_item.NAME].equip(selected_combatant)

	for child in party_panel.get_children():
		child.free()
	$UseContainer.hide()

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
	if PlayerGlobals.INVENTORY[item.NAME].EQUIPPED_COMBATANT != null:
		return true
	else:
		return false
