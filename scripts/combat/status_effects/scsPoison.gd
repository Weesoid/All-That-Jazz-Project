static func applyEffects(target: ResCombatant, status_effect: ResStatusEffect):
	CombatGlobals.calculateRawDamage(
		target, 
		2 * status_effect.current_rank, 
		null, 
		false, 
		-1.0, 
		false, 
		-1.0, 
		null, 
		false, 
		"res://audio/sounds/46_Poison_01.ogg"
	)

	OverworldGlobals.playSound2D(target.SCENE.global_position,"res://audio/sounds/46_Poison_01.ogg" )

static func endEffects(_target: ResCombatant, _status_effect: ResStatusEffect):
	pass
