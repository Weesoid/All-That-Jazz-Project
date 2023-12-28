extends Resource
class_name ResStatusEffect

@export var NAME: String
@export var DESCRIPTION: String
@export var STATUS_SCRIPT: GDScript
@export var PACKED_SCENE: PackedScene
@export var TEXTURE: Texture
@export var MAX_DURATION: int
@export var MAX_RANK: int
@export var ON_HIT: bool
@export var APPLY_ONCE: bool
@export var TICK_PER_TURN: bool
@export var PERMANENT: bool = false

var duration
var current_rank = 1
var afflicted_combatant: ResCombatant
var PARTICLES
var ICON: TextureRect
var TARGETABLE

func initializeStatus():
	ICON = TextureRect.new()
	ICON.texture = TEXTURE
	
	if PACKED_SCENE != null:
		PARTICLES = PACKED_SCENE.instantiate()
		animateStatusEffect()
	
	if ON_HIT:
		CombatGlobals.received_combatant_value.connect(onHitTick)
	
	duration = MAX_DURATION

func onHitTick(combatant, caster, received_value):
	if combatant == afflicted_combatant:
		STATUS_SCRIPT.applyEffects(afflicted_combatant, caster, received_value, self)

func addStatusEffectIcon():
	afflicted_combatant.getStatusBar().add_child(ICON)
	current_rank = 1

func removeStatusEffect():
	if ON_HIT:
		CombatGlobals.received_combatant_value.disconnect(onHitTick)
	STATUS_SCRIPT.endEffects(afflicted_combatant)
	if PARTICLES != null:
		PARTICLES.queue_free()
	ICON.queue_free()
	afflicted_combatant.STATUS_EFFECTS.erase(self)

func tick():
	if !PERMANENT: 
		duration -= 1
	if !ON_HIT:
		STATUS_SCRIPT.applyEffects(afflicted_combatant, self)
	
	APPLY_ONCE = false
	if duration == 0 or afflicted_combatant.isDead() and NAME != "Knock Out":
		removeStatusEffect()

func animateStatusEffect():
	if PARTICLES == null:
		return
	
	PARTICLES.global_position = Vector2(0, 0)
	afflicted_combatant.SCENE.add_child(PARTICLES)
	
	PARTICLES.restart()

