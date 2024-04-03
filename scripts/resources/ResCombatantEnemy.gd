extends ResCombatant
class_name ResEnemyCombatant

@export var AI_PACKAGE: GDScript
@export var CHANCE_TO_DROP = 0.50
@export var DROP_COUNT = 1
## Key: Item to be dropped; Value: Vector2 representing drop chance (x) & drop count (y)
@export var DROP_POOL = {}

# NOTE: Enemy combatants don't get the stat modifications of their gear.
# They do get the ARMOR TYPE and STATUS EFFECTS on armors and charms
# Set the auto-attack manually.
func initializeCombatant():
	SCENE = PACKED_SCENE.instantiate()
	
	for effect in STATUS_EFFECTS:
		effect.initializeStatus()
	
	BASE_STAT_VALUES = STAT_VALUES.duplicate()

func act():
	enemy_turn.emit()

func selectTarget(combatant_array: Array[ResCombatant])-> ResCombatant:
	return AI_PACKAGE.selectTarget(combatant_array)

func getExperience():
	var out = 0
	for key in BASE_STAT_VALUES.keys():
		if key == "health": continue
		out += BASE_STAT_VALUES[key]
	return out

func getDrops():
	if DROP_POOL.is_empty():
		return ''
	
	var drops = {}
	var drops_summary = ''
	
	for i in range(DROP_COUNT):
		#print('Roll ', i)
		if CombatGlobals.randomRoll(CHANCE_TO_DROP): 
			var item = rollDrops()
			#print('Dropped: ', item.NAME)
			if drops.has(item):
				drops[item] += randi_range(1, DROP_POOL[item].y)
			else:
				drops[item] = randi_range(1, DROP_POOL[item].y)
			#print(drops)
	
	for item in drops:
		InventoryGlobals.addItemResource(item, drops[item])
		if item is ResStackItem:
			CombatGlobals.getCombatScene().combat_log.writeCombatLog('%s dropped [color=yellow]x%s %s[/color]!' % [NAME, drops[item], item.NAME])
			drops_summary += 'x%s %s\n' % [drops[item], item.NAME]
		else:
			CombatGlobals.getCombatScene().combat_log.writeCombatLog('%s dropped [color=yellow]%s[/color]' % [NAME, item.NAME])
			drops_summary += '%s\n' % item.NAME
	
	return drops_summary

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
