extends ResCombatant
class_name ResPlayerCombatant

@export var ability_pool: Array[ResAbility]
@export var guard_effect: ResStatusEffect = load("res://resources/combat/status_effects/Riposte.tres")
@export var base_traits: Array[String] = []
@export var follower_texture: Texture
@export var mandatory = false
@export var rest_sprite:  Texture = load("res://images/sprites/rest_unknown.png")
@export var stat_multiplier = 0.01
@export var talents: Array[String]

var file_references: Dictionary = {
	'active_abilities': [],
	'equipped_weapon': ['',0], # [path, durability] ; Handles save data of equipped weapons.
	'active_talents': {}
}
var equipped_weapon: ResWeapon
var stat_points = 1
var charms = {
	0: null,
	1: null,
	2: null
}
var stat_point_allocations = {
	'damage': 0, # Hmmm what to do....... Change to dmg_modifier!
	'defense': 0,
	'handling': 0
} # Change to talent 
var active_talents = {}
var talent_list = {}
var traits: Array[String] = []
var base_health: int
var initialized = false
var max_strain:int=4

func loadTalents():
	talent_list['base_talents'] = ResourceGlobals.loadArrayFromPath("res://resources/combat/talents/base_talents/")
	
	for path in talents:
		talent_list[path] = ResourceGlobals.loadArrayFromPath("res://resources/combat/talents/%s/" % path)

func applyTalents():
	for talent in active_talents.keys():
		if talent is ResStatTalent:
			CombatGlobals.modifyStat(self, talent.getStatModifiers(active_talents[talent]), talent.name)
		elif talent is ResAbilityTalent:
			ability_pool[ability_pool.find(talent.affected_ability)].mutateProperties(talent.effects)

func getAbilityMutations():
	return active_talents.keys().filter(func(talent): return talent is ResAbilityTalent)

func applyAbilityMutations():
	clearAbilityMutations()
	for mutation in getAbilityMutations():
		ability_pool[ability_pool.find(mutation.affected_ability)].mutateProperties(mutation.effects)

func clearAbilityMutations():
	for ability in ability_pool.filter(func(ability): return ability.mutated):
		ability.restoreProperties()

func activateTalent(talent: ResTalent, count:int=1):
	if talent in active_talents.keys() and talent.max_rank < active_talents[talent]+1:
		return
	
	if talent not in active_talents.keys():
		active_talents[talent] = count
	else:
		active_talents[talent] += count
	
	file_references['active_talents'][talent.resource_path] = active_talents[talent]
	applyTalents()

func removeTalent(talent:ResTalent):
	if talent in active_talents.keys():
		if talent is ResStatTalent:
			CombatGlobals.resetStat(self,talent.name)
		elif talent is ResAbilityTalent:
			ability_pool[ability_pool.find(talent.affected_ability)].restoreProperties()
#		elif talent is ResStatusEffectTalent:
#			CombatGlobals.removeLingeringEffect(self, talent.status_effect)
		active_talents.erase(talent)
	
	file_references['active_talents'].erase(talent)

func initializeCombatant(do_scene:bool=true):
	if do_scene:
		combatant_scene = packed_scene.instantiate()
		combatant_scene.combatant_resource = self
	if !initialized:
		base_stat_values = stat_values.duplicate()
		base_health = stat_values['health']
		initialized = true
	if !stat_modifiers.keys().has('scaled_stats'):
		scaleStats()
	if !stat_modifiers.has('base_rebuke'):
		CombatGlobals.modifyStat(self, {'rebuke_chance':1.03},'base_rebuke')
	if !stat_values.has('strain'):
		stat_values['strain']=0
	if CombatGlobals.inCombat():
		applyStatusEffects()
	
	#loadActiveAbilities()
	if !base_traits.is_empty() and traits.is_empty():
		traits = base_traits

	
	loadTalents()
	applyTalents()
	applyAllTraits()
	applyTemporaryModifiers()
	applyStoredStatusEffects()

func getScenePreview():
	combatant_scene = packed_scene.instantiate()
	combatant_scene.combatant_resource = self
	#combatant_scene.collision.disabled = true
	return combatant_scene

func loadFileReferences():
	var remove = []
	
	for ability_path in file_references['active_abilities']:
		if !FileAccess.file_exists(ability_path):
			remove.append(ability_path)
			continue
		ability_set.append(load(ability_path))
	for talent_path in file_references['active_talents']:
		if !FileAccess.file_exists(talent_path):
			remove.append(talent_path)
			continue
		active_talents[load(talent_path)] = file_references['active_talents'][talent_path]
	
	for ability_path in remove:
		file_references['active_abilities'].erase(ability_path)
	remove.clear()
	
	
	if FileAccess.file_exists(file_references['equipped_weapon'][0]):
		var weapon = load(file_references['equipped_weapon'][0])
		weapon.equip(self)
		equipped_weapon.durability = file_references['equipped_weapon'][1]

func applyAllTraits():
	if traits.is_empty():
		return
	
	for t in traits:
		applyTrait(t,false)

func applyTrait(t,show_indicator,append_indicator:String=''):
	if (PlayerGlobals.trait_presets.keys().has(t) and !stat_modifiers.keys().has(t)):
		CombatGlobals.modifyStat(self, PlayerGlobals.trait_presets[t], t,true)
	elif t.split('/').size() > 1:
		var trait_data = t.split('/')
		CombatGlobals.modifyStat(self, JSON.parse_string(trait_data[1]), trait_data[0], false, show_indicator,append_indicator)

# Trait data is a dictionary that contains unique trait data. E.g. <Trait name>/{"damage":69}/{"disease":true} can be a element in the traits array
func addTrait(trait_name: String, stat_mods: Dictionary,data:Dictionary={},append_indicator:String=''):
	if data.has('append') and stat_modifiers.has(trait_name):
		stat_mods = CombatGlobals.appendStatModifications(stat_modifiers[trait_name],stat_mods)
	
	var input_trait = trait_name+'/'+JSON.stringify(stat_mods)
	if !data.is_empty():
		input_trait += '/'+JSON.stringify(data)
	
	# Filter out duplicate trait, replace with latest addition
	traits = traits.filter(func(t): return t.split('/')[0].to_lower() != trait_name.to_lower()) 
	traits.append(input_trait)
	
	if CombatGlobals.inCombat():
		applyTrait(input_trait,true,append_indicator)
	else:
		applyAllTraits()

func removeTrait(trait_name:String):
	removeStatModification(trait_name.split('/')[0])
	if traits.has(trait_name):
		traits.erase(trait_name)

func getTraitsWithFlag(key:String):
	var out = []
	for t in traits:
		var trait_data = t.split('/')
		if trait_data.size() >= 3 and trait_data[2].contains(key):
			out.append(t)
	
	return out

func scaleStats():
	var stat_increase = {}
	stat_increase['health'] = (base_health * (1 + ((PlayerGlobals.team_level-1)*0.1))) - base_health
	CombatGlobals.modifyStat(self, stat_increase, 'scaled_stats')

func updateCombatant(save_data: PlayerSaveData):
	loadFileReferences()
	var path = resource_path
	var percent_health = float(save_data.combatant_save_data[path].stat_values['health']) / float(save_data.combatant_save_data[path].base_stat_values['health'])
	stat_values['health'] = floor(base_stat_values['health'] * percent_health)

func act():
	player_turn.emit()

func applyStatusEffects():
	for charm in charms.values():
		if charm == null or charm.status_effect == null: 
			continue
		CombatGlobals.addStatusEffect(self, charm.status_effect.name)
#	for effect in lingering_effects:
#		CombatGlobals.addStatusEffect(self, effect)

#func isInflicted()-> bool:
#	return !lingering_effects.is_empty()

#func getLingeringEffectsString():
#	var out = 'During combat:\n'
#	for effect in lingering_effects:
#		var status_effect = CombatGlobals.loadStatusEffect(effect)
#		out += '%s - %s\n' % [status_effect.name, status_effect.description]
#	return out

func applyEquipmentModifications():
	for charm in charms:
		charm.applyStatModifications()

func getAllocationModifier()-> Dictionary:
	var out = stat_point_allocations.duplicate()
	out['resist'] = out['defense']
	for stat in out.keys():
		if (stat == 'handling' or stat == 'damage') and out.has(stat):
			out[stat] *= 1
		elif stat == 'defense' and out.has(stat):
			out['defense'] *= stat_multiplier
			out['resist'] *= stat_multiplier
	return out

func removeEquipmentModifications():
	for charm in charms:
		charm.removeStatModifications()

func equipWeapon(weapon: ResWeapon):
	if equipped_weapon != null:
		unequipWeapon()
		
	if InventoryGlobals.getItem(weapon) != null:
		InventoryGlobals.removeItemResource(weapon, 1, false, true)
		weapon.equip(self)
		file_references['equipped_weapon'] = [weapon.resource_path,weapon.durability]
		#print(file_references['equipped_weapon'])
		return

func unequipWeapon():
	if equipped_weapon != null:
		equipped_weapon.unequip()
		InventoryGlobals.addItemResource(equipped_weapon, 1, false, false)
		file_references['equipped_weapon'] = ['',0]
		equipped_weapon = null

func hasEquippedWeapon()-> bool:
	return equipped_weapon != null

func hasWeapon(weapon:ResWeapon):
	return equipped_weapon == weapon

func equipCharm(charm: ResCharm, slot: int):
	if InventoryGlobals.getItem(charm) != null:
		InventoryGlobals.removeItemResource(charm, 1, false, true)
		charm.equip(self)
		charms[slot] = charm
		return

func unequipCharm(slot: int):
	if charms[slot] == null:
		return
	
	charms[slot].unequip()
	CombatGlobals.resetStat(self, charms[slot].name)
	InventoryGlobals.addItemResource(charms[slot], 1, false, false)
	charms[slot] = null
	OverworldGlobals.playSound("res://audio/sounds/421418__jaszunio15__click_200.ogg")

func hasCharm(charm: ResCharm):
	for equipped_charm in charms.values():
		if equipped_charm == null: continue
		if equipped_charm.name == charm.name: return true

## This function is pretty cool. Keeping it!
func convertToEnemy(appended_name: String)-> ResEnemyCombatant:
	initializeCombatant(false)
	var enemy = ResEnemyCombatant.new()
	enemy.name = appended_name + ' ' +name
	enemy.packed_scene = packed_scene
	enemy.description = description
	enemy.stat_values = base_stat_values.duplicate()
	enemy.stat_values['health'] = base_health
	if ability_pool.size() < 4:
		for ability in ability_pool:
			enemy.ability_set.append(ability)
	else:
		enemy.ability_set.append(ability_pool[0])
		enemy.ability_set.append(ability_pool[1])
		enemy.ability_set.append(ability_pool[2])
		enemy.ability_set.append(ability_pool[3])
	enemy.ai_package = load("res://scripts/combat/combatant_ai/aiRandomAI.gd")
	enemy.is_converted = true
#	enemy.tamed_combatant = self
	return enemy.duplicate()

func reset():
	for modification in stat_modifiers.keys():
		removeStatModification(modification)
	if base_health != null:
		stat_values['health'] = base_health
	ability_set = []
	#lingering_effects = []
	equipped_weapon = null
	stat_points = 1
	stat_modifiers = {}
	charms = {
		0: null,
		1: null,
		2: null
	}
	stat_point_allocations = {
		'damage': 0,
		'defense': 0,
		'handling': 0
	}
	traits = []

