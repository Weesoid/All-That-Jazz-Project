extends Control

@onready var travel_panel = $FastTravelAreas/MarginContainer/ScrollContainer/VBoxContainer
@onready var image = $PanelContainer/TextureRect
@onready var description = $PanelContainer2/RichTextLabel
var map_component_data = {}

func _ready():
	for location in PlayerGlobals.FAST_TRAVEL_LOCATIONS:
		var button = OverworldGlobals.createCustomButton()
		var map = load(location).instantiate()
		var map_data = map.get_node('MapDataComponent')
		button.text = map_data.NAME
		map_component_data[location] = [map_data.NAME, map_data.DESCRIPTION, map_data.IMAGE]
		button.pressed.connect(func(): travel(location))
		button.focus_entered.connect(
			func():
				description.text = map_component_data[location][1]
				if map_component_data[location][2] != null:
					image.texture = map_component_data[location][2]
		)
		travel_panel.add_child(button)
		map.queue_free()
	
	OverworldGlobals.setMenuFocus(travel_panel)

func travel(location):
	if OverworldGlobals.getCurrentMap().scene_file_path == location:
		OverworldGlobals.closeMenu(self)
		OverworldGlobals.showPlayerPrompt("You're already here!")
	else:
		OverworldGlobals.closeMenu(self)
		OverworldGlobals.changeMap(location)
