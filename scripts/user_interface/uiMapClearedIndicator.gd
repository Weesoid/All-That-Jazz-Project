extends Node2D

@onready var animator = $AnimationPlayer
@onready var bar_animator = $ProgressBar/AnimationPlayer
@onready var experience = $ProgressBar
@onready var level = $ProgressBar/Label
@onready var loot = $Loot
@export var added_exp: int


func showAnimation(show_clear:bool, patroller_group: PatrollerGroup):
	if !show_clear:
		animator.play("Show_Started")
	else:
		var tween = create_tween()
		animator.play("Show")
		showLoot(patroller_group)
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

func showLoot(patroller_group: PatrollerGroup):
	var bank = patroller_group.reward_bank['loot']
#	var tamed = OverworldGlobals.getCurrentMap().REWARD_BANK['tamed']
	for drop in bank.keys():
		var icon: TextureRect = TextureRect.new()
		var tween = create_tween()
		icon.texture = drop.ICON.duplicate()
		loot.add_child(icon)
		var count_label = Label.new()
		count_label.text = str(bank[drop])
		count_label.theme = preload("res://design/OutlinedLabel.tres")
		icon.add_child(count_label)
		tween.tween_property(icon, 'scale', Vector2(1.25, 1.25), 0.25)
		tween.tween_property(icon, 'scale', Vector2(1.0, 1.0), 0.5)
		OverworldGlobals.playSound("res://audio/sounds/651515__1bob__grab-item.ogg", 4.0)
		await get_tree().create_timer(0.15).timeout
#	for combatant_path in tamed:
#		var combatant = load(combatant_path)
#		var icon = createIcon(combatant)
#		var tween = create_tween()
#		tween.tween_property(icon, 'scale', Vector2(1.25, 1.25), 0.25)
#		tween.tween_property(icon, 'scale', Vector2(1.0, 1.0), 0.25)
#		loot.add_child(icon)
#		OverworldGlobals.playSound("res://audio/sounds/52_Dive_02.ogg", 4.0)
#		await get_tree().create_timer(0.15).timeout

func createIcon(combatant: ResCombatant):
	combatant.initializeCombatant()
	var icon = TextureRect.new()
	var atlas = AtlasTexture.new()
	atlas.region = Rect2(0, 0, 48, 48)
	atlas.atlas = combatant.SCENE.get_node('Sprite2D').texture
	icon.texture = atlas
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	combatant.SCENE.queue_free()
	return icon 
