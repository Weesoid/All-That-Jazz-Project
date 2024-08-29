extends Resource
class_name ResAbility

enum TargetType {
	SINGLE,
	MULTI
}

enum TargetGroup {
	ALLIES,
	ENEMIES,
	SELF,
	ALL
}

@export var NAME: String
@export var DESCRIPTION: String
@export var ANIMATION: PackedScene
@export var ABILITY_SCRIPT: GDScript
@export var TARGET_TYPE: TargetType
@export var TARGET_GROUP: TargetGroup
@export var CAN_TARGET_SELF: bool = true
@export var TARGET_DEAD: bool = false
@export var INSTANT_CAST: bool = false
@export var REQUIRED_LEVEL = 0

var ENABLED: bool = true
var TARGETABLE

signal single_target(type)
signal multi_target(type)
signal random_target(type)

func execute():
	match TARGET_TYPE:
		TargetType.SINGLE: single_target.emit(self, 1)
		TargetType.MULTI: multi_target.emit(self, 2)

func getValidTargets(combatants: Array[ResCombatant], is_caster_player: bool):
	if !TARGET_DEAD:
		combatants = combatants.filter(func filterDead(combatant): return !combatant.isDead())
	if !CAN_TARGET_SELF:
		combatants.erase(CombatGlobals.getCombatScene().active_combatant)
	if TARGET_GROUP == TargetGroup.SELF:
		return CombatGlobals.getCombatScene().active_combatant
	
	if is_caster_player:
		match TARGET_GROUP:
			TargetGroup.ALLIES: return combatants.filter(func isTeamate(combatant): return combatant is ResPlayerCombatant)
			TargetGroup.ENEMIES: 
				if combatants.filter(func(combatant): return combatant.hasStatusEffect('Taunting')).size() > 0:
					combatants = combatants.filter(func(combatant): return combatant.hasStatusEffect('Taunting'))
				return combatants.filter(func isEnemy(combatant): return combatant is ResEnemyCombatant)
			TargetGroup.ALL: return combatants
	else:
		match TARGET_GROUP:
			TargetGroup.ALLIES: return combatants.filter(func isTeamate(combatant): return combatant is ResEnemyCombatant)
			TargetGroup.ENEMIES: 
				if combatants.filter(func(combatant): return combatant.hasStatusEffect('Taunting')).size() > 0:
					combatants = combatants.filter(func(combatant): return combatant.hasStatusEffect('Taunting'))
				return combatants.filter(func isEnemy(combatant): return combatant is ResPlayerCombatant)
			TargetGroup.ALL: return combatants

func animateCast(caster: ResCombatant):
	ABILITY_SCRIPT.animateCast(caster)

func applyEffects(caster: ResCombatant, targets, animation_scene):
	ABILITY_SCRIPT.applyEffects(caster, targets, animation_scene)

func applyOverworldEffects():
	ABILITY_SCRIPT.applyOverworldEffects()

func getTargetType():
	match TARGET_TYPE:
		TargetType.SINGLE: return 1
		TargetType.MULTI: return 2

func getAnimator()-> AnimationPlayer:
	return ANIMATION.get_node('AnimationPlayer')

func _to_string():
	return NAME

func getRichDescription(with_name=true)-> String:
	var description = ''
	if with_name:
		description += NAME.to_upper()+'\n'
	description += '[img]%s[/img]' % [getValidTargetIcon()]
	if INSTANT_CAST:
		description += '[img]%s[/img]' % "res://images/sprites/icon_fast_cast.png"
	description += ' '+DESCRIPTION
	return description

func getValidTargetIcon():
	if TARGET_GROUP == TargetGroup.SELF:
		return "res://images/sprites/icon_single_friend.png"
	if TARGET_TYPE == TargetType.SINGLE:
		match TARGET_GROUP:
			TargetGroup.ALLIES: return "res://images/sprites/icon_single_friend.png"
			TargetGroup.ENEMIES:  return "res://images/sprites/icon_single_enemy.png"
			TargetGroup.ALL: return "res://images/sprites/icon_single_all.png"
	if TARGET_TYPE == TargetType.MULTI:
		match TARGET_GROUP:
			TargetGroup.ALLIES: return "res://images/sprites/icon_multi_friend.png"
			TargetGroup.ENEMIES:  return "res://images/sprites/icon_multi_enemy.png"
			TargetGroup.ALL: return "res://images/sprites/icon_multi_all.png"
