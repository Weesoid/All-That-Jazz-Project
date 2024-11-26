extends Node
class_name StalkerSpawner

@export var stalker_data: ResStalkerEnemy

func _ready():
	# WARNING
	var flash = stalker_data.warning_flash.instantiate()
	var body: GenericPatroller = stalker_data.patroller.instantiate()
	body.modulate = Color.TRANSPARENT
	OverworldGlobals.combat_exited.connect(
		func activatePatroller():
			if body.has_node('NPCPatrolComponent'):
				body.patrol_component.process_mode= Node.PROCESS_MODE_INHERIT
			)
	if stalker_data.flash_on_camera:
		OverworldGlobals.getPlayer().player_camera.add_child(flash)
	else:
		flash.global_position = OverworldGlobals.getPlayer().global_position
		OverworldGlobals.getCurrentMap().add_child(flash)
	await get_tree().create_timer(stalker_data.spawn_time).timeout
	
	# SPAWN
	OverworldGlobals.setPlayerInput(false)
	body.global_position = OverworldGlobals.getPlayer().global_position
	OverworldGlobals.getCurrentMap().add_child(body)
	body.patrol_component.process_mode= Node.PROCESS_MODE_DISABLED
	body.patrol_component.STATE = 2
	create_tween().tween_property(body, 'modulate', Color.WHITE, 0.15)
	await OverworldGlobals.playEntityAnimation(body.name, 'Engage')
	OverworldGlobals.changeToCombat(body.name)
	#await body.ready
	#await get_tree().process_frame
