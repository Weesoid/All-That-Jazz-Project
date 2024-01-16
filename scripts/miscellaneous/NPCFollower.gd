extends CharacterBody2D
class_name NPCFollower

@onready var ANIMATOR = $Animator

var FOLLOW_LOCATION: int
var host_combatant: ResPlayerCombatant
var SPEED = 1.0

func _ready():
	add_collision_exception_with(OverworldGlobals.getPlayer())

func _physics_process(_delta):
	if !host_combatant.active:
		queue_free()
	
	# Positive SPEED allows followers to move, negative SPEED stops them. See 'setFollowerMotion' function
	if SPEED > 0.0:
		SPEED = OverworldGlobals.getPlayer().SPEED
		if OverworldGlobals.follow_array[FOLLOW_LOCATION] != null and OverworldGlobals.getPlayer().velocity != Vector2.ZERO:
			updateSprite()
			velocity = lerp(velocity, global_position.direction_to(OverworldGlobals.follow_array[FOLLOW_LOCATION]) * SPEED, 0.25)
		else:
			velocity = Vector2.ZERO
			ANIMATOR.seek(1, true)
			ANIMATOR.pause()
	
	move_and_slide()

func updateSprite():
	var player_direction: int = OverworldGlobals.getPlayer().player_direction.rotation_degrees
	
	if player_direction == 90:
		ANIMATOR.play('Walk_Left')
	elif player_direction == -90:
		ANIMATOR.play('Walk_Right')
	elif player_direction == 0:
		ANIMATOR.play('Walk_Down')
	elif player_direction == 179:
		ANIMATOR.play('Walk_Up')
