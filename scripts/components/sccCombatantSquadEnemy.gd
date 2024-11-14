# TASKS
# 1. Determine HOW MANY combatants should spawn (Based on morale?)
# 2. Determine WHAT TIER combatants should spawn (Location basis?)
extends CombatantSquad
class_name EnemyCombatantSquad

@export var ENEMY_POOL: Array[ResEnemyCombatant]
@export var FILL_EMPTY: bool = false
@export var RANDOM_SIZE: bool = false
@export var UNIQUE_ID: String
@export var TAMEABLE_CHANCE: float = 0.0
@export var TURN_TIME: float = 0.0
@export var CAN_ESCAPE:bool = true
@export var DO_REINFORCEMENTS:bool = true
@export var REINFORCEMENTS_TURN:int = 50
var afflicted_status_effects: Array[String]

func _ready():
	if FILL_EMPTY:
		pickRandomEnemies()

func addLingeringEffect(status_effect_name: String):
	print('Appending: ', status_effect_name)
	afflicted_status_effects.append(status_effect_name)

func removeLingeringEffect(status_effect_name: String):
	afflicted_status_effects.erase(status_effect_name)

func pickRandomEnemies():
	randomize()
	if RANDOM_SIZE:
		COMBATANT_SQUAD.resize(COMBATANT_SQUAD.size() - randi_range(0, COMBATANT_SQUAD.size()-2))
	
	for index in range(COMBATANT_SQUAD.size()):
		if COMBATANT_SQUAD[index] != null: continue
		var enemy = ENEMY_POOL.pick_random()
		COMBATANT_SQUAD[index] = enemy
	
func getMusic()-> int:
	var faction_count = {}
	for faction in range(CombatGlobals.Enemy_Factions.size()):
		faction_count[faction] = 0
	for combatant in COMBATANT_SQUAD:
		faction_count[combatant.FACTION] += 1
	
	return faction_count.find_key(faction_count.values().max())

func getRawDrops():
	var drops = {}
	for member in COMBATANT_SQUAD:
		drops.merge(member.getRawDrops())
	return drops

func addDrops():
	var loot_drops = getRawDrops()
	for loot in loot_drops.keys():
		if OverworldGlobals.getCurrentMap().REWARD_BANK['loot'].keys().has(loot):
			OverworldGlobals.getCurrentMap().REWARD_BANK['loot'][loot] += loot_drops[loot]
		else:
			OverworldGlobals.getCurrentMap().REWARD_BANK['loot'][loot] = loot_drops[loot]

func getExperience():
	var out = 0
	for member in COMBATANT_SQUAD:
		out += member.getExperience()
	return out
