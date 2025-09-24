extends Node2D

@onready var animator = $AnimationPlayer
@onready var label = $Label
@onready var combat_scene = CombatGlobals.getCombatScene()

var attached_combatant: ResCombatant

func _process(_delta):
	if attached_combatant == null:
		return
	
	label.text = attached_combatant.name
	if attached_combatant != null and combat_scene.target_state != 0:
		if combat_scene.target_combatant is ResCombatant:
			if combat_scene.target_combatant == attached_combatant:
				label.show()
				show()
				animator.play("Select")
			elif combat_scene.valid_targets is Array and combat_scene.valid_targets.has(attached_combatant):
				label.hide()
				show()
				animator.play("Show")
			else:
				hide()
				animator.play("RESET")
		elif combat_scene.target_combatant is Array:
			if combat_scene.valid_targets.has(attached_combatant):
				label.hide()
				show()
				animator.play("Select")
			else:
				hide()
				animator.play("RESET")
	else:
		hide()
		animator.play("RESET")
