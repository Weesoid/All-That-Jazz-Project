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

@export var faction: CombatGlobals.Enemy_Factions
@export var tier: Tier
@export var preferred_position: PreferredPosition
@export var chance_to_drop = 0.5
@export var drop_count = 1
## Key: Item to be dropped; Value: Vector2 representing drop chance (x) & drop count (y)
@export var drop_pool = {}
@export var is_converted: bool
# @export var tamed_combatant: ResCombatant

var spawn_on_death: ResCombatant

func initializeCombatant():
	if ai_package == null: 
		ai_package = load("res://scripts/combat/combatant_ai/aiRandomAI.gd")
	combatant_scene = packed_scene.instantiate()
	combatant_scene.combatant_resource = self
	base_stat_values = stat_values.duplicate()
	scaleStats()
	applyStatusEffects()

func act():
	enemy_turn.emit()

func applyStatusEffects():
	for effect in lingering_effects:
		CombatGlobals.addStatusEffect(self, effect)

func selectTarget(combatant_array: Array[ResCombatant])-> ResCombatant:
	return ai_package.selectTarget(combatant_array)

func getExperience():
	if base_stat_values.is_empty(): 
		base_stat_values = stat_values
	var hustle
	if base_stat_values['speed'] < 0:
		hustle = 0
	else:
		hustle = base_stat_values['speed']*2
	var gain = (base_stat_values["health"] * 0.2) + (base_stat_values["damage"]) + (base_stat_values["defense"] * 100) + base_stat_values["handling"] + hustle + ((base_stat_values["crit"] * base_stat_values["crit_dmg"]) * 100) + (base_stat_values["heal_mult"] * 1.5) + (base_stat_values["resist"] * 100)
	return ceil(gain)

func getDrops():
	if drop_pool.is_empty():
		return {}
	var drops = {}
	
	for i in range(drop_count):
		if CombatGlobals.randomRoll(chance_to_drop): 
			var item = rollDrops()
			if drops.has(item):
				drops[item] += randi_range(1, drop_pool[item].y)
			else:
				drops[item] = randi_range(1, drop_pool[item].y)
	return drops

#func getRawDrops():
#	var drops = {}
#
#	for i in range(drop_count):
#		if CombatGlobals.randomRoll(chance_to_drop): 
#			var item = rollDrops()
#			if drops.has(item):
#				drops[item] += randi_range(1, drop_pool[item].y)
#			elif !drops.is_empty():
#				drops[item] = randi_range(1, drop_pool[item].y)
#	drops.merge(getBarterDrops())
#
#	return drops

func getBarterDrops():
	var out = ceil(getExperience())
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
	
	for weight in drop_pool.values():
		total_weight += weight.x
	
	var random_num = randf_range(0,total_weight)
	for drop in drop_pool:
		cum_weight += drop_pool[drop].x
		if random_num <= cum_weight: return drop
