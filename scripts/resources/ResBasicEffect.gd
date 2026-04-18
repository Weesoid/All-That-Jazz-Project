extends Resource
class_name ResBasicEffect

@export var apply_once: bool
@export var message: String = ''
@export var sound_effect: String = ''
## Used to be able to be found and have it's properties overriden in the addStatusEffect() function CANNOT CONTAIN UNDERSCORE(_)
@export var identifier: String = ''
