extends ResCombatant
class_name ResPlayerCombatant

@export var ability_pool: Array[ResAbility]
@export var guard_effect: ResStatusEffect = load("res://resources/combat/status_effects/Riposte.tres")
@export var base_temperment: Dictionary = {'primary':[], 'secondary':[]}
@export var follower_texture: Texture
@export var mandatory = false
@export var stat_multiplier = 0.01

var equipped_weapon: ResWeapon
var stat_points = 1
var charms = {
	0: null,
	1: null,
	2: null
}
var stat_point_allocations = {
	'brawn': 0,
	'grit': 0,
	'handling': 0
}
var temperment: Dictionary = {'primary':[], 'secondary':[]}
var base_health: int
var initialized = false

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
	if CombatGlobals.inCombat():
		applyStatusEffects()
	if !temperment['primary'] is Array:
		temperment['primary'] = []
		temperment['secondary'] = []
	if temperment['primary'] == [] and temperment['secondary'] == []:
		temperment = base_temperment
	applyTemperments()

func applyTemperments(update:bool = false):
	if temperment['primary'].is_empty():
		return
	if !temperment['primary'] is Array:
		temperment['primary'] = []
		temperment['secondary'] = []
		applyTemperments()
		return
	
	for temperment in temperment['primary']:
		if !stat_modifiers.keys().has('pt_'+temperment) or update:
			CombatGlobals.modifyStat(self, PlayerGlobals.primary_temperments[temperment], 'pt_'+temperment)
	for temperment in temperment['secondary']:
		if !stat_modifiers.keys().has('st_'+temperment) or update:
			CombatGlobals.modifyStat(self, PlayerGlobals.secondary_temperments[temperment], 'st_'+temperment)

func scaleStats():
	var stat_increase = {}
	stat_increase['health'] = (base_health * (1 + ((PlayerGlobals.team_level-1)*0.1))) - base_health
	CombatGlobals.modifyStat(self, stat_increase, 'scaled_stats')

func updateCombatant(save_data: PlayerSaveData):
	var remove_abilities = ability_set.filter(func(ability): return !ability_pool.has(ability))
	for ability in remove_abilities:
		ability_set.erase(ability)
	
	# Debug code.!
	#var percent_health = float(save_data.combatant_save_data[self][2]['health']) / float(save_data.combatant_save_data[self][3]['health'])
#	if name == 'Willis Flynn':
#		print('======= ', name, ' =======')
#		print('BaseHealth: ', stat_values['health'])
#		print('Dividing: ',save_data.combatant_save_data[self][2]['health'], ' / ', save_data.combatant_save_data[self][3]['health'])
#		print('% left: ', percent_health)
#		print(base_stat_values['health'], ' * ', percent_health, ' = ', base_stat_values['health'] * percent_health)
#		print('Floored: ', floor(base_stat_values['health'] * percent_health))
	stat_values['health'] = floor(base_stat_values['health']) #* percent_health)

func act():
	player_turn.emit()

func applyStatusEffects():
	for charm in charms.values():
		if charm == null or charm.status_effect == null: continue
		CombatGlobals.addStatusEffect(self, charm.status_effect.name)
	for effect in lingering_effects:
		CombatGlobals.addStatusEffect(self, effect)

func isInflicted()-> bool:
	return !lingering_effects.is_empty()

func getLingeringEffectsString():
	var out = 'During combat:\n'
	for effect in lingering_effects:
		out += '%s - %s\n' % [effect, CombatGlobals.loadStatusEffect(effect).description]
	return out

func applyEquipmentModifications():
	for charm in charms:
		charm.applyStatModifications()

func getAllocationModifier()-> Dictionary:
	var out = stat_point_allocations.duplicate()
	for stat in out.keys():
		if stat != 'handling' and out.has(stat):
			out[stat] *= stat_multiplier
		elif out.has(stat):
			out[stat] *= 1
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
		return

func unequipWeapon():
	if equipped_weapon != null:
#		if !equipped_weapon.canUse(self):
#			OverworldGlobals.showPrompt('%s does not meet %s requirements.' % [name, equipped_weapon.name])
#			return
		
		equipped_weapon.unequip()
		InventoryGlobals.addItemResource(equipped_weapon, 1, false, false)
		equipped_weapon = null

func hasEquippedWeapon()-> bool:
	return equipped_weapon != null

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
	enemy.ai_package = preload("res://scripts/combat/combatant_ai/aiRandomAI.gd")
	enemy.is_converted = true
#	enemy.tamed_combatant = self
	return enemy.duplicate()

func reset():
	for modification in stat_modifiers.keys():
		removeStatModification(modification)
	if base_health != null:
		stat_values['health'] = base_health
	ability_set = []
	lingering_effects = []
	equipped_weapon = null
	stat_points = 1
	stat_modifiers = {}
	charms = {
		0: null,
		1: null,
		2: null
	}
	stat_point_allocations = {
		'brawn': 0,
		'grit': 0,
		'handling': 0
	}
	temperment = {'primary':[], 'secondary':[]}

