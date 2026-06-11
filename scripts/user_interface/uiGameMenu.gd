extends Control
class_name GameMenu

@onready var tabs = $TabContainer
@onready var sheet = $TabContainer/CHARACTER/CharacterSheet
@onready var character_slots = $CharSlots

func _ready():
	$TabContainer/INVENTORY/MiniInventory.showItems()
	var slot:int=0
	var squad = OverworldGlobals.getCombatantSquad('Player')
	for character in squad:
		var char = UIGlobals.createCharacterButton(character)
		if character.assigned_position == -1:
			getFirstEmptySlot().addCharacter(char)
		else:
			getSlot(character.assigned_position).addCharacter(char)
		char.character_presssed.connect(sheet.setCombatant)
	
	sheet.setCombatant(squad[0])

func getFirstEmptySlot():
	for slot in character_slots.get_children():
		if slot.character_button_container.get_children().size()!=0: continue
		return slot

func getSlot(pos:int):
	for slot in character_slots.get_children():
		if slot.formation_position != pos: continue
		return slot

func _unhandled_input(_event):
	if Input.is_action_just_pressed('ui_tab_right') and tabs.current_tab + 1 < tabs.get_tab_count():
		tabs.current_tab += 1
	elif Input.is_action_just_pressed('ui_tab_left') and tabs.current_tab - 1 >= 0:
		tabs.current_tab -= 1
