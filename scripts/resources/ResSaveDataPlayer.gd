extends Resource
class_name PlayerSaveData

@export var team: Array[ResPlayerCombatant]
@export var FOLLOWERS: Array[NPCFollower]
@export var map_logs: Dictionary
@export var power: GDScript
@export var equipped_arrow: ResProjectileAmmo
@export var equipped_blessing: ResBlessing
@export var currency: int
@export var team_level: int
@export var current_exp: int
@export var STRING_CONDITIONS: Array[String]
@export var progression_data: Dictionary
@export var team_formation: Array[ResCombatant]
@export var COMBATANT_SAVE_DATA: Dictionary
@export var unlocked_abilities: Dictionary
@export var added_abilities: Dictionary
@export var max_team_level: int
@export var known_powers: Array
