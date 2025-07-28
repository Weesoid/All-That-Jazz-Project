extends ResBasicEffect
class_name ResStatusDamageEffect

@export var damage: int
@export var rank_scaling:bool = false
@export var use_damage_formula:bool=false
@export var bonus_stats = {}
@export var crit_chance: float = -1.0
@export var variation: float = -1.0
@export var trigger_on_hits:bool = false
@export var sound_path:String = ''
@export var indicator_bb:  String = ''
