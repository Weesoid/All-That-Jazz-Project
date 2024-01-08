# Rename this to gblPlayerData
extends Node

var TEAM: Array[ResPlayerCombatant]
var CURRENCY = 0
var POWER: GDScript
var EQUIPPED_ARROW: ResProjectileAmmo
var UTILITY_CHARM_COUNT = 0
var PARTY_LEVEL = 1
var CURRENT_EXP = 0
var FOLLOWERS: Array[NPCFollower] = []
signal level_up


func _ready():
	CURRENCY = 100
	# Fix later
	EQUIPPED_ARROW = load("res://resources/items/Arrow.tres")
	EQUIPPED_ARROW.STACK = 0
	
	TEAM.append(preload("res://resources/combatants/p_PrototypeA.tres"))
	TEAM.append(preload("res://resources/combatants/p_PPrototypeB.tres"))
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

func levelUpCombatants():
	for combatant in PlayerGlobals.TEAM:
		print(combatant)
		combatant.ABILITY_POINTS += 1
		
		combatant.removeEquipmentModifications()
		for stat in combatant.BASE_STAT_VALUES.keys():
			var increase = combatant.STAT_GROWTH_RATES[stat] ** (PARTY_LEVEL - 1)
			#print('%s +%s' % [stat, combatant.STAT_GROWTH_RATES[stat]])
			combatant.BASE_STAT_VALUES[stat] += increase
			combatant.UNMODIFIED_STAT_VALUES[stat] += increase
		combatant.applyEquipmentModifications()
		#combatant.STAT_VALUES = combatant.BASE_STAT_VALUES
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

func loadSquad():
	for member in TEAM:
		if member.active: 
			OverworldGlobals.getCombatantSquad('Player').append(member)
