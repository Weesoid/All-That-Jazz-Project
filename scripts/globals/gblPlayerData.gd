# Rename this to gblPlayerData
extends Node

var save_name
var team: Array[ResPlayerCombatant]
var team_formation: Array[ResCombatant]
var map_logs: Dictionary = {}
var power: GDScript
var known_powers: Array = [load("res://resources/powers/Stealth.tres")]
var equipped_arrow: ResProjectileAmmo
var equipped_blessing: ResBlessing
var currency = 100
var team_level = 1
var max_team_level = 5
var current_exp = 0
var progression_data: Dictionary = {} # This'll be handy later...
var unlocked_abilities: Dictionary = {}
var added_abilities: Dictionary = {}
var current_stalker: ResStalkerData
var overworld_stats: Dictionary = {
	'stamina': 100.0,
	'bow_max_draw': 5.0,
	'walk_speed': 100.0,
	'sprint_speed': 200.0,
	'sprint_drain': 0.25,
	'stamina_gain': 0.15
}
# TEMPERMENTS!
var primary_temperments: Dictionary = {
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
var secondary_temperments: Dictionary = {
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

signal level_up

func _ready():
	initializeBenchedTeam()
	#addExperience(99)

func initializeBenchedTeam():
	if PlayerGlobals.team.is_empty():
		return
	
	for member in team:
		if !member.initialized:
			member.initializeCombatant(false)

func getTeamMemberNames():
	var out = []
	for combatant in team:
		out.append(combatant.NAME)
	return out

func getTeamMember(member_name: String)-> ResPlayerCombatant:
	for member in team:
		if member.NAME == member_name: return member
	
	return null

func applyBlessing(blessing):
	if blessing is String and !blessing.contains('res://'):
		blessing = load("res://resources/blessings/%s.tres" % blessing)
	elif blessing is String:
		blessing = load(blessing).instantiate()
		OverworldGlobals.getPlayer().add_child(blessing)
	
	if equipped_blessing != null and blessing is ResBlessing:
		equipped_blessing.setBlessing(false)
	if blessing is ResBlessing:
		equipped_blessing = blessing
		OverworldGlobals.showPrompt('You have been graced by blessing of the [color=yellow]%s[/color].' % blessing.blessing_name)
		blessing.setBlessing(true)

func equipNewArrowType():
	var arrows: Array = InventoryGlobals.inventory.filter(func(item): return item is ResProjectileAmmo)
	arrows.sort_custom(func(a, b): return a.STACK > b.STACK)
	if !InventoryGlobals.hasItem(PlayerGlobals.equipped_arrow) and !arrows.is_empty():
		arrows[0].equip()
		return true
	
	return false

#********************************************************************************
# COMBATANT MANAGEMENT
#********************************************************************************
func addExperience(experience: int, show_message:bool=false, bypass_cap:bool=false):
#	if team_level >= max_team_level and !bypass_cap:
#		OverworldGlobals.showPrompt('Max party level reached!')
#		return
	if show_message and !OverworldGlobals.getPlayer().has_node('ExperienceGainBar'):
		var experience_bar_view = load("res://scenes/user_interface/ExperienceGainBar.tscn").instantiate()
		experience_bar_view.added_exp = experience
		OverworldGlobals.getPlayer().add_child(experience_bar_view)
	current_exp += experience
	if team_level >= max_team_level and current_exp >= getRequiredExp() and !bypass_cap:
		current_exp = getRequiredExp()
		OverworldGlobals.showPrompt('Max level already reached!')
		return
	if current_exp >= getRequiredExp() and (team_level < max_team_level or bypass_cap):
		var prev_required = getRequiredExp()
		var prev_exp = current_exp
		team_level += 1
		current_exp = 0
		if team_level <= max_team_level:
			levelUpCombatants()
			if prev_exp - prev_required > 0:
				addExperience(prev_exp - prev_required, show_message, bypass_cap)
		elif team_level >= max_team_level:
			OverworldGlobals.showPrompt('Max party level reached!')
	elif current_exp < 0:
		current_exp = 0

func levelUpTeam():
	addExperience(getRequiredExp()-current_exp, true)

func getRequiredExp() -> int:
	var baseExp = 500.0
	var expMultiplier = 1.25
	#print(team_level)
	var gain = pow(expMultiplier ** (team_level - 1), 1.0/3.0) * baseExp # Chng to cubrrt
	return int(gain)

func increaseLevelCap(amount:int=5):
	max_team_level += amount
	if current_exp >= getRequiredExp():
		addExperience(1, true)
	OverworldGlobals.showPrompt('Level cap increased to [color=yellow]%s[/color]!' % max_team_level)

func getLevelTier():
	if team_level < 5:
		return 1
	elif team_level >= 5 and team_level < 10:
		return 2
	elif team_level >= 10 and team_level < 15:
		return 3
	elif team_level > 15:
		return 4

func addCurrency(value: int):
	if value + currency < 0:
		currency = 0
	else:
		currency += value

func unlockAbility(combatant: ResPlayerCombatant, ability: ResAbility):
	if unlocked_abilities.keys().has(combatant):
		unlocked_abilities[combatant].append(ability)
	else:
		unlocked_abilities[combatant] = []
		unlocked_abilities[combatant].append(ability)

func addAbility(combatant, ability):
	if combatant is String:
		for member in team: 
			if member.NAME == combatant:
				combatant = member
				break
	if ability is String:
		ability = load("res://resources/combat/abilities/%s.tres" % ability)
	
	if added_abilities.keys().has(combatant):
		added_abilities[combatant].append(ability)
	else:
		added_abilities[combatant] = []
		added_abilities[combatant].append(ability)
	OverworldGlobals.showPrompt('[color=yellow]%s[/color] learnt [color=yellow]%s[/color]!' % [combatant.NAME, ability.NAME])
	loadAddedAbilities()

func addPower(power_file_name: String):
	if FileAccess.file_exists("res://resources/powers/%s.tres" % power_file_name):
		var power = load("res://resources/powers/%s.tres" % power_file_name)
		known_powers.append(power)
		OverworldGlobals.showPrompt('Willis learnt the power of [color=yellow]%s[/color]!' % power.NAME)

func loadAddedAbilities():
	for member in team:
		if added_abilities.keys().has(member): 
			member.ABILITY_POOL.append_array(added_abilities[member])

func hasAbility(combatant: ResPlayerCombatant, ability: ResAbility):
	return combatant.ABILITY_POOL.has(ability)

func hasUnlockedAbility(combatant: ResPlayerCombatant, ability: ResAbility):
	return (unlocked_abilities.keys().has(combatant) and unlocked_abilities[combatant].has(ability)) or ability.required_level == 0

func hasActiveTeam()-> bool:
	return !OverworldGlobals.getCombatantSquad('Player').is_empty()

func levelUpCombatants():
	for combatant in PlayerGlobals.team:
		combatant.STAT_POINTS += 1
		combatant.scaleStats()
	OverworldGlobals.showPrompt('Party leveled up to [color=yellow]%s[/color]!' % [team_level])
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
		combatant.TEMPERMENT['primary'].append(PlayerGlobals.primary_temperments.keys().pick_random())
	if combatant.TEMPERMENT['secondary'] == []:
		combatant.TEMPERMENT['secondary'].append(PlayerGlobals.secondary_temperments.keys().pick_random())
	combatant.STAT_POINTS = team_level
	team.append(combatant)
	OverworldGlobals.showPrompt('[color=yellow]%s[/color] joined your posse!' % combatant.NAME)

func removeCombatant(combatant_id: ResPlayerCombatant):
	for member in team:
		if member == combatant_id: 
			member.reset()
			team.erase(member)
			break
	var removed_combatants = []
	for member in OverworldGlobals.getCombatantSquad('Player'):
		if !team.has(member): removed_combatants.append(member)
	for member in removed_combatants:
		OverworldGlobals.getCombatantSquad('Player').erase(member)
	team_formation = OverworldGlobals.getPlayer().squad.combatant_squad
	overwriteTeam()

func loadSquad():
	OverworldGlobals.setCombatantSquad('Player', PlayerGlobals.team_formation)

func addCombatantTemperment(combatant: ResPlayerCombatant, temperment: String='/random'):
	if combatant.TEMPERMENT['secondary'].size() >= 6:
		var removed_temperment = combatant.TEMPERMENT['secondary'][0]
		combatant.TEMPERMENT['secondary'].remove_at(0)
		OverworldGlobals.showPrompt('[color=yellow]%s[/color] lost [color=yellow]%s[/color]' % [combatant, removed_temperment.capitalize()])
	
	if temperment == '/random':
		randomize()
		var random_temperment = secondary_temperments.keys().filter(func(key): return !combatant.TEMPERMENT['secondary'].has(key)).pick_random()
		OverworldGlobals.showPrompt('[color=yellow]%s[/color] gained [color=yellow]%s[/color]' % [combatant, random_temperment.capitalize()])
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
	for combatant in team:
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

func addCommaToNum(value: int=currency) -> String:
	var str_value: String = str(value)
	var loop_end: int = 0 if value > -1 else 1
	for i in range(str_value.length()-3, loop_end, -3):
		str_value = str_value.insert(i, ",")
	return str_value

func overwriteTeam():
	var current_save = load("res://saves/%s.tres" % PlayerGlobals.save_name)
	for data in current_save.save_data:
		if data is PlayerSaveData: 
			data.team = team
			data.team_formation = team_formation
			break
	ResourceSaver.save(current_save, "res://saves/%s.tres" % PlayerGlobals.save_name)
	#return sa

func saveData(save_data: Array):
	var data: PlayerSaveData = PlayerSaveData.new()
	data.team = team
	#data.FOLLOWERS = FOLLOWERS
	data.power = power
	data.equipped_arrow = equipped_arrow
	data.currency = currency
	data.team_level = team_level
	data.current_exp = current_exp
	data.map_logs = map_logs
	data.known_powers = known_powers
#	data.overworld_stats['stamina'] = stamina
#	data.overworld_stats['bow_max_draw']= bow_max_draw
#	data.overworld_stats['walk_speed'] = walk_speed
#	data.sprint_speed = sprint_speed
#	data.sprint_drain = sprint_drain
#	data.stamina_gain = stamina_gain
	data.progression_data = progression_data
	data.team_formation = team_formation
	data.equipped_blessing = equipped_blessing
	data.unlocked_abilities = unlocked_abilities
	data.added_abilities = added_abilities
	data.max_team_level = max_team_level
	
	for combatant in team:
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
	OverworldGlobals.getPlayer().squad.combatant_squad.clear()
	team = save_data.team
	power = save_data.power
	equipped_arrow = save_data.equipped_arrow
	currency = save_data.currency
	team_level = save_data.team_level
	current_exp = save_data.current_exp
	map_logs = save_data.map_logs
	progression_data = save_data.progression_data
	team_formation = save_data.team_formation
	equipped_blessing = save_data.equipped_blessing
	unlocked_abilities = save_data.unlocked_abilities
	added_abilities = save_data.added_abilities
	max_team_level = save_data.max_team_level
	known_powers = save_data.known_powers
	if equipped_blessing != null: equipped_blessing.setBlessing(true)
	
	initializeBenchedTeam()
	OverworldGlobals.initializePlayerParty()
	OverworldGlobals.setCombatantSquad('Player', team_formation)
	loadAddedAbilities()
	for combatant in team:
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
	for member in team:
		member.reset()
	
	save_name = null
	team = [preload("res://resources/combat/combatants_player/Willis.tres")]
	team_formation = []
	#FOLLOWERS = []
	map_logs = {}
	power = null
	known_powers = [load("res://resources/powers/Stealth.tres")]
	equipped_arrow = null
	equipped_blessing = null
	currency = 100
	team_level = 1
	max_team_level = 5
	current_exp = 0
	progression_data = {}
	unlocked_abilities = {}
	added_abilities = {}
	overworld_stats = {
		'stamina': 100.0,
		'bow_max_draw': 5.0,
		'walk_speed': 100.0,
		'sprint_speed': 200.0,
		'sprint_drain': 0.25,
		'stamina_gain': 0.15
	}

