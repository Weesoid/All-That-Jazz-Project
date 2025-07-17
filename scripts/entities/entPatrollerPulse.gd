extends EffectPulse
class_name PatrollerPulse

var mode: int
var trigger_others=false

func applyPulseEffect():
	for body in get_overlapping_bodies():
		if body is GenericPatroller:
			if mode == body.state:
				continue
			elif mode == 0 and body.state == 2:
				continue
#			elif mode == 1 and (body.state == 2 or body.state == 3):
#				continue
			
			if mode == 4: # Dynamic pulse
				if body.state == 0: # If patroller is patrolling (soothe), alert patrol
					body.updateState(1)
				elif body.state == 1 or body.state == 2: # Patroller is chasing or alert patrolling, CHASE
					body.updateState(2)
			else:
				body.updateState(mode)
	
#	match mode:
#		1: color = Color.WHITE
#		2: color = Color.DARK_ORANGE
#		3: color = Color.SANDY_BROWN
#		4: color = Color.RED
	showPulse()
	queue_free()
