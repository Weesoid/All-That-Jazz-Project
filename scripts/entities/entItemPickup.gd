extends CharacterBody2D
class_name ItemPickup

@onready var sprite = $ItemSprite
@onready var glint = $Glint
@onready var point_light = $Glint/PointLight2D

@export var pickups: Array[ResItemDrop]
@export var do_gravity:bool = true
@export var show_sprite:bool=false
@export var important:bool = false

func _ready():
	$AnimationPlayer.play("Loop")
	if show_sprite:
		sprite.texture = pickups[0].item.icon
	if important:
		glint.modulate = Color.GOLDENROD
		point_light.color = Color.GOLDENROD
		point_light.show()
	

func _physics_process(delta):
	if do_gravity and not is_on_floor():
		velocity.y += ProjectSettings.get_setting('physics/2d/default_gravity') * delta
		move_and_slide()

func interact():
	if !canPickup():
		return
	
	for drop in pickups:
		InventoryGlobals.addItemResource(drop.item, drop.drop_count)
	PlayerGlobals.addMapLog(
		OverworldGlobals.getCurrentMap().scene_file_path,
		'remove',
		[name]
		)
	if important:
		OverworldGlobals.playSound("res://audio/sounds/234924__gordeszkakerek__pick-up-or-found-it-secret-item.ogg")
	if show_sprite:
		await doPickupAnimation()
	queue_free()

func doPickupAnimation():
	glint.hide()
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_property(sprite,'global_position', OverworldGlobals.player.sprite.global_position+Vector2(0,-24),0.25)
	tween.tween_property(sprite, 'modulate', Color.TRANSPARENT,0.25)
	await tween.finished

func canPickup()->bool:
	for drop  in pickups:
		if !InventoryGlobals.canAdd(drop.item, drop.drop_count): return false
	
	return true
