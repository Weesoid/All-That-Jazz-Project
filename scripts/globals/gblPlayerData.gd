# Rename this to gblPlayerData
extends Node

var TEAM: Array[ResPlayerCombatant]
var TEAM_FORMATION: Array[ResCombatant]
var FOLLOWERS: Array[NPCFollower] = []
var FAST_TRAVEL_LOCATIONS: Array[String] = ['res://scenes/maps/TestRoom/TestRoomB.tscn', 'res://scenes/maps/TestRoom/TestRoomA.tscn']
var CLEARED_MAPS = []
var POWER: GDScript
var EQUIPPED_ARROW: ResProjectileAmmo
var EQUIPPED_BLESSING: ResBlessing
var CURRENCY = 100
var PARTY_LEVEL = 1
var CURRENT_EXP = 0
var PROGRESSION_DATA: Dictionary = {} # This'll be handy later...
var UNLOCKED_ABILITIES: Dictionary = {}
var overworld_stats: Dictionary = {
	'stamina': 100.0,
	'bow_max_draw': 5.0,
	'walk_speed': 100.0,
	'sprint_speed': 200.0,
	'sprint_drain': 0.25,
	'stamina_gain': 0.15
}
#var stamina = 100.0
#var bow_max_draw = 5.0
#var walk_speed = 100.0
#var sprint_speed = 200.0
#var sprint_drain = 0.25
#var stamina_gain = 0.15

signal level_up

func _ready():
	EQUIPPED_ARROW = load("res://resources/items/Arrow.tres")
	EQUIPPED_ARROW.STACK = 0
	TEAM.append(preload("res://resources/combat/combatants_player/Willis.tres"))
	initializeBenchedTeam()
	addExperience(99)

func initializeBenchedTeam():
	if PlayerGlobals.TEAM.is_empty():
		return
	
	for member in TEAM:
		if !member.initialized:
			member.initializeCombatant(false)

func applyBlessing(blessing):
	if blessing is String and !blessing.contains('res://'):
		blessing = load("res://resources/blessings/%s.tres" % blessing)
	elif blessing is String:
		blessing = load(blessing).instantiate()
		OverworldGlobals.getPlayer().add_child(blessing)
	
	if EQUIPPED_BLESSING != null and blessing is ResBlessing:
		EQUIPPED_BLESSING.setBlessing(false)
		EQUIPPED_BLESSING = blessing
		OverworldGlobals.showPlayerPrompt('You have been graced by blessing of the [color=yellow]%s[/color].' % blessing.blessing_name)
		blessing.setBlessing(true)

#********************************************************************************
# COMBATANT MANAGEMENT
#********************************************************************************
func addExperience(experience: int, show_message:bool=false):
	if show_message:
		var message = '[color=yellow]%s[/color] morale added! (%s/%s)' % [experience, CURRENT_EXP, getRequiredExp()]
		OverworldGlobals.showPlayerPrompt(message)
	CURRENT_EXP += experience
	if CURRENT_EXP >= getRequiredExp():
		var prev_required = getRequiredExp()
		var prev_exp = CURRENT_EXP
		PARTY_LEVEL += 1
		levelUpCombatants()
		CURRENT_EXP = 0
		if prev_exp - prev_required > 0:
			addExperience(prev_exp - prev_required)
	elif CURRENT_EXP < 0:
		CURRENT_EXP = 0

func getRequiredExp() -> int:
	var baseExp = 100
	var expMultiplier = 1.25
	return int(baseExp * expMultiplier ** (PARTY_LEVEL - 1))

func addCurrency(value: int):
	if value + CURRENCY < 0:
		CURRENCY = 0
	else:
		CURRENCY += value

func unlockAbility(combatant: ResPlayerCombatant, ability: ResAbility):
	if UNLOCKED_ABILITIES.keys().has(combatant):
		UNLOCKED_ABILITIES[combatant].append(ability)
	else:
		UNLOCKED_ABILITIES[combatant] = []
		UNLOCKED_ABILITIES[combatant].append(ability)

func hasUnlockedAbility(combatant: ResPlayerCombatant, ability: ResAbility):
	return UNLOCKED_ABILITIES.keys().has(combatant) and UNLOCKED_ABILITIES[combatant].has(ability)

func hasActiveTeam()-> bool:
	return !OverworldGlobals.getCombatantSquad('Player').is_empty()

func levelUpCombatants():
	for combatant in PlayerGlobals.TEAM:
		combatant.STAT_POINTS += 1
	OverworldGlobals.getPlayer().prompt.showPrompt('Party leveled up to [color=yellow]%s[/color]!' % [PARTY_LEVEL])
	level_up.emit()

func addCombatantToTeam(combatant_id):
	var combatant
	if combatant_id is String:
		combatant = load("res://resources/combat/combatants_player/%s.tres" % combatant_id)
	elif combatant_id is ResCombatant:
		combatant = combatant_id
	combatant.STAT_POINTS = PARTY_LEVEL
	TEAM.append(combatant)
	OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s[/color] joined your posse!' % combatant.NAME)

func getTeamMembers()-> Array[String]:
	var out: Array[String] = []
	for member in TEAM:
		out.append(member.NAME)
	return out

func addFollower(follower: NPCFollower):
	print('before: ', OverworldGlobals.follow_array)
	FOLLOWERS.append(follower)
	follower.FOLLOW_LOCATION = 20 * FOLLOWERS.size()
	print('after: ', OverworldGlobals.follow_array)

func removeFollower():
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

func isFollowerActive(follower_combatant_name: String):
	for f in FOLLOWERS:
		if f.host_combatant.NAME == follower_combatant_name:
			return true
	
	return false

func loadSquad():
	OverworldGlobals.setCombatantSquad('Player', PlayerGlobals.TEAM_FORMATION)

func setFollowersMotion(enable:bool):
	for follower in FOLLOWERS:
		if enable:
			follower.SPEED = 1.0
		else:
			follower.SPEED = -1.0
			follower.stopWalkAnimation()

func healCombatants(cure: bool=true):
	for combatant in TEAM:
		combatant.STAT_VALUES['health'] = combatant.BASE_STAT_VALUES['health']
		if cure: combatant.LINGERING_STATUS_EFFECTS.clear()

func isMapCleared():
	if OverworldGlobals.getCurrentMap().SAFE:
		return true
	else:
		return CLEARED_MAPS.has(OverworldGlobals.getCurrentMap().NAME)

func saveData(save_data: Array):
	var data: PlayerSaveData = PlayerSaveData.new()
	data.TEAM = TEAM
	data.FOLLOWERS = FOLLOWERS
	data.FAST_TRAVEL_LOCATIONS = FAST_TRAVEL_LOCATIONS
	data.POWER = POWER
	data.EQUIPPED_ARROW = EQUIPPED_ARROW
	data.CURRENCY = CURRENCY
	data.PARTY_LEVEL = PARTY_LEVEL
	data.CURRENT_EXP = CURRENT_EXP
	data.CLEARED_MAPS = CLEARED_MAPS
#	data.overworld_stats['stamina'] = stamina
#	data.overworld_stats['bow_max_draw']= bow_max_draw
#	data.overworld_stats['walk_speed'] = walk_speed
#	data.sprint_speed = sprint_speed
#	data.sprint_drain = sprint_drain
#	data.stamina_gain = stamina_gain
	data.PROGRESSION_DATA = PROGRESSION_DATA
	data.TEAM_FORMATION = TEAM_FORMATION
	data.EQUIPPED_BLESSING = EQUIPPED_BLESSING
	data.UNLOCKED_ABILITIES = UNLOCKED_ABILITIES
	
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
			combatant.STAT_POINTS,
			combatant.STAT_MODIFIERS,
			combatant.EQUIPPED_WEAPON,
			combatant.STAT_POINT_ALLOCATIONS,
			combatant.ABILITY_SLOT,
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
	PARTY_LEVEL = save_data.PARTY_LEVEL
	CURRENT_EXP = save_data.CURRENT_EXP
	CLEARED_MAPS = save_data.CLEARED_MAPS
#	stamina = save_data.stamina
#	bow_max_draw= save_data.overworld_stats['bow_max_draw']
#	walk_speed = save_data.overworld_stats['walk_speed']
#	sprint_speed = save_data.sprint_speed
#	sprint_drain = save_data.sprint_drain
#	stamina_gain = save_data.stamina_gain
	PROGRESSION_DATA = save_data.PROGRESSION_DATA
	TEAM_FORMATION = save_data.TEAM_FORMATION
	EQUIPPED_BLESSING = save_data.EQUIPPED_BLESSING
	UNLOCKED_ABILITIES = save_data.UNLOCKED_ABILITIES
	#EQUIPPED_CHARM.equip(null)
	if EQUIPPED_BLESSING != null: EQUIPPED_BLESSING.setBlessing(true)
	
	initializeBenchedTeam()
	OverworldGlobals.initializePlayerParty()
	OverworldGlobals.setCombatantSquad('Player', TEAM_FORMATION)
	for combatant in TEAM:
		combatant.ABILITY_SET = save_data.COMBATANT_SAVE_DATA[combatant][0]
		combatant.CHARMS = save_data.COMBATANT_SAVE_DATA[combatant][1]
		#combatant.STAT_VALUES = save_data.COMBATANT_SAVE_DATA[combatant][2]
		#combatant.BASE_STAT_VALUES = save_data.COMBATANT_SAVE_DATA[combatant][3]
		#combatant.ABILITY_POOL = save_data.COMBATANT_SAVE_DATA[combatant][4]
		combatant.MANDATORY = save_data.COMBATANT_SAVE_DATA[combatant][5]
		combatant.LINGERING_STATUS_EFFECTS = save_data.COMBATANT_SAVE_DATA[combatant][6]
		combatant.initialized = save_data.COMBATANT_SAVE_DATA[combatant][7]
		combatant.STAT_POINTS = save_data.COMBATANT_SAVE_DATA[combatant][8]
		#combatant.STAT_MODIFIERS = save_data.COMBATANT_SAVE_DATA[combatant][9]
		combatant.EQUIPPED_WEAPON = save_data.COMBATANT_SAVE_DATA[combatant][10]
		combatant.STAT_POINT_ALLOCATIONS = save_data.COMBATANT_SAVE_DATA[combatant][11]
		combatant.ABILITY_SLOT = save_data.COMBATANT_SAVE_DATA[combatant][12]
		CombatGlobals.modifyStat(combatant, combatant.getAllocationModifier(), 'allocations')
		for charm in combatant.CHARMS.values():
			if charm != null:
				charm.updateItem() 
				charm.equip(combatant)
		combatant.updateCombatant(save_data)
	
	overworld_stats['stamina'] = 100.0 # DO NOT TOUCH STAMINA FOR BLESSINGS!
