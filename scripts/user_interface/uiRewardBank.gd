extends Control
class_name RewardBank

@onready var patrol_label = $Label
@onready var loot_container = $Rewards/HBoxContainer
@onready var experience = $Rewards/Label
var patroller_group: PatrollerGroup

func _ready():
	OverworldGlobals.group_cleared.connect(
		func(group):
			if group == patroller_group: 
				await get_tree().create_timer(0.5).timeout
				queue_free()
	)

func updateBank(rewards:Dictionary):
	clearLootIcons()
	
	patrol_label.text = getPatrolName(patroller_group.name)
	for item in rewards['loot']:
		var icon = OverworldGlobals.createItemIcon(item, rewards['loot'][item])
		loot_container.add_child(icon)
		popIcon(icon)
	experience.text = 'Morale: %s' % str(rewards['experience'])

func getPatrolName(group_name: StringName):
	var group_num = group_name.replace('PatrollerGroup','')
	if group_num == '':
		group_num = '1'
	return 'Patrol %s' % group_num

func clearLootIcons():
	for icon in loot_container.get_children():
		icon.queue_free()

func giveRewardsAnimation():
	pass

func popIcon(icon):
	var tween = create_tween()
	tween.tween_property(icon, 'scale', Vector2(1.25, 1.25), 0.25)
	tween.tween_property(icon, 'scale', Vector2(1.0, 1.0), 0.25)
