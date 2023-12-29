extends ResStackItem
class_name ResConsumable

@export var EFFECT: ResAbility
@export var OVERWORLD_USE: bool = false

func animateCast(caster: ResCombatant):
	EFFECT.animateCast(caster)

func applyEffect(caster: ResCombatant, targets, animation_scene, overworld=false):
	if overworld:
		EFFECT.ABILITY_SCRIPT.applyOverworldEffects(caster, targets, animation_scene)
	else:
		EFFECT.applyEffects(caster, targets, animation_scene)
	InventoryGlobals.removeItemResource(self, 1)
