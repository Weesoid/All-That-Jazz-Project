extends Node

var tilemaps: Array[TileMap] = []
const FOOTSTEP_SOUNDS = {
	'sand': [
		'353799__monte32__footsteps_6_dirt_shoe 01.ogg',
		'353799__monte32__footsteps_6_dirt_shoe 02.ogg',
		'353799__monte32__footsteps_6_dirt_shoe 03.ogg'
		#'353799__monte32__footsteps_6_dirt_shoe 04.ogg'.
		#'353799__monte32__footsteps_6_dirt_shoe 05.ogg'
	]
}

func playFootstep(body: CharacterBody2D, position:Vector2,db:float=-3,pitch=1.0):
	if !body.is_on_floor():
		return
	position+=Vector2(0,7)
	#OverworldGlobals.showQuickAnimation("res://scenes/animations_quick/DebugPoint.tscn",position)
	var tile_data = []
	for tilemap in tilemaps:
		if !is_instance_valid(tilemap):
			return
		
		var tile_pos = tilemap.local_to_map(position)
		var data = tilemap.get_cell_tile_data(0,tile_pos)
		if data:
			tile_data.push_back(data)
	
	if tile_data.size() > 0:
		var tile_type = tile_data.back().get_custom_data("footstep_sound")
		if FOOTSTEP_SOUNDS.has(tile_type):
			OverworldGlobals.playSound2D(position, FOOTSTEP_SOUNDS[tile_type].pick_random(),db,pitch,true,[0.0,1.0])
