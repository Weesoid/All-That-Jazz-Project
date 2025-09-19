extends Resource
class_name CombatantSaveData

@export var charms: Dictionary
@export var stat_values: Dictionary
@export var base_stat_values: Dictionary
@export var mandatory:bool
@export var lingering_effects:Array[String]
@export var initialized:bool
@export var stat_points: int
@export var stat_point_allocations: Dictionary
@export var temperment: Array[String]
@export var file_references: Dictionary

func _init(
	p_charms = {},
	p_stat_values = {},
	p_base_stat_values = {},
	p_mandatory = false,
	p_lingering_effects = [],
	p_initialized = false,
	p_stat_points = 0,
	p_stat_point_allocations = {},
	p_temperment = [],
	p_file_references = {}
):
	#lingering_effects.assign(p_lingering_effects)
	charms = saveCharms(p_charms)
	stat_values = p_stat_values
	base_stat_values = p_base_stat_values
	mandatory = p_mandatory
	lingering_effects.assign(p_lingering_effects)
	initialized = p_initialized
	stat_points = p_stat_points
	stat_point_allocations = p_stat_point_allocations
	temperment.assign(p_temperment)
	file_references = p_file_references

func loadData(combatant: ResPlayerCombatant):
	combatant.charms = loadCharms()
	combatant.mandatory = mandatory
	combatant.lingering_effects = lingering_effects
	combatant.initialized = initialized
	combatant.stat_points = stat_points
	combatant.stat_point_allocations = stat_point_allocations
	combatant.temperment = temperment
	combatant.file_references = file_references

func saveCharms(p_charms):
	var i = 0
	var out = {}
	for key in p_charms.keys():
		if p_charms[key] == null:
			out[i] = ''
		else:
			out[i] = p_charms[key].parent_item
		i += 1
	
	return out

func loadCharms():
	var i = 0
	var out = {}
	for charm in charms.keys():
		if !FileAccess.file_exists(charms[charm]):
			out[i] = null
		else:
			var loaded_charm = load(charms[charm])
			loaded_charm.parent_item = charms[charm]
			out[i] = loaded_charm
		i += 1
	
	return out
