extends NPCMovement

func _physics_process(_delta):
	lookAtPlayer()
	
	if OverworldGlobals.getPlayer().velocity == Vector2.ZERO:
		ANIMATOR.seek(1, true)
		ANIMATOR.pause()
		BODY.velocity = Vector2.ZERO
	else:
		followPlayer()
	
	BODY.move_and_slide()

func followPlayer():
	if int(OverworldGlobals.getPlayer().player_direction.rotation_degrees) == 90 or int(OverworldGlobals.getPlayer().player_direction.rotation_degrees) == -90:
		TARGET = OverworldGlobals.getPlayer().player_direction.get_node('FollowPoint').global_position + Vector2(0, 13)
	else:
		TARGET = OverworldGlobals.getPlayer().player_direction.get_node('FollowPoint').global_position
	
	BODY.velocity = BODY.global_position.direction_to(TARGET) * BASE_MOVE_SPEED

func lookAtPlayer():
	if int(OverworldGlobals.getPlayer().get_node('PlayerDirection').rotation_degrees) == 90:
		updateSprite('L')
	elif int(OverworldGlobals.getPlayer().get_node('PlayerDirection').rotation_degrees) == -90:
		updateSprite('R')
	elif int(OverworldGlobals.getPlayer().get_node('PlayerDirection').rotation_degrees) == 179:
		updateSprite('U')
	elif int(OverworldGlobals.getPlayer().get_node('PlayerDirection').rotation_degrees) == 0:
		updateSprite('D')
