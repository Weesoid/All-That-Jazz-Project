extends Node2D

#@export var sprite: Sprite2D
@export var image_count:int=8
@export var delay_time:float = 0.1
@onready var delay = $Timer

func showAfterImages(sprite):
	var world = CombatGlobals.getCombatScene() if CombatGlobals.inCombat() else OverworldGlobals.getCurrentMap()
	for i in range(image_count):
		var duped_sprite = sprite.duplicate()
		var tween = world.create_tween().set_parallel().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.bind_node(duped_sprite)
		tween.finished.connect(duped_sprite.queue_free)
		#tween.finished.connect(duped_sprite.queue_free)
		duped_sprite.z_index = sprite.z_index-1
		duped_sprite.modulate = Color(Color.WHITE,0.25)
		duped_sprite.global_position = sprite.global_position
		duped_sprite.show()
		world.add_child(duped_sprite)
		tween.tween_property(duped_sprite, 'modulate', Color.TRANSPARENT,0.6)
		await get_tree().create_timer(delay_time).timeout
		#await tween.finished
		#delay.start(delay_time)
		#await tween.finished
		#await delay.timeout 
		#duped_sprite.queue_free()
		#tween.tween_property(sprite, 'modulate', Color.TRANSPARENT,0.25)
	await get_tree().create_timer(1).timeout
	queue_free()
