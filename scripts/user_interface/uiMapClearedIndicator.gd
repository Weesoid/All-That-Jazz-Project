extends Node2D

@onready var animator = $AnimationPlayer
@onready var bar_animator = $ProgressBar/AnimationPlayer
@onready var experience = $ProgressBar
@onready var level = $ProgressBar/Label
@onready var loot = $Loot
@export var added_exp: int

func _ready():
	if !PlayerGlobals.CLEARED_MAPS.has(OverworldGlobals.getCurrentMap().NAME) and !OverworldGlobals.getCurrentMap().SAFE:
		animator.play("Show_Started")
	else:
		# Add progressal sound!
		var tween = create_tween()
		animator.play("Show")
		showLoot()
		level.text = str(PlayerGlobals.PARTY_LEVEL)
		experience.max_value = PlayerGlobals.getRequiredExp()
		experience.value = PlayerGlobals.CURRENT_EXP
		OverworldGlobals.playSound("res://audio/sounds/698992__robindouglasjohnson__modeltoy-train-set.ogg",4.0)
		tween.tween_property(experience, 'value', experience.value+added_exp,0.5)
		await tween.finished
		if experience.value >= experience.max_value:
			level.text = str(PlayerGlobals.PARTY_LEVEL)
			bar_animator.play("Level_Up")
			OverworldGlobals.playSound("494984__original_sound__cinematic-trailer-risers-1.ogg")
	
	await animator.animation_finished
	queue_free()

func showLoot():
	var bank = OverworldGlobals.getCurrentMap().REWARD_BANK['loot']
	for drop in bank.keys():
		var icon: TextureRect = TextureRect.new()
		var tween = create_tween()
		icon.texture = drop.ICON.duplicate()
		loot.add_child(icon)
		tween.tween_property(icon, 'scale', Vector2(1.25, 1.25), 0.25)
		tween.tween_property(icon, 'scale', Vector2(1.0, 1.0), 0.5)
		OverworldGlobals.playSound("res://audio/sounds/651515__1bob__grab-item.ogg", 4.0)
		await get_tree().create_timer(0.15).timeout
