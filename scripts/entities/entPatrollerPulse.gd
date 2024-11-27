extends EffectPulse
class_name PatrollerPulse

var mode: int
var trigger_others=false

func applyPulseEffect():
	for body in get_overlapping_bodies():
		if body.has_node('NPCPatrolComponent'):
			var current_state = body.get_node('NPCPatrolComponent').STATE
			if mode == current_state:
				continue
			elif mode == 0 and current_state == 3:
				continue
			elif mode == 1 and (current_state == 2 or current_state == 3):
				continue
			
			if mode == 4:
				if current_state == 0:
					body.get_node('NPCPatrolComponent').updateMode(1)
				elif current_state == 1:
					body.get_node('NPCPatrolComponent').updateMode(2)
			else:
				body.get_node('NPCPatrolComponent').updateMode(mode)
	
	match mode:
		1: color = Color.WHITE
		2: color = Color.DARK_ORANGE
		3: color = Color.SANDY_BROWN
		4: color = Color.RED
	showPulse()
	queue_free()
