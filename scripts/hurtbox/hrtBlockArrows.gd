static func applyEffect(body: CharacterBody2D):
	print('piss')
#	body.patrol_component.process_mode = Node.PROCESS_MODE_DISABLED
#	await OverworldGlobals.playEntityAnimation(body.name, 'RESET')
#	await updateLineOfSight(body)
#	body.patrol_component.process_mode = Node.PROCESS_MODE_INHERIT

#static func updateLineOfSight(patroller: GenericPatroller):
#	var look_direction = patroller.patrol_component.LINE_OF_SIGHT.global_rotation_degrees
#
#	if look_direction < 135 and look_direction > 45:
#		await OverworldGlobals.playEntityAnimation(patroller.name, 'Block_Left')
#	elif look_direction < -45 and look_direction > -135:
#		await OverworldGlobals.playEntityAnimation(patroller.name, 'Block_Right')
#	elif look_direction < 45 and look_direction > -45:
#		await OverworldGlobals.playEntityAnimation(patroller.name, 'Block_Down')
#	else:
#		await OverworldGlobals.playEntityAnimation(patroller.name, 'Block_Up')
#
