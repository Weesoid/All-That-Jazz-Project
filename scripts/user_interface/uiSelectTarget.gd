extends Node2D

@onready var animator = $AnimationPlayer
@onready var label = $Label

var attached_combatant: ResCombatant
var combat_scene = CombatGlobals.getCombatScene()

func _process(_delta):
	label.text = attached_combatant.NAME
	if attached_combatant != null and combat_scene.target_state != 0:
		if combat_scene.target_combatant is ResCombatant:
			if combat_scene.target_combatant == attached_combatant:
				show()
				animator.play("Select")
			elif combat_scene.valid_targets is Array and combat_scene.valid_targets.has(attached_combatant):
				show()
				animator.play("Show")
			else:
				hide()
				animator.play("RESET")
		elif combat_scene.target_combatant is Array:
			if combat_scene.valid_targets.has(attached_combatant):
				show()
				animator.play("Select")
			else:
				hide()
				animator.play("RESET")
	else:
		hide()
		animator.play("RESET")
