extends Control
class_name RosterSelector

const CHARACTER_BUTTON = preload("res://scenes/user_interface/CustomCharacterButton.tscn")

@export var char_page: MemberAdjustUI
@onready var member_container = $ScrollContainer/HBoxContainer
@onready var inspecting_label = $Label
@onready var inspect_mark = $InspectIcon
@onready var cancel_button = $ScrollContainer/HBoxContainer/CancelButton
@onready var character_sheet: CharacterSheet = $CharacterSheet
var remove_member:ResPlayerCombatant
signal added_character(character:ResPlayerCombatant)
signal removed_character(character:ResPlayerCombatant)

func _ready():
	loadMembers()

func loadMembers(replace_member: ResPlayerCombatant=null):
	character_sheet.hide()
	for child in member_container.get_children():
		if child == cancel_button: continue
		child.queue_free()
	await get_tree().process_frame
	var team = PlayerGlobals.team
	for member in team:
		var member_button: CustomCharacterButton = CHARACTER_BUTTON.instantiate()
		member_button.character = member
		member_container.add_child(member_button)
		member_button.setDisabled(OverworldGlobals.getCombatantSquad('Player').has(member))
		member_button.pressed.connect(addToActive.bind(member,replace_member),CONNECT_ONE_SHOT)
		member_button.held_press.connect(func(): character_sheet.showCharacter(member))
		member_button.hold_time = 0.25
		member_button.description_text = member.description
		member_button.hold_ignore_disabled = true
	if replace_member != null:
		remove_member = replace_member

func addToActive(member: ResPlayerCombatant, replace_member:ResPlayerCombatant=null):
	print('rep: %s w %s'% [replace_member, member])
	if OverworldGlobals.getCombatantSquad('Player').size() == 4 and !OverworldGlobals.getCombatantSquad('Player').has(member):
		OverworldGlobals.showPrompt('You have a full party!')
		return
	if !OverworldGlobals.getCombatantSquad('Player').has(member) and replace_member == null:
		member.initializeCombatant(false)
		OverworldGlobals.getCombatantSquad('Player').append(member)
	elif replace_member != null:
		member.initializeCombatant(false)
		OverworldGlobals.getCombatantSquad('Player')[OverworldGlobals.getCombatantSquad('Player').find(replace_member)] = member
	
	OverworldGlobals.initializePlayerParty()
	PlayerGlobals.team_formation = OverworldGlobals.getCombatantSquad('Player')
	added_character.emit(member)

func removeFromActive():
	OverworldGlobals.getCombatantSquad('Player').erase(remove_member)
	removed_character.emit(remove_member)
	remove_member = null
