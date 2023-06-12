extends Area2D
class_name LineOfSight

@onready var AREA = $"."
@onready var AREA_OF_SIGHT = $AreaOfSight
@onready var RAYCAST = $LineOfSight

func detectPlayer():
	# TO-DO IMPROVE THIS
	RAYCAST.look_at(OverworldGlobals.getPlayer().global_position)
	RAYCAST.rotation -= PI/2
	RAYCAST.force_raycast_update()
	return overlaps_body(OverworldGlobals.getPlayer()) and RAYCAST.get_collider() == OverworldGlobals.getPlayer()
