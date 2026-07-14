extends Control
class_name CharacterSlot

@onready var character_button_container = $CharacterButtonContainer
@onready var gradient_texture = $TextureRect

## 3,2 Backline 1,0 frontline
@export_range(0,3) var formation_position:int = 0
var assign_position:bool=true
var character_button:CharacterButton

func _ready():
	UIGlobals.addFocusMode(self, gradient_texture)
	focus_mode = Control.FOCUS_ALL if character_button == null else Control.FOCUS_NONE

func _can_drop_data(_at_position, data):
	return data is CharacterButton

func _drop_data(_at_position, data):
	addCharacter(data)
	
func addCharacter(button: CharacterButton):
	if character_button != null:
		character_button.reparent(button.get_parent())
	
	if button.get_parent() != null:
		button.reparent(character_button_container)
	else:
		character_button_container.add_child(button)
	
	await get_tree().process_frame
	character_button.grab_focus()

func reset():
	character_button = null
	if character_button_container.get_child_count() > 0:
		character_button_container.get_child(0).queue_free()

func addCharacterNoPos(button: CharacterButton):
	assign_position=false
	character_button_container.add_child(button)
	assign_position=true

func _on_character_button_container_child_entered_tree(node):
	if node is CharacterButton:
		node.combatant.assigned_position=formation_position
	
	await get_tree().process_frame
	character_button = node
	focus_mode = Control.FOCUS_NONE

func _on_character_button_container_child_exiting_tree(node):
	await node.tree_exited
	character_button = null
	focus_mode = Control.FOCUS_ALL

func _unhandled_input(_event):
	if (has_focus() or (character_button != null and character_button.has_focus())) and _can_drop_data(position, get_viewport().gui_get_drag_data()) and UIGlobals.isUsingController() and Input.is_action_pressed("ui_accept"):
		UIGlobals.getControllerAdapter().fastClick()
		#_drop_data(position, get_viewport().gui_get_drag_data())
		#Input.action_press("ui_cancel")
