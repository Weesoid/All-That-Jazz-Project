extends Area2D
class_name ClimberArea

#func _on_body_exited(body):
#	if body is PlayerScene:
#		setClimbingFalse()
@onready var collision_box =  $"../PinArea/CollisionShape2D"
var player: PlayerScene
var player_snapped:bool=false

func _ready():
	await get_tree().create_timer(0.25).timeout
	player = OverworldGlobals.player
	player.landed.connect(
		func(from_climb):
			if from_climb: 
				player_snapped=false
				player.setClimbing(false)
			)

func _input(_event):
	if player == null or !playerInClimbable() or get_parent().must_shoot or !OverworldGlobals.player.isMovementAllowed() or !OverworldGlobals.player.climb_cooldown.is_stopped():
		return
	
	if inputtedMovement():
		if global_position.y > player.global_position.y and !player_snapped and Input.is_action_pressed("ui_move_down"): #and player.velocity.y > 0:
			#if get_parent().name == 'Rope2': print(global_position.distance_to(player.global_position))
			player.global_position.y += 16
			player_snapped=true
		player.setClimbing(true)
	
#	if OverworldGlobals.player.velocity.y < 0:
#		OverworldGlobals.player.climb_cooldown.start()
#		OverworldGlobals.player.climbing = false
#		OverworldGlobals.player.jump()
#		OverworldGlobals.player.toggleClimbAnimation(false)
#	if !OverworldGlobals.player.get_collision_mask_value(1):
#		OverworldGlobals.player.set_collision_mask_value(1, true)
#
#	if  OverworldGlobals.player.climbing and get_parent().isPlayerOnEnterArea() and Input.is_action_pressed("ui_move_up"):
#		get_parent().jumpRope(-220)
#		return
#	if inputtedMovement():
#		OverworldGlobals.player.fall_damage = 0
#		OverworldGlobals.player.climbing = true
#	if get_parent().isPlayerOnEnterArea() and inputtedMovement():
#		OverworldGlobals.player.setClimbing(true)
#		#OverworldGlobals.player.toggleClimbAnimation(true)
#		#OverworldGlobals.player.set_collision_mask_value(1, false)
##	elif !get_parent().isPlayerOnEnterArea() and inputtedMovement():
##		OverworldGlobals.player.toggleClimbAnimation(true)
##		OverworldGlobals.player.set_collision_mask_value(1, true)
#	elif !get_parent().isPlayerOnEnterArea() and OverworldGlobals.player.is_on_floor():
#		OverworldGlobals.player.setClimbing(false)

func inputtedMovement():
	return Input.is_action_pressed("ui_move_down") or (Input.is_action_pressed("ui_move_up") and !get_parent().isPlayerOnEnterArea())

#func setClimbingFalse():
#	OverworldGlobals.player.climbing = false
#	OverworldGlobals.player.toggleClimbAnimation(false)
#	if !OverworldGlobals.player.get_collision_mask_value(1):
#		OverworldGlobals.player.set_collision_mask_value(1, true)

func playerInClimbable():
	return get_overlapping_bodies().has(OverworldGlobals.player)
