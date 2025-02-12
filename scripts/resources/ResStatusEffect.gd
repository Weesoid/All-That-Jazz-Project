extends Resource
class_name ResStatusEffect

enum EffectType {
	STANDARD,
	ON_HIT,
	DYNAMIC
}

@export var NAME: String
@export var DESCRIPTION: String
@export var BASIC_EFFECTS: Array[ResBasicEffect]
@export var STATUS_SCRIPT: GDScript = preload("res://scripts/combat/status_effects/scsBasicStatus.gd")
@export var PACKED_SCENE: PackedScene
@export var EFFECT_TYPE: EffectType
@export var TEXTURE: Texture = preload("res://images/sprites/unknown_icon.png")
@export var MAX_DURATION: int
@export var EXTEND_DURATION: int = 1
@export var APPLY_EXTEND_DURATION:  bool = false
@export var MAX_RANK: int
@export var TICK_PER_TURN: bool
@export var DO_TICKS: bool = true
@export var RESISTABLE: bool = true
@export var PERMANENT: bool = false
@export var LINGERING: bool = false

var APPLY_ONCE = true
var duration
var current_rank = 1
var afflicted_combatant: ResCombatant
var attached_data
var VISUALS
var ICON: TextureRect
var TARGETABLE

func initializeStatus():
	ICON = TextureRect.new()
	ICON.texture = TEXTURE
	
	if PACKED_SCENE != null:
		VISUALS = PACKED_SCENE.instantiate()
		animateStatusEffect()
	
	if EFFECT_TYPE == EffectType.ON_HIT:
		CombatGlobals.received_combatant_value.connect(onHitTick)
	elif EFFECT_TYPE == EffectType.DYNAMIC:
		VISUALS.status_effect = self
	
	if !APPLY_EXTEND_DURATION:
		duration = MAX_DURATION
	else:
		duration = EXTEND_DURATION

func onHitTick(combatant, caster, received_value):
	if combatant == afflicted_combatant:
		STATUS_SCRIPT.applyHitEffects(afflicted_combatant, caster, received_value, self)

func removeStatusEffect():
	if EFFECT_TYPE == EffectType.ON_HIT:
		CombatGlobals.received_combatant_value.disconnect(onHitTick)
	
	if STATUS_SCRIPT != null:
		STATUS_SCRIPT.endEffects(afflicted_combatant, self)
	if VISUALS != null:
		VISUALS.queue_free()
	
	if (CombatGlobals.randomRoll(0.15+afflicted_combatant.STAT_VALUES['resist']) or afflicted_combatant.isDead()) and afflicted_combatant is ResPlayerCombatant and LINGERING:
		afflicted_combatant.LINGERING_STATUS_EFFECTS.erase(NAME)
		CombatGlobals.manual_call_indicator.emit(afflicted_combatant, 'Cured %s!' % NAME, 'Heal')
	elif afflicted_combatant is ResPlayerCombatant and LINGERING:
		CombatGlobals.manual_call_indicator.emit(afflicted_combatant, '%s Persists!' % NAME, 'Flunk')
	
	ICON.queue_free()
	afflicted_combatant.STATUS_EFFECTS.erase(self)

func tick(update_duration=true):
	if !PERMANENT and update_duration: 
		duration -= 1
	
	if STATUS_SCRIPT != null and DO_TICKS:
		STATUS_SCRIPT.applyEffects(afflicted_combatant, self)
	
	APPLY_ONCE = false
	if duration <= 0 or afflicted_combatant.isDead() and !['Knock Out', 'Fading', 'Deathmark'].has(NAME) and !NAME.contains('Faded') and STATUS_SCRIPT != null:
		removeStatusEffect()

func animateStatusEffect():
	if VISUALS == null:
		return
	
	VISUALS.global_position = Vector2(0, 0)
	afflicted_combatant.SCENE.add_child(VISUALS)
	if VISUALS.has_node('AnimationPlayer'):
		VISUALS.get_node('AnimationPlayer').play('Show')
	if VISUALS is DynamicStatusEffect:
		VISUALS.status_effect = self
		if afflicted_combatant is ResEnemyCombatant and !afflicted_combatant.SCENE is PlayerCombatantScene:
			VISUALS.rotation_degrees = -180

func getDescription():
	var description = DESCRIPTION
	if MAX_RANK > 1: description += ' (%s/%s)' % [current_rank, MAX_RANK]
	return description

func _to_string():
	return NAME
