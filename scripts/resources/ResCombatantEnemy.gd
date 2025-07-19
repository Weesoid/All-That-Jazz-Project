extends ResCombatant
class_name ResEnemyCombatant

enum Tier {
	Easy,
	Medium,
	Hard,
	Very_Hard
}
enum PreferredPosition {
	FRONTLINE,
	BACKLINE
}

@export var FACTION: CombatGlobals.Enemy_Factions
@export var TIER: Tier
@export var PREFERRED_POSITION: PreferredPosition
@export var CHANCE_TO_DROP = 0.5
@export var DROP_COUNT = 1
## Key: Item to be dropped; Value: Vector2 representing drop chance (x) & drop count (y)
@export var DROP_POOL = {}
@export var is_converted: bool
@export var tamed_combatant: ResCombatant

var SPAWN_ON_DEATH: ResCombatant

func initializeCombatant():
	if AI_PACKAGE == null: 
		AI_PACKAGE = preload("res://scripts/combat/combatant_ai/aiRandomAI.gd")
	SCENE = PACKED_SCENE.instantiate()
	SCENE.combatant_resource = self
	applyStatusEffects()
	BASE_STAT_VALUES = STAT_VALUES.duplicate()
	scaleStats()

func act():
	enemy_turn.emit()

func applyStatusEffects():
	for effect in LINGERING_STATUS_EFFECTS:
		CombatGlobals.addStatusEffect(self, effect)

func selectTarget(combatant_array: Array[ResCombatant])-> ResCombatant:
	return AI_PACKAGE.selectTarget(combatant_array)

func getExperience():
	if BASE_STAT_VALUES.is_empty(): 
		BASE_STAT_VALUES = STAT_VALUES
	var hustle
	if BASE_STAT_VALUES['hustle'] < 0:
		hustle = 0
	else:
		hustle = BASE_STAT_VALUES['hustle']*2
	var gain = (BASE_STAT_VALUES["health"] * 0.2) + (BASE_STAT_VALUES["brawn"] * 100) + (BASE_STAT_VALUES["grit"] * 100) + BASE_STAT_VALUES["handling"] + hustle + ((BASE_STAT_VALUES["crit"] * BASE_STAT_VALUES["crit_dmg"]) * 100) + (BASE_STAT_VALUES["heal_mult"] * 1.5) + (BASE_STAT_VALUES["resist"] * 100)
	return ceil(gain)

func getDrops():
	if DROP_POOL.is_empty():
		return {}
	var drops = {}
	
	for i in range(DROP_COUNT):
		if CombatGlobals.randomRoll(CHANCE_TO_DROP): 
			var item = rollDrops()
			if drops.has(item):
				drops[item] += randi_range(1, DROP_POOL[item].y)
			else:
				drops[item] = randi_range(1, DROP_POOL[item].y)
	return drops

#func getRawDrops():
#	var drops = {}
#
#	for i in range(DROP_COUNT):
#		if CombatGlobals.randomRoll(CHANCE_TO_DROP): 
#			var item = rollDrops()
#			if drops.has(item):
#				drops[item] += randi_range(1, DROP_POOL[item].y)
#			elif !drops.is_empty():
#				drops[item] = randi_range(1, DROP_POOL[item].y)
#	drops.merge(getBarterDrops())
#
#	return drops

func getBarterDrops():
	var out = ceil(getExperience()/2)
	var denominations = [20, 50, 100, 500, 1000]
	var change = {}
	
	for denom in denominations:
		if out >= denom:
			change[InventoryGlobals.loadItemResource('BarterSalvage'+str(denom))] = int(out / denom)
			out -= int(out / denom)
	
	return change

func rollDrops():
	var total_weight = 0
	var cum_weight = 0
	
	for weight in DROP_POOL.values():
		total_weight += weight.x
	
	var random_num = randf_range(0,total_weight)
	for drop in DROP_POOL:
		cum_weight += DROP_POOL[drop].x
		if random_num <= cum_weight: return drop
