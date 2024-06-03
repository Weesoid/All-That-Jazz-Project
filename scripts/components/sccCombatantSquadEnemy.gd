# TASKS
# 1. Determine HOW MANY combatants should spawn (Based on morale?)
# 2. Determine WHAT TIER combatants should spawn (Location basis?)
extends CombatantSquad
class_name EnemyCombatantSquad

@export var ENEMY_POOL: Array[ResEnemyCombatant]
@export var FILL_EMPTY: bool = false
@export var RANDOM_SIZE: bool = false
@export var UNIQUE_ID: String
var afflicted_status_effects: Array[String]

func _ready():
	if FILL_EMPTY:
		pickRandomEnemies()

func addLingeringEffect(status_effect_name: String):
	afflicted_status_effects.append(status_effect_name)

func removeLingeringEffect(status_effect_name: String):
	afflicted_status_effects.erase(status_effect_name)

func pickRandomEnemies():
	randomize()
	if RANDOM_SIZE:
		COMBATANT_SQUAD.resize(COMBATANT_SQUAD.size() - randi_range(0, COMBATANT_SQUAD.size()-2))
	
	for index in range(COMBATANT_SQUAD.size()):
		if COMBATANT_SQUAD[index] != null: continue
		COMBATANT_SQUAD[index] = ENEMY_POOL.pick_random()

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

func getExperience():
	for member in COMBATANT_SQUAD:
		PlayerGlobals.addExperience(member.getExperience())
