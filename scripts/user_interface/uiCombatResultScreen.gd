extends Control
class_name CombatResults

signal done

@onready var center_point = $Marker2D.global_position
@onready var combat_scene = CombatGlobals.getCombatScene()
@onready var animator = $AnimationPlayer2
@onready var loot_icons = $Spoils/LootContainer
@onready var spoils = $Spoils
@onready var exp_bar = $Spoils/EarntExp/CurrentExp
@onready var earnt_exp_bar = $Spoils/EarntExp
@onready var earnt_exp_label = $Spoils/EarntExp/EarntExpLabel

var morale = PlayerGlobals.current_exp
var bonuses
var reward_bank
var drops
var done_showing = false

func _ready():
	animator.play("Show")
	await animator.animation_finished
	for bonus in bonuses:
		CombatGlobals.spawnIndicator(center_point,'[color=yellow]'+bonus,'QTE',self)
		OverworldGlobals.playSound("721774__maodin204__cash-register.ogg")
		await get_tree().create_timer(0.6).timeout
	animator.play("Show_Spoils")
	await animator.animation_finished
	create_tween().tween_property(spoils,'modulate', Color.WHITE,0.3)
	showLoot()
	await setExperienceBar()
	done_showing=true

func setExperienceBar():
	var tween = create_tween()
	exp_bar.max_value = PlayerGlobals.getRequiredExp()
	earnt_exp_bar.max_value = PlayerGlobals.getRequiredExp()
	exp_bar.value = PlayerGlobals.current_exp
	tween.tween_property(earnt_exp_bar,'value',PlayerGlobals.current_exp+reward_bank['experience'],0.5)
	earnt_exp_label.text = '+'+str(int(reward_bank['experience']))+'.0'
	await tween.finished

func showLoot():
	for drop in reward_bank['loot'].keys():
		var icon = OverworldGlobals.createItemIcon(drop,reward_bank['loot'][drop])
		if drops.has(drop):
			var tween = create_tween()
			var tween_b = create_tween()
			loot_icons.add_child(icon)
			tween.tween_property(icon, 'scale', Vector2(1.25, 1.25), 0.25)
			tween.tween_property(icon, 'scale', Vector2(1.0, 1.0), 0.5)
			tween_b.tween_property(icon, 'self_modulate', Color.YELLOW, 0.25)
			tween_b.tween_property(icon, 'self_modulate', Color.WHITE, 1.5)
			OverworldGlobals.playSound("res://audio/sounds/651515__1bob__grab-item.ogg", 4.0)
		else:
			loot_icons.add_child(icon)
		await get_tree().create_timer(0.25).timeout

func _unhandled_input(_event):
	if Input.is_action_just_released('ui_accept') and done_showing:
		done.emit()

