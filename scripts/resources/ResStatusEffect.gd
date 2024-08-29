extends Resource
class_name ResStatusEffect

@export var NAME: String
@export var DESCRIPTION: String
@export var STATUS_SCRIPT: GDScript
@export var PACKED_SCENE: PackedScene # Turn this into a Node2D
@export var TEXTURE: Texture = preload("res://images/sprites/unknown_icon.png")
@export var MAX_DURATION: int
@export var EXTEND_DURATION: int = 0
@export var MAX_RANK: int
@export var ON_HIT: bool
@export var APPLY_ONCE: bool
@export var TICK_PER_TURN: bool
@export var TICK_ON_TURN_START: bool
@export var PERMANENT: bool = false
@export var LINGERING: bool = false

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
	
	if ON_HIT:
		CombatGlobals.received_combatant_value.connect(onHitTick)
	
	duration = MAX_DURATION

func onHitTick(combatant, caster, received_value):
	if combatant == afflicted_combatant:
		STATUS_SCRIPT.applyHitEffects(afflicted_combatant, caster, received_value, self)

func removeStatusEffect():
	if ON_HIT:
		CombatGlobals.received_combatant_value.disconnect(onHitTick)
	
	if STATUS_SCRIPT != null:
		STATUS_SCRIPT.endEffects(afflicted_combatant, self)
	if VISUALS != null:
		VISUALS.queue_free()
	
	ICON.queue_free()
	afflicted_combatant.STATUS_EFFECTS.erase(self)

func tick(update_duration=true):
	if !PERMANENT and update_duration: 
		duration -= 1
	
	if STATUS_SCRIPT != null:
		STATUS_SCRIPT.applyEffects(afflicted_combatant, self)
	
	APPLY_ONCE = false
	if duration <= 0 or afflicted_combatant.isDead() and !['Knock Out', 'Fading'].has(NAME) and STATUS_SCRIPT != null:
		removeStatusEffect()

func animateStatusEffect():
	if VISUALS == null:
		return
	
	VISUALS.global_position = Vector2(0, 0)
	VISUALS.get_node('AnimationPlayer').play('Show')
	afflicted_combatant.SCENE.add_child(VISUALS)

func _to_string():
	return NAME
