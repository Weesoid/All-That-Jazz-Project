extends CharacterBody2D
class_name NPCSceneFollower

@onready var follower_component = $NPCFollow

func _ready():
	follower_component.FOLLOW_POINT = get_parent().global_position
