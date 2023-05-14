# TO-DO
# Run _init automatically
# Better way to handle sheets?

extends Resource
class_name Combatant

## Backend export variables
@export var NAME: String
@export var SPRITE_NAME: String
@export var IS_PLAYER_UNIT: bool
@export var COUNT: int = 1
@export var AI_PACKAGE_NAME: String

## Frontend / Gameplay export variables
@export var STAT_HEALTH: int
@export var STAT_SPEED: int
@export var STAT_BRAWN: int
@export var STAT_WIT: int

var SCENE
var AI_PACKAGE

signal enemy_turn
signal player_turn

func initializeCombatant():
	SCENE = load(str("res://assets/scene_assets/combatant_sprites/",SPRITE_NAME,".tscn")).instantiate()
	AI_PACKAGE = load(str("res://assets/scripts/ai_packages/",AI_PACKAGE_NAME,".gd"))
	print(NAME, ' LOADED')

func act():
	if IS_PLAYER_UNIT:
		player_turn.emit()
	else:
		enemy_turn.emit()

func getSprite()-> Sprite2D:
	return SCENE.get_node('Sprite')

func getAnimator()-> AnimationPlayer:
	return SCENE.get_node('AnimationPlayer')

func selectTarget(combatant_array: Array[Combatant])-> Combatant:
	return AI_PACKAGE.selectTarget(combatant_array)
