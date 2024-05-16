# Rename this to gblPlayerData
extends Node

var TEAM: Array[ResPlayerCombatant]
var FOLLOWERS: Array[NPCFollower] = []
var FAST_TRAVEL_LOCATIONS: Array[String] = ['res://scenes/maps/TestRoom/TestRoomB.tscn', 'res://scenes/maps/TestRoom/TestRoomA.tscn']
var CLEARED_MAPS = []
var POWER: GDScript
var EQUIPPED_ARROW: ResProjectileAmmo
var EQUIPPED_CHARM: ResUtilityCharm
var CURRENCY = 0
var PARTY_LEVEL = 1
var CURRENT_EXP = 0
var STRING_CONDITIONS: Array[String] # This'll be handly later...

var stamina = 100.0
var bow_max_draw = 5.0
var walk_speed = 100.0
var sprint_speed = 200.0
var sprint_drain = 0.10
var stamina_gain = 0.10

signal level_up

func _ready():
	CURRENCY = 100
	
	EQUIPPED_ARROW = load("res://resources/items/Arrow.tres")
	EQUIPPED_ARROW.STACK = 0
	
	TEAM.append(preload("res://resources/combat/combatants_player/GreenHealer.tres"))
	TEAM.append(preload("res://resources/combat/combatants_player/PinkBlasko.tres"))
	TEAM.append(preload("res://resources/combat/combatants_player/Filler1.tres"))
	TEAM.append(preload("res://resources/combat/combatants_player/Filler2.tres"))
	initializeBenchedTeam()

func initializeBenchedTeam():
	if PlayerGlobals.TEAM.is_empty():
		return
	
	for member in TEAM:
		if !member.initialized:
			member.initializeCombatant()
			member.SCENE.free()

#********************************************************************************
# COMBATANT MANAGEMENT
#********************************************************************************
func addExperience(experience: int):
	CURRENT_EXP += experience
	if CURRENT_EXP >= getRequiredExp():
		PARTY_LEVEL += 1
		CURRENT_EXP = 0
		levelUpCombatants()

func getRequiredExp() -> int:
	var baseExp = 100
	var expMultiplier = 1.25
	return int(baseExp * expMultiplier ** (PARTY_LEVEL - 1))

func hasActiveTeam()-> bool:
	for member in TEAM:
		if member.active: return true
	
	return false

func levelUpCombatants():
	for combatant in PlayerGlobals.TEAM:
		combatant.STAT_POINTS += 1
	OverworldGlobals.getPlayer().prompt.showPrompt('Party leveled up to [color=yellow]%s[/color]!' % [PARTY_LEVEL])
	level_up.emit()

func addFollower(follower: NPCFollower):
	FOLLOWERS.append(follower)
	follower.FOLLOW_LOCATION = 20 * FOLLOWERS.size()

func removeFollower(follower_combatant: ResPlayerCombatant):
	follower_combatant.active = false
	OverworldGlobals.loadFollowers()
	
	var index = 1
	for f in FOLLOWERS:
		f.FOLLOW_LOCATION = 20 * index
		index += 1

func hasFollower(follower_combatant: ResPlayerCombatant):
	for f in FOLLOWERS:
		if f.host_combatant == follower_combatant:
			return true
	
	return false

func hasUtilityCharm():
	return EQUIPPED_CHARM != null

func isFollowerActive(follower_combatant_name: String):
	for f in FOLLOWERS:
		if f.host_combatant.NAME == follower_combatant_name:
			return true
	
	return false

func loadSquad():
	for member in TEAM:
		if member.active: 
			OverworldGlobals.getCombatantSquad('Player').append(member)

func setFollowersMotion(enable:bool):
	for follower in FOLLOWERS:
		if enable:
			follower.SPEED = 1.0
		else:
			follower.SPEED = -1.0
			follower.stopWalkAnimation()

func saveData(save_data: Array):
	var data: PlayerSaveData = PlayerSaveData.new()
	data.TEAM = TEAM
	data.FOLLOWERS = FOLLOWERS
	data.FAST_TRAVEL_LOCATIONS = FAST_TRAVEL_LOCATIONS
	data.POWER = POWER
	data.EQUIPPED_ARROW = EQUIPPED_ARROW
	data.CURRENCY = CURRENCY
	data.EQUIPPED_CHARM = EQUIPPED_CHARM
	data.PARTY_LEVEL = PARTY_LEVEL
	data.CURRENT_EXP = CURRENT_EXP
	data.CLEARED_MAPS = CLEARED_MAPS
	data.stamina = stamina
	data.bow_max_draw= bow_max_draw
	data.walk_speed = walk_speed
	data.sprint_speed = sprint_speed
	data.sprint_drain = sprint_drain
	data.stamina_gain = stamina_gain
	data.STRING_CONDITIONS = STRING_CONDITIONS
	
	for combatant in TEAM:
		data.COMBATANT_SAVE_DATA[combatant] = [
			combatant.ABILITY_SET, 
			combatant.CHARMS,
			combatant.STAT_VALUES,
			combatant.BASE_STAT_VALUES,
			combatant.ABILITY_POOL,
			combatant.MANDATORY,
			combatant.LINGERING_STATUS_EFFECTS,
			combatant.initialized,
			combatant.active,
			combatant.STAT_POINTS,
			combatant.STAT_MODIFIERS,
			combatant.EQUIPPED_WEAPON,
			combatant.STAT_POINT_ALLOCATIONS,
			combatant.ABILITY_SLOT
			]
	
	save_data.append(data)

func loadData(save_data: PlayerSaveData):
	OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.clear()
	TEAM = save_data.TEAM
	FOLLOWERS = save_data.FOLLOWERS
	FAST_TRAVEL_LOCATIONS = save_data.FAST_TRAVEL_LOCATIONS
	POWER = save_data.POWER
	EQUIPPED_ARROW = save_data.EQUIPPED_ARROW
	CURRENCY = save_data.CURRENCY
	EQUIPPED_CHARM = save_data.EQUIPPED_CHARM
	PARTY_LEVEL = save_data.PARTY_LEVEL
	CURRENT_EXP = save_data.CURRENT_EXP
	CLEARED_MAPS = save_data.CLEARED_MAPS
	stamina = save_data.stamina
	bow_max_draw= save_data.bow_max_draw
	walk_speed = save_data.walk_speed
	sprint_speed = save_data.sprint_speed
	sprint_drain = save_data.sprint_drain
	stamina_gain = save_data.stamina_gain
	STRING_CONDITIONS = save_data.STRING_CONDITIONS
	
	for combatant in TEAM:
		combatant.ABILITY_SET = save_data.COMBATANT_SAVE_DATA[combatant][0]
		combatant.CHARMS = save_data.COMBATANT_SAVE_DATA[combatant][1]
		combatant.STAT_VALUES = save_data.COMBATANT_SAVE_DATA[combatant][2]
		combatant.BASE_STAT_VALUES = save_data.COMBATANT_SAVE_DATA[combatant][3]
		combatant.ABILITY_POOL = save_data.COMBATANT_SAVE_DATA[combatant][4]
		combatant.MANDATORY = save_data.COMBATANT_SAVE_DATA[combatant][5]
		combatant.LINGERING_STATUS_EFFECTS = save_data.COMBATANT_SAVE_DATA[combatant][6]
		combatant.initialized = save_data.COMBATANT_SAVE_DATA[combatant][7]
		combatant.active = save_data.COMBATANT_SAVE_DATA[combatant][8]
		combatant.STAT_POINTS = save_data.COMBATANT_SAVE_DATA[combatant][9]
		combatant.STAT_MODIFIERS = save_data.COMBATANT_SAVE_DATA[combatant][10]
		combatant.EQUIPPED_WEAPON = save_data.COMBATANT_SAVE_DATA[combatant][11]
		combatant.STAT_POINT_ALLOCATIONS = save_data.COMBATANT_SAVE_DATA[combatant][12]
		combatant.ABILITY_SLOT = save_data.COMBATANT_SAVE_DATA[combatant][13]
		if combatant.active:
			OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.append(combatant)
	
	initializeBenchedTeam()
	OverworldGlobals.initializePlayerParty()
