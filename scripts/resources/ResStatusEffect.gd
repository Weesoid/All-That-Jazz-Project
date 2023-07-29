extends Resource
class_name ResStatusEffect

@export var NAME: String
@export var STATUS_SCRIPT: GDScript
@export var PACKED_SCENE: PackedScene
@export var TEXTURE: Texture
@export var MAX_DURATION: int
@export var MAX_RANK: int
@export var APPLY_ONCE: bool
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
	
	PARTICLES = PACKED_SCENE.instantiate()
	animateStatusEffect()
	
	duration = MAX_DURATION

func addStatusEffectIcon():
	afflicted_combatant.getStatusBar().add_child(ICON)
	current_rank = 1

func removeStatusEffect():
	STATUS_SCRIPT.endEffects(afflicted_combatant)
	PARTICLES.queue_free()
	ICON.queue_free()
	afflicted_combatant.STATUS_EFFECTS.erase(self)

func tick():
	if !PERMANENT: 
		duration -= 1
	STATUS_SCRIPT.applyEffects(afflicted_combatant, self)
	APPLY_ONCE = false
	if duration == 0 or afflicted_combatant.isDead():
		removeStatusEffect()
	
func animateStatusEffect():
	PARTICLES.global_position = Vector2(0, 60)
	afflicted_combatant.SCENE.add_child(PARTICLES)
	
	PARTICLES.restart()

