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
#@export var drop_count = 1
## Key: Item to be dropped; Value: Vector2 representing drop chance (x) & drop count (y)
@export var drop_pool:Array[ResEnemyDrops] = []
@export var is_converted: bool
@export var experience_multiplier:float = 1.0
# @export var tamed_combatant: ResCombatant

var spawn_on_death: ResCombatant
var items_dropped:bool=false

func initializeCombatant():
	if ai_package == null: 
		ai_package = load("res://scripts/combat/combatant_ai/aiRandomAI.gd")
	combatant_scene = packed_scene.instantiate()
	combatant_scene.combatant_resource = self
	base_stat_values = stat_values.duplicate()
	scaleStats()
	#applyStatusEffects()
	#loadAbilities()
	clearAbilityMutations()
	applyStoredStatusEffects()

func act():
	enemy_turn.emit()

#func applyStatusEffects():
#	for effect in lingering_effects:
#		CombatGlobals.addStatusEffect(self, effect)

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
	# TODO Revalue this
	var gain = 100
	return ceil(gain)*experience_multiplier

func getDrops():
	if drop_pool.is_empty(): return {}
	var drops = {}
	
	for dropped_item in drop_pool:
		if !CombatGlobals.randomRoll(dropped_item.drop_chance): continue
		drops[dropped_item.item] = dropped_item.getDropCount()

#		if drops.has(item):
#			drops[item] += randi_range(1, drop_pool[item].y)
#		else:
#			drops[item] = randi_range(1, drop_pool[item].y)
	
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
