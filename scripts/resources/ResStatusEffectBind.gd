extends ResStatusEffect

@export var BINDED_PACKED_SCENE: PackedScene
var binded_combatant: ResCombatant
var BINDED_VISUALS

func initializeStatus():
	ICON = TextureRect.new()
	ICON.texture = TEXTURE
	
	if PACKED_SCENE != null:
		VISUALS = PACKED_SCENE.instantiate()
		animateStatusEffect()
	
	if BINDED_PACKED_SCENE != null:
		BINDED_VISUALS = BINDED_PACKED_SCENE.instantiate()
		animateStatusEffect()
	
	if ON_HIT:
		CombatGlobals.received_combatant_value.connect(onHitTick)
	
	duration = MAX_DURATION

func onHitTick(combatant, caster, received_value):
	if combatant == afflicted_combatant:
		STATUS_SCRIPT.applyHitEffects(afflicted_combatant, binded_combatant, caster, received_value, self)

func tick():
	if !PERMANENT: 
		duration -= 1
	
	STATUS_SCRIPT.applyEffects(afflicted_combatant, binded_combatant, self)
	
	APPLY_ONCE = false
	if duration <= 0 or afflicted_combatant.isDead() and !['Knock Out', 'Fading'].has(NAME):
		removeStatusEffect()

func animateStatusEffect():
	if VISUALS == null:
		return
	
	VISUALS.global_position = Vector2(0, 0)
	VISUALS.get_node('AnimationPlayer').play('Show')
	afflicted_combatant.SCENE.add_child(VISUALS)
