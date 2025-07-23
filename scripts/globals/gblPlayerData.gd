# Rename this to gblPlayerData
extends Node

var SAVE_NAME
var TEAM: Array[ResPlayerCombatant]
var TEAM_FORMATION: Array[ResCombatant]
var map_logs: Dictionary = {}
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
# TEMPERMENTS!
var PRIMARY_TEMPERMENTS: Dictionary = {
	'gifted': {'handling': 1},
	'nimble': {'hustle': 4},
	'lucky': {'crit':0.03},
	'deadly': {'crit_dmg': 0.15},
	'dominant': {'brawn': 0.1},
	'tenacious': {'grit': 0.1},
	'fortified': {'resist': 0.1},
	'focused': {'accuracy':0.03},
	'unyielding': {'heal_mult':0.2},
	'all_arounder': {'hustle': 1, 'crit': 0.02, 'crit_dmg': 0.02, 'brawn': 0.02, 'grit': 0.02, 'resist': 0.02, 'accuracy': 0.02, 'heal_mult': 0.02}
}
var SECONDARY_TEMPERMENTS: Dictionary = {
	# BUFFS
	'clever': {'handling': 1},
	'quick': {'hustle': 2},
	'acute': {'crit':0.02},
	'hard_hitter': {'crit_dmg': 0.1},
	'mighty': {'brawn': 0.05},
	'stalwart': {'grit': 0.05},
	'resilient': {'resist': 0.05},
	'keen': {'accuracy':0.02},
	'limber': {'heal_mult':0.05},
	
	# QUIRKS
	'smartass': {'handling': 2, 'brawn': -0.12,'grit': -0.12},
	'frantic': {'hustle': 4, 'accuracy': -0.1},
	'daredevil': {'crit':0.1, 'accuracy':-0.1},
	'crude': {'crit_dmg': 0.25, 'crit':-0.15},
	'reckless': {'brawn': 0.15, 'grit': -0.15},
	'headstrong': {'grit': 0.15, 'brawn': -0.15},
	'hardened': {'resist': 0.35, 'crit': -0.1},
	'rigid': {'accuracy':0.15, 'crit': -0.05, 'crit_dmg': -0.25},
	'selfish': {'heal_mult':0.25, 'grit': -0.2},
	
	# DEBUFFS
	'heavy_handed': {'handling': -1},
	'clumsy': {'hustle': -4},
	'bad_luck': {'crit':-0.05},
	'dud_hitter': {'crit_dmg': -0.25},
	'wimpy': {'brawn': -0.1},
	'soft': {'grit': -0.1},
	'sickly': {'resist': -0.05},
	'oblivious': {'accuracy':-0.05},
	'stubborn': {'heal_mult':-0.15}
}
var current_stalker: ResStalkerData
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

func getTeamMemberNames():
	var out = []
	for combatant in TEAM:
		out.append(combatant.NAME)
	return out

func getTeamMember(member_name: String)-> ResPlayerCombatant:
	for member in TEAM:
		if member.NAME == member_name: return member
	
	return null

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
		if PARTY_LEVEL <= MAX_PARTY_LEVEL:
			levelUpCombatants()
			if prev_exp - prev_required > 0:
				addExperience(prev_exp - prev_required, show_message, bypass_cap)
		elif PARTY_LEVEL >= MAX_PARTY_LEVEL:
			OverworldGlobals.showPlayerPrompt('Max party level reached!')
	elif CURRENT_EXP < 0:
		CURRENT_EXP = 0

func levelUpTeam():
	addExperience(getRequiredExp()-CURRENT_EXP, true)

func getRequiredExp() -> int:
	var baseExp = 500.0
	var expMultiplier = 1.25
	#print(PARTY_LEVEL)
	var gain = pow(expMultiplier ** (PARTY_LEVEL - 1), 1.0/3.0) * baseExp # Chng to cubrrt
	return int(gain)

func increaseLevelCap(amount:int=5):
	MAX_PARTY_LEVEL += amount
	if CURRENT_EXP >= getRequiredExp():
		addExperience(1, true)
	OverworldGlobals.showPlayerPrompt('Level cap increased to [color=yellow]%s[/color]!' % MAX_PARTY_LEVEL)

func getLevelTier():
	if PARTY_LEVEL < 5:
		return 1
	elif PARTY_LEVEL >= 5 and PARTY_LEVEL < 10:
		return 2
	elif PARTY_LEVEL >= 10 and PARTY_LEVEL < 15:
		return 3
	elif PARTY_LEVEL > 15:
		return 4

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
		combatant.scaleStats()
	OverworldGlobals.getPlayer().prompt.showPrompt('Party leveled up to [color=yellow]%s[/color]!' % [PARTY_LEVEL])
	level_up.emit()

func addCombatantToTeam(combatant_id):
	var combatant
	if combatant_id is String:
		if !combatant_id.contains('res://'):
			combatant = load("res://resources/combat/combatants_player/%s.tres" % combatant_id)
		else:
			combatant = load(combatant_id)
	elif combatant_id is ResCombatant:
		combatant = combatant_id
	if combatant.TEMPERMENT['primary'] == []:
		combatant.TEMPERMENT['primary'].append(PlayerGlobals.PRIMARY_TEMPERMENTS.keys().pick_random())
	if combatant.TEMPERMENT['secondary'] == []:
		combatant.TEMPERMENT['secondary'].append(PlayerGlobals.SECONDARY_TEMPERMENTS.keys().pick_random())
	combatant.STAT_POINTS = PARTY_LEVEL
	TEAM.append(combatant)
	OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s[/color] joined your posse!' % combatant.NAME)

func removeCombatant(combatant_id: ResPlayerCombatant):
	for member in TEAM:
		if member == combatant_id: 
			member.reset()
			TEAM.erase(member)
			break
	var removed_combatants = []
	for member in OverworldGlobals.getCombatantSquad('Player'):
		if !TEAM.has(member): removed_combatants.append(member)
	for member in removed_combatants:
		OverworldGlobals.getCombatantSquad('Player').erase(member)
	TEAM_FORMATION = OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD
	overwriteTeam()

func loadSquad():
	OverworldGlobals.setCombatantSquad('Player', PlayerGlobals.TEAM_FORMATION)

func addCombatantTemperment(combatant: ResPlayerCombatant, temperment: String='/random'):
	if combatant.TEMPERMENT['secondary'].size() >= 6:
		var removed_temperment = combatant.TEMPERMENT['secondary'][0]
		combatant.TEMPERMENT['secondary'].remove_at(0)
		OverworldGlobals.showPlayerPrompt('[color=yellow]%s[/color] lost [color=yellow]%s[/color]' % [combatant, removed_temperment.capitalize()])
	
	if temperment == '/random':
		randomize()
		var random_temperment = SECONDARY_TEMPERMENTS.keys().filter(func(key): return !combatant.TEMPERMENT['secondary'].has(key)).pick_random()
		OverworldGlobals.showPlayerPrompt('[color=yellow]%s[/color] gained [color=yellow]%s[/color]' % [combatant, random_temperment.capitalize()])
		combatant.TEMPERMENT['secondary'].append(random_temperment)
	else:
		combatant.TEMPERMENT['secondary'].append(temperment)
	
	combatant.applyTemperments(true)

func hasFollower(follower_combatant: ResPlayerCombatant):
	for f in getActiveFollowers():
		if f.host_combatant == follower_combatant:
			return true
	
	return false

func isFollowerActive(follower_combatant_name: String):
	for f in getActiveFollowers():
		if f.host_combatant.NAME == follower_combatant_name:
			return true
	
	return false

func getActiveFollowers():
	return OverworldGlobals.getCurrentMap().get_children().filter(func(child): return child is NPCFollower)

func setFollowersMotion(enable:bool):
	for follower in getActiveFollowers():
		if !is_instance_valid(follower):
			return
		if enable:
			follower.speed_multiplier = 1.1
		else:
			follower.speed_multiplier = 0.0
			follower.stopWalkAnimation()

func healCombatants(percent_heal:float=1.0,cure: bool=true):
	for combatant in TEAM:
		if !combatant.initialized: combatant.initializeCombatant(false)
		combatant.STAT_VALUES['health'] = int(combatant.BASE_STAT_VALUES['health'] * percent_heal)
		if cure: combatant.LINGERING_STATUS_EFFECTS.clear()

func addMapLog(map_path: String, log=null):
	if !map_logs.has(map_path):
		if log != null:
			map_logs[map_path] = [log]
		else:
			map_logs[map_path] = []
	elif log != null:
		map_logs[map_path].append(log)
	

func randomizeMapEvents(exclude_map:String=''):
	for map in map_logs.keys().filter(func(map): return hasMapEvent(map)):
		clearMapPatrollers(map)
		removeMapEvents(map)
	var map_keys = map_logs.keys().filter(
		func(key): 
			return hasClearedPatrolGroups(key) and (exclude_map == '' or key != exclude_map)
			)
	map_keys.shuffle()
	map_keys.resize(ceil(map_keys.size()*0.5))
	for map in map_keys:
		respawnMapPatrollers(map)
		removeMapEvents(map)
		map_logs[map].append(generateMapEvent())

func getClearedMaps():
	return map_logs.keys().filter(func(map): return hasClearedPatrolGroups(map))

func respawnMapPatrollers(map):
	map_logs[map] = map_logs[map].filter(func(log): return !(log is StringName and log.contains('PatrollerGroup')))

func clearMapPatrollers(map_path):
	var map: MapData = load(map_path).instantiate()
	map.clearPatrollers()
	map.queue_free()

func removeMapEvents(map):
	map_logs[map] = map_logs[map].filter(func(log): return !(log is Dictionary and log.has('map_events')))

func generateMapEvent():
	var events = {}
	var chance_budget = 1.0
	var possible_events = [
#		'combat_event',
#		'additional_enemies',
#		'patroller_effect',
#		'reward_item',
		'bonus_loot',
		'bonus_experience'
		]
	var random_event
	
	while chance_budget > 0:
		if CombatGlobals.randomRoll(chance_budget) and !possible_events.is_empty():
			random_event = possible_events.pick_random()
			possible_events.erase(random_event)
			match random_event:
				'combat_event': events['combat_event'] = OverworldGlobals.loadArrayFromPath("res://resources/combat/events/").pick_random()
				'additional_enemies': events['additional_enemies'] = CombatGlobals.back_up_enemies.pick_random()
				'patroller_effect': events['patroller_effect'] = ['CriticalEye','Riposte'].pick_random()
				'reward_item': events['reward_item'] = OverworldGlobals.loadArrayFromPath("res://resources/items/", func(item): return item is ResCharm and !item.UNIQUE).pick_random()
				'bonus_loot': events['bonus_loot'] = {}
				'bonus_experience': events['bonus_experience'] = 0
				#'destroy_objective': events['destroy_objective'] = true
			chance_budget -= 0.25
		else:
			chance_budget = 0
	events['map_events'] = ''
	
	return events

func hasMapEvent(map_path):
	if !map_logs.has(map_path):
		return false
	
	for log in map_logs[map_path]:
		if log is Dictionary and log.has('map_events') and hasPatrolGroups(map_path):
			return true

# Checks if map has patrol groups.
func hasPatrolGroups(map_path):
	var map: MapData = load(map_path).instantiate()
	var has_patrol_groups = map.getPatrolGroups().size() > 0
	map.queue_free()
	return has_patrol_groups

# Check if player cleared the maps with patrol groups.
func hasClearedPatrolGroups(map_path):
	var map: MapData = load(map_path).instantiate()
	var has_patrol_groups = (map.getClearState() == MapData.PatrollerClearState.FULL_CLEAR and hasPatrolGroups(map_path))
	map.queue_free()
	return has_patrol_groups

#func hasRespawnedPatrols(map_path):
#	return map_logs[map_path].has('respawned')

func addCommaToNum(value: int=CURRENCY) -> String:
	var str_value: String = str(value)
	var loop_end: int = 0 if value > -1 else 1
	for i in range(str_value.length()-3, loop_end, -3):
		str_value = str_value.insert(i, ",")
	return str_value

func overwriteTeam():
	var current_save = load("res://saves/%s.tres" % PlayerGlobals.SAVE_NAME)
	for data in current_save.save_data:
		if data is PlayerSaveData: 
			data.TEAM = TEAM
			data.TEAM_FORMATION = TEAM_FORMATION
			break
	ResourceSaver.save(current_save, "res://saves/%s.tres" % PlayerGlobals.SAVE_NAME)
	#return sa

func saveData(save_data: Array):
	var data: PlayerSaveData = PlayerSaveData.new()
	data.TEAM = TEAM
	#data.FOLLOWERS = FOLLOWERS
	data.POWER = POWER
	data.EQUIPPED_ARROW = EQUIPPED_ARROW
	data.CURRENCY = CURRENCY
	data.PARTY_LEVEL = PARTY_LEVEL
	data.CURRENT_EXP = CURRENT_EXP
	data.map_logs = map_logs
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
			combatant.GUARD_EFFECT,
			combatant.TEMPERMENT
			]
	
	save_data.append(data)

func loadData(save_data: PlayerSaveData):
	OverworldGlobals.getPlayer().squad.COMBATANT_SQUAD.clear()
	TEAM = save_data.TEAM
	POWER = save_data.POWER
	EQUIPPED_ARROW = save_data.EQUIPPED_ARROW
	CURRENCY = save_data.CURRENCY
	PARTY_LEVEL = save_data.PARTY_LEVEL
	CURRENT_EXP = save_data.CURRENT_EXP
	map_logs = save_data.map_logs
	PROGRESSION_DATA = save_data.PROGRESSION_DATA
	TEAM_FORMATION = save_data.TEAM_FORMATION
	EQUIPPED_BLESSING = save_data.EQUIPPED_BLESSING
	UNLOCKED_ABILITIES = save_data.UNLOCKED_ABILITIES
	ADDED_ABILITIES = save_data.ADDED_ABILITIES
	MAX_PARTY_LEVEL = save_data.MAX_PARTY_LEVEL
	KNOWN_POWERS = save_data.KNOWN_POWERS
	if EQUIPPED_BLESSING != null: EQUIPPED_BLESSING.setBlessing(true)
	
	initializeBenchedTeam()
	OverworldGlobals.initializePlayerParty()
	OverworldGlobals.setCombatantSquad('Player', TEAM_FORMATION)
	loadAddedAbilities()
	for combatant in TEAM:
		#combatant.reset()
		combatant.ABILITY_SET = save_data.COMBATANT_SAVE_DATA[combatant][0]
		combatant.CHARMS = save_data.COMBATANT_SAVE_DATA[combatant][1]
		#combatant.STAT_VALUES = save_data.COMBATANT_SAVE_DATA[combatant][2]
		#combatant.BASE_STAT_VALUES = save_data.COMBATANT_SAVE_DATA[combatant][3]
		#combatant.ABILITY_POOL = save_data.COMBATANT_SAVE_DATA[combatant][4]
		#combatant.MANDATORY = save_data.COMBATANT_SAVE_DATA[combatant][5]
		combatant.LINGERING_STATUS_EFFECTS = save_data.COMBATANT_SAVE_DATA[combatant][6]
		combatant.initialized = save_data.COMBATANT_SAVE_DATA[combatant][7]
		combatant.STAT_POINTS = save_data.COMBATANT_SAVE_DATA[combatant][8]
		#combatant.STAT_MODIFIERS = save_data.COMBATANT_SAVE_DATA[combatant][9]
		combatant.EQUIPPED_WEAPON = save_data.COMBATANT_SAVE_DATA[combatant][10]
		combatant.STAT_POINT_ALLOCATIONS = save_data.COMBATANT_SAVE_DATA[combatant][11]
		combatant.GUARD_EFFECT = save_data.COMBATANT_SAVE_DATA[combatant][12]
		combatant.TEMPERMENT = save_data.COMBATANT_SAVE_DATA[combatant][13]
		CombatGlobals.modifyStat(combatant, combatant.getAllocationModifier(), 'allocations')
		for charm in combatant.CHARMS.values():
			if charm != null:
				charm.updateItem()
				charm.equip(combatant)
		combatant.initializeCombatant(false)
		combatant.updateCombatant(save_data)
		combatant.initializeCombatant(false)
	# TO DO: Fade followers based on interaction instead...?
#	if OverworldGlobals.getCurrentMap().SAFE:
#		OverworldGlobals.loadFollowers()
	
	overworld_stats['stamina'] = 100.0 # DO NOT TOUCH STAMINA FOR BLESSINGS!
	
func resetVariables():
	for member in TEAM:
		member.reset()
	
	SAVE_NAME = null
	TEAM = [preload("res://resources/combat/combatants_player/Willis.tres")]
	TEAM_FORMATION = []
	#FOLLOWERS = []
	map_logs = {}
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

