extends ResStackItem
class_name ResConsumable

@export var EFFECT: ResAbility
@export var OVERWORLD_USE: bool = false

func animateCast(caster: ResCombatant):
	EFFECT.animateCast(caster)

func applyEffect(caster: ResCombatant, targets, animation_scene):
	EFFECT.applyEffects(caster, targets, animation_scene)
	InventoryGlobals.removeItemResource(self, 1)

func applyOverworldEffects():
	if STACK >= 0:
		EFFECT.ABILITY_SCRIPT.applyOverworldEffects()
		InventoryGlobals.removeItemResource(self, 1)
