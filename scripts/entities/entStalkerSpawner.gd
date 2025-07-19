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
	body = CombatGlobals.generatePatroller(stalker_data.patroller)
	body.name = 'Stalker'
	body.modulate = Color.TRANSPARENT
	PlayerGlobals.CLEARED_MAPS[OverworldGlobals.getCurrentMap().scene_file_path]['cleared'] = false
	quarter_time = stalker_data.spawn_delay*0.25
	if stalker_data.intro_follow:
		await OverworldGlobals.showQuickAnimation(stalker_data.stalker_intro, OverworldGlobals.getPlayer(),'')
	else:
		await OverworldGlobals.showQuickAnimation(stalker_data.stalker_intro, 'Player','')
	await get_tree().create_timer(stalker_data.spawn_delay+randf_range(-quarter_time,quarter_time)).timeout
	OverworldGlobals.setPlayerInput(false)
	var player_pos=OverworldGlobals.getPlayer().global_position+OverworldGlobals.getPlayer().sprite.offset
	body.global_position = player_pos+Vector2(0,10)
	body.process_mode= Node.PROCESS_MODE_DISABLED
	OverworldGlobals.getCurrentMap().add_child(body)
	await OverworldGlobals.showQuickAnimation(stalker_data.engage_animation, player_pos)
	OverworldGlobals.changeToCombat(body.name,{},body)

func reactivatePatroller():
	if is_instance_valid(body) and body is GenericPatroller and OverworldGlobals.isPlayerAlive():
		body.updateState(2)
		body.process_mode= Node.PROCESS_MODE_INHERIT
		PlayerGlobals.CLEARED_MAPS[OverworldGlobals.getCurrentMap().scene_file_path]['cleared'] = true
	elif !OverworldGlobals.isPlayerAlive():
		OverworldGlobals.getCurrentMap().give_on_exit = false
	
	OverworldGlobals.combat_exited.disconnect(reactivatePatroller)
	queue_free()
