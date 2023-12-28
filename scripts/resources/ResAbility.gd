extends Resource
class_name ResAbility

enum TargetType {
	SINGLE,
	MULTI
}

enum TargetGroup {
	ALLIES,
	ENEMIES,
	ALL
}

@export var NAME: String
@export var DESCRIPTION: String
@export var ANIMATION: PackedScene
@export var ABILITY_SCRIPT: GDScript
@export var COST: int
@export var COST_RESOURCE: String
@export var TARGET_TYPE: TargetType
@export var TARGET_GROUP: TargetGroup
@export var TARGET_DEAD: bool = false
@export var INSTANT_CAST: bool = false
@export var VALUE = 5

var ENABLED: bool = true
var TARGETABLE

signal single_target(type)
signal multi_target(type)
signal random_target(type)
signal no_resource

func execute():
	print('EXECUTING!')
	print(TARGET_TYPE)
	match TARGET_TYPE:
		TargetType.SINGLE: single_target.emit(self, 1)
		TargetType.MULTI: multi_target.emit(self, 2)

func getValidTargets(combatants: Array[ResCombatant], is_caster_player: bool):
	if !TARGET_DEAD:
		combatants = combatants.filter(func filterDead(combatant): return !combatant.isDead())
	
	if is_caster_player:
		match TARGET_GROUP:
			TargetGroup.ALLIES: return combatants.filter(func isTeamate(combatant): return combatant is ResPlayerCombatant)
			TargetGroup.ENEMIES:  return combatants.filter(func isEnemy(combatant): return combatant is ResEnemyCombatant)
			TargetGroup.ALL: return combatants
	else:
		match TARGET_GROUP:
			TargetGroup.ALLIES: return combatants.filter(func isTeamate(combatant): return combatant is ResEnemyCombatant)
			TargetGroup.ENEMIES: return combatants.filter(func isEnemy(combatant): return combatant is ResPlayerCombatant)
			TargetGroup.ALL: return combatants

func canCast(caster: ResCombatant):
	return COST > 0 and caster.STAT_VALUES[COST_RESOURCE] >= COST or COST == 0

func expendCost(caster: ResCombatant):
	if COST == 0:
		return
	else:
		caster.STAT_VALUES[COST_RESOURCE] -= COST

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

func _to_string():
	return NAME
