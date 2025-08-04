extends TileMap

func _ready():
	FootstepSoundManager.tilemaps = FootstepSoundManager.tilemaps.filter(
		func(tilemap):
			return is_instance_valid(tilemap)
	)
	FootstepSoundManager.tilemaps.push_back(self)
