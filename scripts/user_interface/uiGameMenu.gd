extends Control

@onready var experience_bar = $Experience
@onready var experience_current = $Experience/Label
@onready var level = $Experience/Level
@onready var tabs = $TabContainer
@onready var sheet = $TabContainer/CHARACTER/CharacterSheet
@onready var character_slots = $CharSlots
func _ready():
	experience_bar.max_value = PlayerGlobals.getRequiredExp()
	experience_bar.value = PlayerGlobals.current_exp
	experience_current.text = '%s / %s' % [PlayerGlobals.current_exp, PlayerGlobals.getRequiredExp()]
	level.text =  str(PlayerGlobals.team_level)
	$TabContainer/INVENTORY/MiniInventory.showItems()
	#for combatant in OverworldGlobals.getCombatantSquad('Player'):
	#	var bar = load("res://scenes/user_interface/GeneralCombatantStatus.tscn").instantiate()
	#	general_party_bars.add_child(bar)
	#	bar.combatant = combatant
	#drop_area.item_dropped.connect(sheet.equipment.addButton)
	#grabTabFocus(tabs.current_tab)
	#await get_tree().process_frame
	#print(sheet)
	var slot:int=0
	var squad = OverworldGlobals.getCombatantSquad('Player')
	for character in squad:
		var char = OverworldGlobals.createCharacterButton(character)
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
		#grabTabFocus(tabs.current_tab)
	elif Input.is_action_just_pressed('ui_tab_left') and tabs.current_tab - 1 >= 0:
		tabs.current_tab -= 1
		#grabTabFocus(tabs.current_tab)

#func grabTabFocus(tab:int):
#	var menu = tabs.get_tab_control(tab)
#	if menu.name == 'PARTY':
#		menu = menu.pool
##	elif menu.name == 'INVENTORY':
##		menu = menu.get_child(0).inventory_grid
#	elif menu.name == 'QUESTS':
#		var quests = menu.get_child(0).ongoing_quests
#		if quests.get_children().size() == 1:
#			quests = menu.get_child(0).completed_quests
#		menu = quests
#
#	OverworldGlobals.setControlFocus(menu)
