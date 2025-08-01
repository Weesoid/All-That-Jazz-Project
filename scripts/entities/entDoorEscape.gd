extends Door
class_name EscapeDoor

func _ready():
	OverworldGlobals.group_cleared.connect(func():queue_free())

func interact():
	OverworldGlobals.addPatrollerPulse(global_position, 150.0, 3)
	OverworldGlobals.player.set_collision_layer_value(5, false)
	OverworldGlobals.player.set_collision_mask_value(5, false)
	if OverworldGlobals.getCurrentMap().getPatrollers().size() > 0:
		PlayerGlobals.addExperience(int(randf_range(-0.5,-0.25) * PlayerGlobals.getRequiredExp()), true)
		OverworldGlobals.setMapRewardBank('experience', 0)
		OverworldGlobals.getCurrentMap().give_on_exit = true
	OverworldGlobals.changeMap(to_scene_path, '0,0,0','SavePoint',true,true)

func _on_body_entered(body):
	if touch_enter and body is PlayerScene and PlayerGlobals.isMapCleared(): 
		OverworldGlobals.changeMap(to_scene_path, to_coords)
	elif touch_enter and body is PlayerScene:
		OverworldGlobals.showPrompt("You can't leave yet, there's a job to be done.")
