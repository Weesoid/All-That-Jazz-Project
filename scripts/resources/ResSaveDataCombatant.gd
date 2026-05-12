extends Resource
class_name CombatantSaveData

@export var charms: Dictionary
@export var stat_values: Dictionary
@export var base_stat_values: Dictionary
@export var mandatory:bool
#@export var lingering_effects:Array[String]
@export var initialized:bool
@export var stat_points: int
#@export var stat_point_allocations: Dictionary
@export var traits: Array[String]
@export var file_references: Dictionary
@export var temp_modifier_tracker: Dictionary
@export var assigned_position:int
#@export var item_strain_tracker: Dictionary

func _init(
	p_charms = {},
	p_stat_values = {},
	p_base_stat_values = {},
	p_mandatory = false,
	#p_lingering_effects = [],
	p_initialized = false,
	p_stat_points = 0,
	#p_stat_point_allocations = {},
	p_traits = [],
	p_file_references = {},
	p_temp_modifier_tracker = {},
	p_assigned_position=-1
	#p_item_strain_tracker = {}
):
	#lingering_effects.assign(p_lingering_effects)
	charms = saveCharms(p_charms)
	stat_values = p_stat_values
	base_stat_values = p_base_stat_values
	mandatory = p_mandatory
	#lingering_effects.assign(p_lingering_effects)
	initialized = p_initialized
	stat_points = p_stat_points
	#stat_point_allocations = p_stat_point_allocations
	traits.assign(p_traits)
	file_references = p_file_references
	temp_modifier_tracker = p_temp_modifier_tracker
	assigned_position = p_assigned_position
	#item_strain_tracker = p_item_strain_tracker

func loadData(combatant: ResPlayerCombatant):
	combatant.charms = loadCharms()
	combatant.mandatory = mandatory #NOTE: Might need to return if you have to change mando flag dynamically (e.g. character is mando for a certain time)
	#combatant.lingering_effects = lingering_effects.filter(func(effect): return FileAccess.file_exists("res://resources/combat/status_effects/"+effect+".tres"))
	combatant.initialized = initialized
	combatant.stat_points = stat_points
	#combatant.stat_point_allocations = stat_point_allocations
	combatant.traits = loadTraits()
	combatant.file_references = file_references
	combatant.temp_modifier_tracker = temp_modifier_tracker
	combatant.assigned_position = assigned_position
	#combatant.item_strain_tracker = item_strain_tracker

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

func loadTraits():
	var out: Array[String] = []
	for temp in traits:
		if temp.contains('|'):
			var path = "res://resources/combat/status_effects/"+temp.split('|')[1].replace(' ', '')+".tres"
			if FileAccess.file_exists(path): out.append(temp)
		else:
			out.append(temp)
	
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

#func loadTalents():
#	var valid_talents = []
#	for talent_path in file_references['active_talents']:
#		if !ResourceLoader.has_cached(talent_path): continue
#
#		var updated_talent = ResourceLoader.load(talent_path)
#		var recorded_rank = file_references['active_talents'][talent_path]
		
#		if !ResourceLoader.has_cached(talent_path):
#			remove.append(talent_path)
#			stat_points += updated_talent.getCost(recorded_rank)
#			continue
#
#		active_talents[load(talent_path)] = file_references['active_talents'][talent_path]
