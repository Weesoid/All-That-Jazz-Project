extends Area2D

@onready var player = OverworldGlobals.getPlayer()
@onready var smear = $AnimationPlayer

func _on_body_entered(body):
	if body is GenericPatroller and is_instance_valid(body):
		if body.has_node('CombatInteractComponent'):
			OverworldGlobals.getCurrentMap().destroyPatroller(body)
			OverworldGlobals.shakeCamera()
			await OverworldGlobals.getPlayer().showOverlay(Color.RED, 0.025)
			OverworldGlobals.getPlayer().hideOverlay()
		elif body.getState() != 3:
			OverworldGlobals.shakeSprite(body)
			OverworldGlobals.changeToCombat(body.name, {'initial_damage'=10})

func _unhandled_input(event):
	if Input.is_action_just_pressed('ui_melee') and player.can_move and !player.animation_tree["parameters/conditions/shoot_bow"]:
		smear.play('Show')
