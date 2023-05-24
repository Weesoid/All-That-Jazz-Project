extends Resource
class_name Combatant

enum ArmorType {
	NEUTRAL,
	LIGHT,
	HEAVY
}

## Backend export variables
@export var NAME: String
@export var SPRITE_NAME: String
@export var IS_PLAYER_UNIT: bool
@export var COUNT: int = 1
@export var AI_PACKAGE_NAME: String

## Frontend / Gameplay export variables
@export var ARMOR_TYPE: ArmorType
@export var STAT_HEALTH: int
@export var STAT_SPEED: int
@export var STAT_BRAWN: int
@export var STAT_WIT: int
@export var STAT_GRIT: int
@export var ABILITY_SET: Array[Ability] # May need to be refactored to dict for specific selection

var STATUS_EFFECTS: Array[StatusEffect]
var SCENE
var AI_PACKAGE

signal enemy_turn
signal player_turn

func initializeCombatant():
	SCENE = load(str("res://assets/scene_assets/combatant_sprites/",SPRITE_NAME,".tscn")).instantiate()
	for ability in ABILITY_SET:
		ability.initializeAbility()
	if !IS_PLAYER_UNIT:
		AI_PACKAGE = load(str("res://assets/scripts/ai_packages/",AI_PACKAGE_NAME,".gd"))
	getSprite().get_node("HealthBar").max_value = STAT_HEALTH
	getSprite().get_node("HealthBar").value = STAT_HEALTH

func act():
	if IS_PLAYER_UNIT:
		player_turn.emit()
	else:
		enemy_turn.emit()

func getSprite()-> Sprite2D:
	return SCENE.get_node('Sprite')

func playIndicator(value):
	getSprite().get_node("IndicatorComponent").get_node("Label").text = str(value)
	getSprite().get_node("IndicatorComponent").get_node("Animator").play('Show')

func getAnimator()-> AnimationPlayer:
	return SCENE.get_node('AnimationPlayer')

func selectTarget(combatant_array: Array[Combatant])-> Combatant:
	return AI_PACKAGE.selectTarget(combatant_array)

func updateHealth(new_health):
	getSprite().get_node("HealthBar").value = new_health

func _to_string():
	return str(NAME)
