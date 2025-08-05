extends Control

@onready var animator = $AnimationPlayer
@onready var bar_animator = $ProgressBar/AnimationPlayer
@onready var experience = $ProgressBar
@onready var level = $ProgressBar/Label
@onready var loot = $Loot
@onready var message = $Label
@onready var bonus_exp = $BonusExp
@onready var bonus_loot = $BonusLoot
@onready var bonuses_animator = $AnimationPlayerBonus
@export var added_exp: int

func showAnimation(show_clear:bool, reward_bank:Dictionary):
	if OverworldGlobals.getCurrentMap().getClearState() == MapData.PatrollerClearState.FULL_CLEAR and hasBonuses():
		var map_events = OverworldGlobals.getCurrentMap().events
		if map_events.has('bonus_experience'):
			bonus_exp.text = ' + %s.0' % str(OverworldGlobals.getCurrentMap().events['bonus_experience'])
		else:
			bonus_exp.hide()
		bonuses_animator.play('Show')
		if map_events.has('bonus_loot'):
			showLoot(OverworldGlobals.getCurrentMap().events['bonus_loot'], bonus_loot)
	
	if !show_clear:
		animator.play("Show_Started")
	else:
		var tween = create_tween()
		animator.play("Show")
		showLoot(reward_bank['loot'])
		level.text = str(PlayerGlobals.team_level)
		experience.max_value = PlayerGlobals.getRequiredExp()
		experience.value = PlayerGlobals.current_exp
		OverworldGlobals.playSound("res://audio/sounds/698992__robindouglasjohnson__modeltoy-train-set.ogg",4.0)
		tween.tween_property(experience, 'value', experience.value+added_exp,0.5)
		await tween.finished
		if experience.value >= experience.max_value:
			level.text = str(PlayerGlobals.team_level)
			bar_animator.play("Level_Up")
			OverworldGlobals.playSound("494984__original_sound__cinematic-trailer-risers-1.ogg")
	
	await animator.animation_finished
	queue_free()

func hasBonuses():
	var map_events = OverworldGlobals.getCurrentMap().events
	return map_events.has('bonus_experience') or map_events.has('bonus_loot')
	
func showLoot(loot_dict,container=loot):
	for drop in loot_dict.keys():
		var icon = OverworldGlobals.createItemIcon(drop, loot_dict[drop])
		container.add_child(icon)
		var tween = create_tween()
		tween.tween_property(icon, 'scale', Vector2(1.25, 1.25), 0.25)
		tween.tween_property(icon, 'scale', Vector2(1.0, 1.0), 0.5)
		OverworldGlobals.playSound("res://audio/sounds/651515__1bob__grab-item.ogg", 4.0)
		await get_tree().create_timer(0.15).timeout

func createIcon(combatant: ResCombatant):
	combatant.initializeCombatant()
	var icon = TextureRect.new()
	var atlas = AtlasTexture.new()
	atlas.region = Rect2(0, 0, 48, 48)
	atlas.atlas = combatant.combatant_scene.get_node('Sprite2D').texture
	icon.texture = atlas
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	combatant.combatant_scene.queue_free()
	return icon 
