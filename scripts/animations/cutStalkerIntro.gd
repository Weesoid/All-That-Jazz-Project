extends QuickAnimation
class_name StalkerIntro

@export var projectile: Array[ResProjectile]

func dropProjectile(direction:float=90, projectile_idx:int=0):
	OverworldGlobals.shootProjectile(projectile[projectile_idx].getProjectile(), global_position, direction)

func shootFromPoint(point:String='', projectile_idx:int=0):
	var shoot_point: Marker2D
	var direction
	if point != '':
		shoot_point = get_node(point)
	else:
		shoot_point = getShootPoints().pick_random()
	if shoot_point.position.y == 0.0:
		if shoot_point.position.x > 0:
			direction = 180
		elif shoot_point.position.x < 0:
			direction = 0
	elif shoot_point.position.x == 0.0:
		if shoot_point.position.y > 0:
			direction = 270
		elif shoot_point.position.y < 0:
			direction = 90
	OverworldGlobals.shootProjectile(projectile[projectile_idx].getProjectile(), shoot_point.global_position,direction)

func getShootPoints():
	var out = []
	for child in get_children():
		if child is Marker2D and child.name.contains('ShootPoint'):
			out.append(child)
	return out
