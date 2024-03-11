extends ResCombatant
class_name ResPlayerCombatant

@export var ABILITY_POOL: Array[ResAbility]
@export var FOLLOWER_PACKED_SCENE: PackedScene
@export var CHARMS = {
	0: null,
	1: null,
	2: null
}
@export var MANDATORY = false
var LINGERING_STATUS_EFFECTS: Array[String]
var STAT_POINTS = 1
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
		if charm == null: continue
		if charm.STATUS_EFFECT != null:
			CombatGlobals.addStatusEffect(self, charm.STATUS_EFFECT.NAME)
	for effect in LINGERING_STATUS_EFFECTS:
		CombatGlobals.addStatusEffect(self, effect)

func applyEquipmentModifications():
	for charm in CHARMS:
		charm.applyStatModifications()

func removeEquipmentModifications():
	for charm in CHARMS:
		charm.removeStatModifications()

func equipCharm(charm: ResCharm, slot: int):
	if hasCharm(charm):
		OverworldGlobals.showPlayerPrompt('[color=yellow]%s[/color] already has [color=yellow]%s[/color] equipped.' % [NAME, charm.NAME])
		return
	
	if InventoryGlobals.getItem(charm) != null:
		InventoryGlobals.removeItemResource(charm)
		charm.equip(self)
		CHARMS[slot] = charm
		print(CHARMS)
		return

func unequipCharm(slot: int):
	if CHARMS[slot] == null:
		return
	
	CHARMS[slot].unequip()
	InventoryGlobals.addItemResource(CHARMS[slot])
	CHARMS[slot] = null
	print(CHARMS)

func hasCharm(charm: ResCharm):
	for equipped_charm in CHARMS.values():
		if equipped_charm == null: continue
		if equipped_charm.NAME == charm.NAME: return true
