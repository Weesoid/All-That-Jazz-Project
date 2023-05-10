extends Resource
class_name Combatant

@export var NAME: String
@export var SPRITE_NAME: String
@export var HEALTH: int
@export var IS_PLAYER_UNIT: bool
var SPRITE: TextureRect

signal enemy_turn
signal player_turn

func init():
	# Load TEXTURE
	SPRITE = TextureRect.new()
	SPRITE.texture = load(str('res://resources/sprites/combat_characters/',SPRITE_NAME))
	SPRITE.expand_mode = 3
	print(NAME, ' LOADED')

func act():
	print(NAME, "'s turn!")
	if IS_PLAYER_UNIT:
		player_turn.emit()
	else:
		enemy_turn.emit()
