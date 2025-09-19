extends EffectPulse
class_name PatrollerPulse

var mode: GenericPatroller.State
var dynamic_pulse:bool=false
var trigger_others=false

func applyPulseEffect():
	for body in get_overlapping_bodies():
		if body is GenericPatroller:
			if mode == body.state:
				continue
			elif mode == GenericPatroller.State.IDLE and body.state == GenericPatroller.State.CHASING:
				continue
			
			if dynamic_pulse: # Dynamic pulse
				if body.state == GenericPatroller.State.IDLE: # If patroller is patrolling (soothe), alert patrol
					body.updateState(GenericPatroller.State.CHASING)
				elif body.state == GenericPatroller.State.CHASING: # Patroller is chasing or alert patrolling, CHASE
					body.updateState(GenericPatroller.State.STUNNED)
			else:
				body.updateState(mode)
	
#	match mode:
#		1: color = Color.WHITE
#		2: color = Color.DARK_ORANGE
#		3: color = Color.SANDY_BROWN
#		4: color = Color.RED
	showPulse()
	queue_free()
