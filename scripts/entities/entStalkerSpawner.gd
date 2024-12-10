extends Node
class_name StalkerSpawner

@export var stalker_data: ResStalkerData
var body: GenericPatroller

func _ready():
	randomize()
	# WARNING
	var flash = stalker_data.warning_flash.instantiate()
	var quarter_time = stalker_data.spawn_time*0.25
	OverworldGlobals.combat_exited.connect(reactivatePatroller)
	if stalker_data.flash_follow:
		OverworldGlobals.getPlayer().player_camera.add_child(flash)
	else:
		flash.global_position = OverworldGlobals.getPlayer().global_position
		OverworldGlobals.getCurrentMap().add_child(flash)
	await get_tree().create_timer(stalker_data.spawn_time+randf_range(-quarter_time,quarter_time)).timeout
	
	# SPAWN
	body = stalker_data.patroller.instantiate()
	body.modulate = Color.TRANSPARENT
	PlayerGlobals.CLEARED_MAPS[OverworldGlobals.getCurrentMap().scene_file_path]['cleared'] = false
	quarter_time = stalker_data.spawn_delay*0.25
	if stalker_data.intro_follow:
		await OverworldGlobals.showQuickAnimation(stalker_data.stalker_intro, OverworldGlobals.getPlayer(),'')
	else:
		await OverworldGlobals.showQuickAnimation(stalker_data.stalker_intro, 'Player','')
	await get_tree().create_timer(stalker_data.spawn_delay+randf_range(-quarter_time,quarter_time)).timeout
	OverworldGlobals.setPlayerInput(false)
	body.global_position = OverworldGlobals.getPlayer().global_position
	OverworldGlobals.getCurrentMap().add_child(body)
	body.patrol_component.process_mode= Node.PROCESS_MODE_DISABLED
	body.patrol_component.STATE = 2
	create_tween().tween_property(body, 'modulate', Color.WHITE, 0.15)
	await OverworldGlobals.playEntityAnimation(body.name, 'Engage')
	OverworldGlobals.changeToCombat(body.name)

func _exit_tree():
	OverworldGlobals.combat_exited.disconnect(reactivatePatroller)
	#body.queue_free()

func reactivatePatroller():
	if is_instance_valid(body) and body.has_node('NPCPatrolComponent') and OverworldGlobals.isPlayerAlive():
		body.patrol_component.process_mode= Node.PROCESS_MODE_INHERIT
		PlayerGlobals.CLEARED_MAPS[OverworldGlobals.getCurrentMap().scene_file_path]['cleared'] = true
	queue_free()
