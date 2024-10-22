extends ResCombatant
class_name ResEnemyCombatant

@export var FACTION: CombatGlobals.Enemy_Factions
@export var ELITE: bool = false
@export var AI_PACKAGE: GDScript
@export var CHANCE_TO_DROP = 0.50
@export var DROP_COUNT = 1
## Key: Item to be dropped; Value: Vector2 representing drop chance (x) & drop count (y)
@export var DROP_POOL = {}
@export var is_converted: bool
@export var tamed_combatant: ResPlayerCombatant

var SPAWN_ON_DEATH: ResCombatant

func initializeCombatant():
	SCENE = PACKED_SCENE.instantiate()
	SCENE.combatant_resource = self
	applyStatusEffects()
	BASE_STAT_VALUES = STAT_VALUES.duplicate()

func act():
	enemy_turn.emit()

func applyStatusEffects():
	for effect in LINGERING_STATUS_EFFECTS:
		CombatGlobals.addStatusEffect(self, effect)

func selectTarget(combatant_array: Array[ResCombatant])-> ResCombatant:
	return AI_PACKAGE.selectTarget(combatant_array)

func getExperience():
	var out = 0
	if BASE_STAT_VALUES.is_empty(): 
		BASE_STAT_VALUES = STAT_VALUES
	
	for key in BASE_STAT_VALUES.keys():
#		if BASE_STAT_VALUES[key] <= 1.0:
		out += BASE_STAT_VALUES[key]
	
	return int(out * 2.0)

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

func getRawDrops():
	var drops = {}
	
	for i in range(DROP_COUNT):
		if CombatGlobals.randomRoll(CHANCE_TO_DROP): 
			var item = rollDrops()
			if drops.has(item):
				drops[item] += randi_range(1, DROP_POOL[item].y)
			else:
				drops[item] = randi_range(1, DROP_POOL[item].y)
	
	return drops

func rollDrops():
	var total_weight = 0
	var cum_weight = 0
	
	for weight in DROP_POOL.values():
		total_weight += weight.x
	
	var random_num = randf_range(0,total_weight)
	for drop in DROP_POOL:
		cum_weight += DROP_POOL[drop].x
		if random_num <= cum_weight: return drop
