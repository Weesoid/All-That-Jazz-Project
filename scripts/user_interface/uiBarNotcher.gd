extends Control
class_name BarNotcher

@export var notch_thresholds: Array[float] = []
@export var notch_color:Color=Color(Color.RED,0.75)

@onready var notch = $Notch

func _ready():
	await get_tree().create_timer(0.25).timeout
	for threshold in notch_thresholds:
		var notch_dupe = notch.duplicate()
		add_child(notch_dupe)
		notch_dupe.position.x = size.x*threshold
		notch_dupe.modulate = notch_color
		notch_dupe.show()


func _on_tree_entered():
	pass


func _on_size_flags_changed():
	print('sisssdsd')
	print(size)
