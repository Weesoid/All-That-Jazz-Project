extends Control
class_name RewardBank

@onready var patrol_label = $Patrol/Label
@onready var loot_container = $Patrol/Rewards/HBoxContainer
@onready var experience = $Patrol/Rewards/Label
var patroller_group: PatrollerGroup

func updateBank(rewards:Dictionary):
	patrol_label.text = getPatrolName(patroller_group.name)
	for item in rewards['loot']:
		var icon = OverworldGlobals.createItemIcon(item, rewards['loot'][item])
		loot_container.add_child(icon)
	experience.text = 'Morale: %s' % str(rewards['experience'])

func getPatrolName(group_name: StringName):
	var group_num = group_name.replace('PatrollerGroup','')
	if group_num == '':
		group_num = '1'
	return 'Patrol %s' % group_num

func giveRewardsAnimation():
	pass
