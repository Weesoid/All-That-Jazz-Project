extends ResCombatant
class_name ResPlayerCombatant

@export var ABILITY_POOL: Array[ResAbility]
@export var ABILITY_SLOT: ResAbility = preload("res://resources/combat/abilities/BraceSelf.tres")
@export var FOLLOWER_PACKED_SCENE: PackedScene
@export var MANDATORY = false

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
var initialized = false
var active = false

func initializeCombatant():
	SCENE = PACKED_SCENE.instantiate()
	
	if !initialized:
		BASE_STAT_VALUES = STAT_VALUES.duplicate()
		initialized = true
	
	applyStatusEffects()

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
	var out = '%s is afflicted with:\n' % NAME
	for effect in LINGERING_STATUS_EFFECTS:
		out += '%s - %s\n' % [effect, CombatGlobals.loadStatusEffect(effect).DESCRIPTION]
	return out

func applyEquipmentModifications():
	for charm in CHARMS:
		charm.applyStatModifications()

func getAllocationModifier()-> Dictionary:
	var out = STAT_POINT_ALLOCATIONS.duplicate()
	for stat in out.keys():
		out[stat] *= 0.02
	return out

func removeEquipmentModifications():
	for charm in CHARMS:
		charm.removeStatModifications()

func equipWeapon(weapon: ResWeapon):
	if EQUIPPED_WEAPON != null:
		unequipWeapon()
		
	if InventoryGlobals.getItem(weapon) != null:
		InventoryGlobals.removeItemResource(weapon, 1, false)
		weapon.equip(self)
		return

func unequipWeapon():
	if EQUIPPED_WEAPON != null:
		if !EQUIPPED_WEAPON.canUse(self):
			OverworldGlobals.showPlayerPrompt('%s does not meet %s requirements.' % [NAME, EQUIPPED_WEAPON.NAME])
			return
		
		EQUIPPED_WEAPON.unequip()
		InventoryGlobals.addItemResource(EQUIPPED_WEAPON, 1, false, false)
		EQUIPPED_WEAPON = null
		ABILITY_SLOT = preload("res://resources/combat/abilities/BraceSelf.tres")

func equipCharm(charm: ResCharm, slot: int):
	if hasCharm(charm):
		OverworldGlobals.showPlayerPrompt('[color=yellow]%s[/color] already has [color=yellow]%s[/color] equipped.' % [NAME, charm.NAME])
		return
	
	if InventoryGlobals.getItem(charm) != null:
		InventoryGlobals.removeItemResource(charm, 1, false)
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

func hasCharm(charm: ResCharm):
	for equipped_charm in CHARMS.values():
		if equipped_charm == null: continue
		if equipped_charm.NAME == charm.NAME: return true
