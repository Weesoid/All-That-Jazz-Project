extends ResCombatant
class_name ResPlayerCombatant

@export var ABILITY_POOL: Array[ResAbility]
@export var ABILITY_SLOT: ResAbility = load("res://resources/combat/abilities/BraceSelf.tres")
@export var BASE_TEMPERMENT: Dictionary = {'primary':[], 'secondary':[]}
@export var FOLLOWER_PACKED_SCENE: PackedScene
@export var MANDATORY = false
@export var STAT_MULTIPLIER = 0.01

var EQUIPPED_WEAPON: ResWeapon
var STAT_POINTS = 1
var CHARMS = {
	0: null,
	1: null,
	2: null
}
var STAT_POINT_ALLOCATIONS = {
	'brawn': 0,
	'grit': 0,
	'handling': 0
}
var TEMPERMENT: Dictionary = {'primary':[], 'secondary':[]}
var BASE_HEALTH: int
var initialized = false

func initializeCombatant(do_scene:bool=true):
	if do_scene:
		SCENE = PACKED_SCENE.instantiate()
		SCENE.combatant_resource = self
	if !initialized:
		BASE_STAT_VALUES = STAT_VALUES.duplicate()
		BASE_HEALTH = STAT_VALUES['health']
		initialized = true
	if !STAT_MODIFIERS.keys().has('scaled_stats'):
		scaleStats()
	if CombatGlobals.inCombat():
		applyStatusEffects()
	if !TEMPERMENT['primary'] is Array:
		TEMPERMENT['primary'] = []
		TEMPERMENT['secondary'] = []
	if TEMPERMENT['primary'] == [] and TEMPERMENT['secondary'] == []:
		TEMPERMENT = BASE_TEMPERMENT
	applyTemperments()

func applyTemperments(update:bool = false):
	if TEMPERMENT['primary'].is_empty():
		return
	if !TEMPERMENT['primary'] is Array:
		TEMPERMENT['primary'] = []
		TEMPERMENT['secondary'] = []
		applyTemperments()
		return
	
	for temperment in TEMPERMENT['primary']:
		if !STAT_MODIFIERS.keys().has('pt_'+temperment) or update:
			CombatGlobals.modifyStat(self, PlayerGlobals.PRIMARY_TEMPERMENTS[temperment], 'pt_'+temperment)
	for temperment in TEMPERMENT['secondary']:
		if !STAT_MODIFIERS.keys().has('st_'+temperment) or update:
			CombatGlobals.modifyStat(self, PlayerGlobals.SECONDARY_TEMPERMENTS[temperment], 'st_'+temperment)

func scaleStats():
	var stat_increase = {}
	stat_increase['health'] = (BASE_HEALTH * (1 + ((PlayerGlobals.PARTY_LEVEL-1)*0.1))) - BASE_HEALTH
	CombatGlobals.modifyStat(self, stat_increase, 'scaled_stats')

func updateCombatant(save_data: PlayerSaveData):
	var remove_abilities = ABILITY_SET.filter(func(ability): return !ABILITY_POOL.has(ability))
	for ability in remove_abilities:
		ABILITY_SET.erase(ability)
	
	var percent_health = float(save_data.COMBATANT_SAVE_DATA[self][2]['health']) / float(save_data.COMBATANT_SAVE_DATA[self][3]['health'])
#	if NAME == 'Willis Flynn':
#		print('======= ', NAME, ' =======')
#		print('BaseHealth: ', STAT_VALUES['health'])
#		print('Dividing: ',save_data.COMBATANT_SAVE_DATA[self][2]['health'], ' / ', save_data.COMBATANT_SAVE_DATA[self][3]['health'])
#		print('% left: ', percent_health)
#		print(BASE_STAT_VALUES['health'], ' * ', percent_health, ' = ', BASE_STAT_VALUES['health'] * percent_health)
#		print('Floored: ', floor(BASE_STAT_VALUES['health'] * percent_health))
	STAT_VALUES['health'] = floor(BASE_STAT_VALUES['health'] * percent_health)

func act():
	player_turn.emit()

func applyStatusEffects():
	for charm in CHARMS.values():
		if charm == null or charm.STATUS_EFFECT == null: continue
		CombatGlobals.addStatusEffect(self, charm.STATUS_EFFECT.NAME)
	for effect in LINGERING_STATUS_EFFECTS:
		CombatGlobals.addStatusEffect(self, effect)

func isInflicted()-> bool:
	return !LINGERING_STATUS_EFFECTS.is_empty()

func getLingeringEffectsString():
	var out = 'During combat:\n'
	for effect in LINGERING_STATUS_EFFECTS:
		out += '%s - %s\n' % [effect, CombatGlobals.loadStatusEffect(effect).DESCRIPTION]
	return out

func applyEquipmentModifications():
	for charm in CHARMS:
		charm.applyStatModifications()

func getAllocationModifier()-> Dictionary:
	var out = STAT_POINT_ALLOCATIONS.duplicate()
	for stat in out.keys():
		if stat != 'handling' and out.has(stat):
			out[stat] *= STAT_MULTIPLIER
		elif out.has(stat):
			out[stat] *= 1
	return out

func removeEquipmentModifications():
	for charm in CHARMS:
		charm.removeStatModifications()

func equipWeapon(weapon: ResWeapon):
	if EQUIPPED_WEAPON != null:
		unequipWeapon()
		
	if InventoryGlobals.getItem(weapon) != null:
		InventoryGlobals.removeItemResource(weapon, 1, false, true)
		weapon.equip(self)
		return

func unequipWeapon():
	if EQUIPPED_WEAPON != null:
#		if !EQUIPPED_WEAPON.canUse(self):
#			OverworldGlobals.showPlayerPrompt('%s does not meet %s requirements.' % [NAME, EQUIPPED_WEAPON.NAME])
#			return
		
		EQUIPPED_WEAPON.unequip()
		InventoryGlobals.addItemResource(EQUIPPED_WEAPON, 1, false, false)
		EQUIPPED_WEAPON = null
		ABILITY_SLOT = load("res://resources/combat/abilities/BraceSelf.tres")


func hasEquippedWeapon()-> bool:
	return EQUIPPED_WEAPON != null

func equipCharm(charm: ResCharm, slot: int):
	if InventoryGlobals.getItem(charm) != null:
		InventoryGlobals.removeItemResource(charm, 1, false, true)
		charm.equip(self)
		CHARMS[slot] = charm
		return

func unequipCharm(slot: int):
	if CHARMS[slot] == null:
		return
	
	CHARMS[slot].unequip()
	CombatGlobals.resetStat(self, CHARMS[slot].NAME)
	InventoryGlobals.addItemResource(CHARMS[slot], 1, false, false)
	CHARMS[slot] = null
	OverworldGlobals.playSound("res://audio/sounds/421418__jaszunio15__click_200.ogg")

func hasCharm(charm: ResCharm):
	for equipped_charm in CHARMS.values():
		if equipped_charm == null: continue
		if equipped_charm.NAME == charm.NAME: return true

func convertToEnemy(appended_name: String)-> ResEnemyCombatant:
	initializeCombatant(false)
	var enemy = ResEnemyCombatant.new()
	enemy.NAME = appended_name + ' ' +NAME
	enemy.PACKED_SCENE = PACKED_SCENE
	enemy.DESCRIPTION = DESCRIPTION
	enemy.STAT_VALUES = BASE_STAT_VALUES.duplicate()
	enemy.STAT_VALUES['health'] = BASE_HEALTH
	if ABILITY_POOL.size() < 4:
		for ability in ABILITY_POOL:
			enemy.ABILITY_SET.append(ability)
	else:
		enemy.ABILITY_SET.append(ABILITY_POOL[0])
		enemy.ABILITY_SET.append(ABILITY_POOL[1])
		enemy.ABILITY_SET.append(ABILITY_POOL[2])
		enemy.ABILITY_SET.append(ABILITY_POOL[3])
	enemy.AI_PACKAGE = preload("res://scripts/combat/combatant_ai/aiRandomAI.gd")
	enemy.is_converted = true
	enemy.tamed_combatant = self
	return enemy.duplicate()

func reset():
	for modification in STAT_MODIFIERS.keys():
		removeStatModification(modification)
	if BASE_HEALTH != null:
		STAT_VALUES['health'] = BASE_HEALTH
	ABILITY_SET = []
	LINGERING_STATUS_EFFECTS = []
	EQUIPPED_WEAPON = null
	STAT_POINTS = 1
	STAT_MODIFIERS = {}
	CHARMS = {
		0: null,
		1: null,
		2: null
	}
	STAT_POINT_ALLOCATIONS = {
		'brawn': 0,
		'grit': 0,
		'handling': 0
	}
	TEMPERMENT = {'primary':[], 'secondary':[]}

