extends CombatantSquad
class_name EnemyCombatantSquad

@export var enemy_pool: Array[ResEnemyCombatant]
@export var fill_empty: bool = false
@export var random_size: bool = false
@export var unique_id: String
#@export var TAMEABLE_CHANCE: float = 0.0
@export var turn_time: float = 0.0
@export var can_escape:bool = true
@export var do_reinforcements:bool = true
@export var reinforcements_turn:int = 50
var reward_bank ={'experience':0.0, 'loot':{}}

func _ready():
	unique_id = get_parent().name
	if fill_empty:
		pickRandomEnemies()

func setProperties(properties: Dictionary):
	for key in properties.keys():
		set(key, properties[key])

func pickRandomEnemies():
	if random_size:
		randomize()
		combatant_squad.resize(randi_range(1,4))
	
	for index in range(combatant_squad.size()):
		if combatant_squad[index] != null: continue
		var valid_enemies = enemy_pool.filter(
			func(enemy):
				if index <= 1:
					return enemy.preferred_position == 0
				elif index <= 3:
					return enemy.preferred_position == 1
		)
		if valid_enemies.is_empty():
			continue
		var enemy = valid_enemies.pick_random()
		combatant_squad[index] = enemy

func getMajorityFaction()-> int:
	var faction_count = {}
	for faction in range(CombatGlobals.Enemy_Factions.size()):
		faction_count[faction] = 0
	var combatants = combatant_squad.filter(func(combatant): return combatant != null)
	for combatant in combatants:
		faction_count[combatant.faction] += 1
	
	return faction_count.find_key(faction_count.values().max())
	
func getRawDrops():
	var drops = {}
	for member in combatant_squad:
		if member == null: continue
		drops.merge(member.getDrops())
		drops.merge(member.getBarterDrops())
	return drops

func addDrops():
	var loot_drops = getRawDrops()
	for loot in loot_drops.keys():
		if get_parent().patroller_group.reward_bank['loot'].keys().has(loot):
			get_parent().patroller_group.reward_bank['loot'][loot] += loot_drops[loot]
		else:
			get_parent().patroller_group.reward_bank['loot'][loot] = loot_drops[loot]

func getExperience():
	var out = 0
	for member in combatant_squad:
		if member == null: continue
		out += member.getExperience()
	return out
