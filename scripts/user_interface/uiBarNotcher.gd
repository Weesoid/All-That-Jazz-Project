extends Control
class_name BarNotcher

@export var notch_thresholds: Array[float] = []
@export var threshold_percent: float = 0.0
@export var notch_color:Color=Color(Color.RED,0.75)

@onready var notch = $Notch

func _ready():
	await get_tree().create_timer(1.0).timeout
	var bar = get_parent()
	if threshold_percent > 0:
		var total = 0
		while (total+(threshold_percent*2)) < 1.0:
			notch_thresholds.append(total+threshold_percent)
			total += threshold_percent
	print(notch_thresholds)
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
