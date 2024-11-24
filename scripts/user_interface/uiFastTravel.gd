extends Control

@onready var travel_panel = $FastTravelAreas/MarginContainer/ScrollContainer/VBoxContainer
@onready var description = $PanelContainer2/RichTextLabel
var map_component_data = {}

func _ready():
	PlayerGlobals.addFastTravelArea(OverworldGlobals.getCurrentMap().scene_file_path, OverworldGlobals.getCurrentMap().getPatrollers().size()<=0)
	for location in PlayerGlobals.CLEARED_MAPS.keys():
		var button = OverworldGlobals.createCustomButton()
		var map = load(location).instantiate()
		button.text = map.NAME
		map_component_data[location] = [map.NAME, map.DESCRIPTION, map.IMAGE, map.EVENTS]
		button.pressed.connect(func(): travel(location))
		button.focus_entered.connect(
			func():
				getMapInfo(location, map_component_data)
		)
		button.mouse_entered.connect(
			func():
				getMapInfo(location, map_component_data)
		)
		if location == OverworldGlobals.getCurrentMap().scene_file_path or !PlayerGlobals.CLEARED_MAPS[location]['fast_travel']:
			button.disabled = true
		if !PlayerGlobals.CLEARED_MAPS[location]['cleared']:
			button.icon = preload("res://images/sprites/icon_multi_enemy.png")
		travel_panel.add_child(button)
		map.queue_free()
	
	OverworldGlobals.setMenuFocus(travel_panel)

func getMapInfo(location, map_data):
	description.text = map_data[location][0].to_upper()+'\n'
	description.text += map_data[location][1]+'\n\n'
	var map_event = PlayerGlobals.CLEARED_MAPS[location]
	if !map_event['cleared']:
		description.text += 'OCCUPIED BY: %s' % CombatGlobals.getFactionName(map_event['faction'])+'\n'
	if map_event['events'].has('combat_event'):
		description.text += 'COMBAT_EVENT: %s' % map_event['events']['combat_event'] + '\n'
	if map_event['events'].has('time_limit'):
		description.text += 'TIME_LIMIT: %s' % map_event['events']['time_limit'] + '\n'
	if map_event['events'].has('additional_enemies'):
		description.text += 'ADDITIONAL_ENEMIES: %s' % CombatGlobals.getFactionName(map_event['events']['additional_enemies'])+ '\n'
	if map_event['events'].has('tameable_modifier'):
		description.text += 'TAMEABLE_MODIFIER: %s' % map_event['events']['tameable_modifier'] + '\n'
	if map_event['events'].has('patroller_effect'):
		description.text += 'PATROLLER_EFFECT: %s' % map_event['events']['patroller_effect'] + '\n'
	if map_event['events'].has('reward_item'):
		description.text += 'REWARD_ITEM: %s' % map_event['events']['reward_item'] + '\n'
	if map_event['events'].has('reward_multipliers'):
		description.text += 'REWARD_MULTIPLIERS: %s' % map_event['events']['reward_multipliers'] + '\n'



func travel(location):
	OverworldGlobals.closeMenu(self)
	OverworldGlobals.changeMap(location, '0,0,0', 'FastTravel')
