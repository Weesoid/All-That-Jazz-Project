extends Control
class_name GameMenu

@onready var tabs = $TabContainer
@onready var sheet = $TabContainer/CHARACTER/CharacterSheet
@onready var character_slots = $CharSlots
var original_pos:Vector2

func _ready():
	$TabContainer/INVENTORY/MiniInventory.showItems()
	loadParty()
	await get_tree().process_frame
	original_pos = position
	showTween()

func showTween():
	modulate = Color.TRANSPARENT
	var tween = create_tween().set_parallel()
	position = original_pos + Vector2(0,32)
	tween.tween_property(self,'position',original_pos,0.25)
	tween.tween_property(self, 'modulate', Color.WHITE, 0.3)

func loadParty():
	resetSlots()
	await get_tree().process_frame
	var squad = OverworldGlobals.getCombatantSquad('Player')
	for character in squad:
		var charact = UIGlobals.createCharacterButton(character)
		if character.assigned_position == -1:
			getFirstEmptySlot().addCharacter(charact)
		else:
			getSlot(character.assigned_position).addCharacter(charact)
		charact.character_presssed.connect(sheet.setCombatant)
	
	sheet.setCombatant(squad[0])

func getFirstEmptySlot():
	for slot in character_slots.get_children():
		if slot.character_button_container.get_children().size()!=0: continue
		return slot

func getSlot(pos:int):
	for slot in character_slots.get_children():
		if slot.formation_position != pos: continue
		return slot

func resetSlots():
	for slot in character_slots.get_children():
		slot.reset()

func _unhandled_input(_event):
	if Input.is_action_just_pressed('ui_tab_right') and tabs.current_tab + 1 < tabs.get_tab_count():
		tabs.current_tab += 1
	elif Input.is_action_just_pressed('ui_tab_left') and tabs.current_tab - 1 >= 0:
		tabs.current_tab -= 1
