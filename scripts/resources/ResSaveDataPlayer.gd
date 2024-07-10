extends Resource
class_name PlayerSaveData

@export var TEAM: Array[ResPlayerCombatant]
@export var FOLLOWERS: Array[NPCFollower]
@export var FAST_TRAVEL_LOCATIONS: Array[String]
@export var CLEARED_MAPS = []
@export var POWER: GDScript
@export var EQUIPPED_ARROW: ResProjectileAmmo
@export var CURRENCY: int
@export var EQUIPPED_CHARM: ResUtilityCharm
@export var PARTY_LEVEL: int
@export var CURRENT_EXP: int
@export var stamina: float
@export var bow_max_draw: float
@export var walk_speed: float
@export var sprint_speed: float
@export var sprint_drain: float
@export var stamina_gain: float
@export var STRING_CONDITIONS: Array[String]
@export var COMBATANT_SAVE_DATA: Dictionary
