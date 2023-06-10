extends Area2D
class_name LineOfSight

@onready var AREA = $"."
@onready var AREA_OF_SIGHT = $AreaOfSight
@onready var RAYCAST = $LineOfSight

func detectPlayer():
	RAYCAST.rotation = 0
	
	if get_overlapping_bodies().size() > 0:
		RAYCAST.look_at(OverworldGlobals.getPlayer().global_position)
		RAYCAST.rotation -= PI/2
		RAYCAST.force_raycast_update()
		if RAYCAST.get_collider() == OverworldGlobals.getPlayer():
			return true
		
	return false
