extends ColorRect


@export var scroll_time:float = 3
@export var scroll_threshold:int = 4
@onready var container = $HBoxContainer
@onready var test_icon = $TestIcon


signal scroll_done
var scroll_active=false

func _ready():
	scroll_done.connect(scroll_cont)

func scroll_cont():
	print('scrolling!')
	container.position.x = size.x+4
	var tween = create_tween()
	tween.tween_property(container,'position',Vector2(-container.size.x,0),scroll_time)
	await tween.finished
	tween.kill()
	if container.get_child_count() >= scroll_threshold:
		scroll_done.emit()
	else:
		container.position = Vector2.ZERO
		scroll_active=false

#func _on_h_box_container_child_entered_tree(node):
#	if container != null and container.get_child_count() >= scroll_threshold and !scroll_active:
#		scroll_cont()

func add_icon(icon:TextureRect):
	container.add_child(icon)
	if container.get_child_count() >= scroll_threshold and !scroll_active:
		scroll_active=true
		scroll_cont()

#func _unhandled_input(event):
#	if Input.is_action_just_pressed("ui_accept"):
#		var icon = test_icon.duplicate()
#		container.add_child(icon)
#		icon.show()
#	if Input.is_action_just_pressed("ui_cancel"):
#		container.get_child(0).queue_free()
