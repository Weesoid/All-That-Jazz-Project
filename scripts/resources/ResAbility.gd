extends Resource
class_name ResAbility

enum TargetType {
	SINGLE,
	MULTI
}

enum TargetGroup {
	ALLIES,
	ENEMIES
}

@export var NAME: String
@export var DESCRIPTION: String
@export var ANIMATION: PackedScene
@export var ABILITY_SCRIPT: GDScript
@export var COST: int
@export var COST_RESOURCE: String
@export var TARGET_TYPE: TargetType
@export var TARGET_GROUP: TargetGroup
@export var INSTANT_CAST: bool = false

var ENABLED: bool = true
var TARGETABLE

signal single_target(type)
signal multi_target(type)
signal random_target(type)
signal no_resource

# Add cost value, and cost resource parameters
func execute():
	match TARGET_TYPE:
		TargetType.SINGLE: single_target.emit(self, 1)
		TargetType.MULTI: multi_target.emit(self, 2)

func getValidTargets(combatants: Array[ResCombatant], is_caster_player: bool):
	if is_caster_player:
		match TARGET_GROUP:
			TargetGroup.ALLIES: return combatants.filter(func isTeamate(combatant): return combatant is ResPlayerCombatant)
			TargetGroup.ENEMIES:  return combatants.filter(func isEnemy(combatant): return combatant is ResEnemyCombatant)
	else:
		match TARGET_GROUP:
			TargetGroup.ALLIES: return combatants.filter(func isTeamate(combatant): return combatant is ResEnemyCombatant)
			TargetGroup.ENEMIES: return combatants.filter(func isEnemy(combatant): return combatant is ResPlayerCombatant)

func canCast(caster: ResCombatant):
	return COST > 0 and caster.STAT_VALUES[COST_RESOURCE] >= COST or COST == 0

func expendCost(caster: ResCombatant):
	if COST == 0:
		return
	else:
		caster.STAT_VALUES[COST_RESOURCE] -= COST
		caster.updateEnergy() # Doesn't support updating health, signals?

func animateCast(caster: ResCombatant):
	ABILITY_SCRIPT.animateCast(caster)

func applyEffects(caster: ResCombatant, targets, animation_scene):
	ABILITY_SCRIPT.applyEffects(caster, targets, animation_scene)

func getTargetType():
	match TARGET_TYPE:
		TargetType.SINGLE: return 1
		TargetType.MULTI: return 2

func getAnimator()-> AnimationPlayer:
	return ANIMATION.get_node('AnimationPlayer')
