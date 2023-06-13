extends Area2D
class_name LineOfSight

@onready var AREA = $"."
@onready var AREA_OF_SIGHT = $AreaOfSight
@onready var RAYCAST = $LineOfSight

func detectPlayer():
	# TO-DO IMPROVE THIS
	# Only seems to trigger if moving
	# Removing player tracking fixes this
	# Cut your losses and do a sweep cast?
	RAYCAST.rotation = 0
	if overlaps_body(OverworldGlobals.getPlayer()):
		RAYCAST.look_at(OverworldGlobals.getPlayer().global_position)
		RAYCAST.rotation -= PI/2
		RAYCAST.force_raycast_update()
		return RAYCAST.get_collider() == OverworldGlobals.getPlayer()
		
