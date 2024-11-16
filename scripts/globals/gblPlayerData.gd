# Rename this to gblPlayerData
extends Node

var SAVE_NAME
var TEAM: Array[ResPlayerCombatant]
var TEAM_FORMATION: Array[ResCombatant]
var FOLLOWERS: Array[NPCFollower] = []
var FAST_TRAVEL_LOCATIONS: Array[String] = ['res://scenes/maps/TestRoom/TestRoomB.tscn', 'res://scenes/maps/TestRoom/TestRoomA.tscn']
var CLEARED_MAPS = []
var POWER: GDScript
var KNOWN_POWERS: Array = [load("res://resources/powers/Stealth.tres")]
var EQUIPPED_ARROW: ResProjectileAmmo
var EQUIPPED_BLESSING: ResBlessing
var CURRENCY = 100
var PARTY_LEVEL = 1
var MAX_PARTY_LEVEL = 5
var CURRENT_EXP = 0
var PROGRESSION_DATA: Dictionary = {} # This'll be handy later...
var UNLOCKED_ABILITIES: Dictionary = {}
var ADDED_ABILITIES: Dictionary = {}
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
	initializeBenchedTeam()
	#addExperience(99)

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
	if blessing is ResBlessing:
		EQUIPPED_BLESSING = blessing
		OverworldGlobals.showPlayerPrompt('You have been graced by blessing of the [color=yellow]%s[/color].' % blessing.blessing_name)
		blessing.setBlessing(true)

func equipNewArrowType():
	var arrows: Array = InventoryGlobals.INVENTORY.filter(func(item): return item is ResProjectileAmmo)
	arrows.sort_custom(func(a, b): return a.STACK > b.STACK)
	if !InventoryGlobals.hasItem(PlayerGlobals.EQUIPPED_ARROW) and !arrows.is_empty():
		arrows[0].equip()
		return true
	
	return false

#********************************************************************************
# COMBATANT MANAGEMENT
#********************************************************************************
func addExperience(experience: int, show_message:bool=false, bypass_cap:bool=false):
#	if PARTY_LEVEL >= MAX_PARTY_LEVEL and !bypass_cap:
#		OverworldGlobals.showPlayerPrompt('Max party level reached!')
#		return
	if show_message and !OverworldGlobals.getPlayer().has_node('ExperienceGainBar'):
		var experience_bar_view = load("res://scenes/user_interface/ExperienceGainBar.tscn").instantiate()
		experience_bar_view.added_exp = experience
		OverworldGlobals.getPlayer().add_child(experience_bar_view)
	CURRENT_EXP += experience
	if PARTY_LEVEL >= MAX_PARTY_LEVEL and CURRENT_EXP >= getRequiredExp() and !bypass_cap:
		CURRENT_EXP = getRequiredExp()
		OverworldGlobals.showPlayerPrompt('Max level already reached!')
		return
	if CURRENT_EXP >= getRequiredExp() and (PARTY_LEVEL < MAX_PARTY_LEVEL or bypass_cap):
		var prev_required = getRequiredExp()
		var prev_exp = CURRENT_EXP
		PARTY_LEVEL += 1
		CURRENT_EXP = 0
		if PARTY_LEVEL < MAX_PARTY_LEVEL:
			levelUpCombatants()
			if prev_exp - prev_required > 0:
				addExperience(prev_exp - prev_required, show_message, bypass_cap)
		elif PARTY_LEVEL >= MAX_PARTY_LEVEL:
			OverworldGlobals.showPlayerPrompt('Max party level reached!')
	elif CURRENT_EXP < 0:
		CURRENT_EXP = 0

func getRequiredExp() -> int:
	var baseExp = 500.0
	var expMultiplier = 1.25
	#print(PARTY_LEVEL)
	var gain = sqrt(expMultiplier ** (PARTY_LEVEL - 1)) * baseExp # Chng to cubrrt
	return int(gain)

func increaseLevelCap(amount:int=5):
	MAX_PARTY_LEVEL += amount
	if CURRENT_EXP >= getRequiredExp():
		addExperience(1, true)
	OverworldGlobals.showPlayerPrompt('Level cap increased to [color=yellow]%s[/color]!' % MAX_PARTY_LEVEL)

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

func addAbility(combatant, ability):
	if combatant is String:
		for member in TEAM: 
			if member.NAME == combatant:
				combatant = member
				break
	if ability is String:
		ability = load("res://resources/combat/abilities/%s.tres" % ability)
	
	if ADDED_ABILITIES.keys().has(combatant):
		ADDED_ABILITIES[combatant].append(ability)
	else:
		ADDED_ABILITIES[combatant] = []
		ADDED_ABILITIES[combatant].append(ability)
	OverworldGlobals.showPlayerPrompt('[color=yellow]%s[/color] learnt [color=yellow]%s[/color]!' % [combatant.NAME, ability.NAME])
	loadAddedAbilities()

func addPower(power_file_name: String):
	if FileAccess.file_exists("res://resources/powers/%s.tres" % power_file_name):
		var power = load("res://resources/powers/%s.tres" % power_file_name)
		KNOWN_POWERS.append(power)
		OverworldGlobals.showPlayerPrompt('Willis learnt the power of [color=yellow]%s[/color]!' % power.NAME)

func loadAddedAbilities():
	for member in TEAM:
		if ADDED_ABILITIES.keys().has(member): 
			member.ABILITY_POOL.append_array(ADDED_ABILITIES[member])

func hasAbility(combatant: ResPlayerCombatant, ability: ResAbility):
	return combatant.ABILITY_POOL.has(ability)

func hasUnlockedAbility(combatant: ResPlayerCombatant, ability: ResAbility):
	return (UNLOCKED_ABILITIES.keys().has(combatant) and UNLOCKED_ABILITIES[combatant].has(ability)) or ability.REQUIRED_LEVEL == 0

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
	FOLLOWERS.append(follower)
	follower.FOLLOW_LOCATION = 20 * FOLLOWERS.size()

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
		if !combatant.initialized: combatant.initializeCombatant()
		combatant.STAT_VALUES['health'] = combatant.BASE_STAT_VALUES['health']
		if cure: combatant.LINGERING_STATUS_EFFECTS.clear()

func isMapCleared():
	if OverworldGlobals.getCurrentMap().SAFE:
		return true
	else:
		return CLEARED_MAPS.has(OverworldGlobals.getCurrentMap().NAME)

func addCommaToNum(value: int=CURRENCY) -> String:
	var str_value: String = str(value)
	var loop_end: int = 0 if value > -1 else 1
	for i in range(str_value.length()-3, loop_end, -3):
		str_value = str_value.insert(i, ",")
	return str_value

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
	data.KNOWN_POWERS = KNOWN_POWERS
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
	data.ADDED_ABILITIES = ADDED_ABILITIES
	data.MAX_PARTY_LEVEL = MAX_PARTY_LEVEL
	
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
	#SAVE_NAME = save_data.
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
	ADDED_ABILITIES = save_data.ADDED_ABILITIES
	MAX_PARTY_LEVEL = save_data.MAX_PARTY_LEVEL
	KNOWN_POWERS = save_data.KNOWN_POWERS
	#EQUIPPED_CHARM.equip(null)
	if EQUIPPED_BLESSING != null: EQUIPPED_BLESSING.setBlessing(true)
	
	initializeBenchedTeam()
	OverworldGlobals.initializePlayerParty()
	OverworldGlobals.setCombatantSquad('Player', TEAM_FORMATION)
	loadAddedAbilities()
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

func resetVariables():
	for member in TEAM:
		member.reset()
	
	SAVE_NAME = null
	TEAM = [preload("res://resources/combat/combatants_player/Willis.tres")]
	TEAM_FORMATION = []
	FOLLOWERS = []
	FAST_TRAVEL_LOCATIONS = [
		'res://scenes/maps/TestRoom/TestRoomB.tscn',
		'res://scenes/maps/TestRoom/TestRoomA.tscn'
	]
	CLEARED_MAPS = []
	POWER = null
	KNOWN_POWERS = [load("res://resources/powers/Stealth.tres")]
	EQUIPPED_ARROW = null
	EQUIPPED_BLESSING = null
	CURRENCY = 100
	PARTY_LEVEL = 1
	MAX_PARTY_LEVEL = 5
	CURRENT_EXP = 0
	PROGRESSION_DATA = {}
	UNLOCKED_ABILITIES = {}
	ADDED_ABILITIES = {}
	overworld_stats = {
		'stamina': 100.0,
		'bow_max_draw': 5.0,
		'walk_speed': 100.0,
		'sprint_speed': 200.0,
		'sprint_drain': 0.25,
		'stamina_gain': 0.15
	}
