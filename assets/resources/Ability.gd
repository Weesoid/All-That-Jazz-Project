extends Resource
class_name Ability

enum TargetType {
	SINGLE,
	MULTI
}

enum TargetGroup {
	ALLIES,
	ENEMIES
}

@export var NAME: String
@export var ANIMATION_NAME: String
@export var ABILITY_SCRIPT_NAME: String
@export var TARGET_TYPE: TargetType
@export var TARGET_GROUP: TargetGroup

var TARGETABLE
var ABILITY_SCRIPT
var ANIMATION

signal single_target(type)
signal multi_target(type)
signal random_target(type)
signal executed

func initializeAbility():
	ABILITY_SCRIPT = load(str("res://assets/scripts/ability_scripts/"+ABILITY_SCRIPT_NAME+".gd"))
	ANIMATION = load(str("res://assets/scene_assets/animations/abilities/"+ANIMATION_NAME+".tscn")).instantiate()
	
func execute():
	match TARGET_TYPE:
		TargetType.SINGLE: single_target.emit(self, 1)
		TargetType.MULTI: multi_target.emit(self, 2)
	
func getValidTargets(combatants: Array[Combatant], is_caster_player: bool):
	if is_caster_player:
		match TARGET_GROUP:
			TargetGroup.ALLIES: return combatants.filter(func isTeamate(combatant): return combatant.IS_PLAYER_UNIT)
			TargetGroup.ENEMIES: return combatants.filter(func isEnemy(combatant): return !combatant.IS_PLAYER_UNIT)
	else:
		match TARGET_GROUP:
			TargetGroup.ALLIES: return combatants.filter(func isTeamate(combatant): return !combatant.IS_PLAYER_UNIT)
			TargetGroup.ENEMIES: return combatants.filter(func isEnemy(combatant): return combatant.IS_PLAYER_UNIT)
	
func animateCast(caster: Combatant):
	ABILITY_SCRIPT.animateCast(caster)
	
func applyEffects(caster: Combatant, targets, animation_scene):
	ABILITY_SCRIPT.applyEffects(caster, targets, animation_scene)
	
func getTargetType():
	match TARGET_TYPE:
		TargetType.SINGLE: return 1
		TargetType.MULTI: return 2
	
func getAnimator()-> AnimationPlayer:
	return ANIMATION.get_node('AnimationPlayer')
	
