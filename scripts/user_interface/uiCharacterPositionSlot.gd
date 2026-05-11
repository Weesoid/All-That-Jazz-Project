extends Control
class_name CharacterSlot

@onready var character_button_container = $CharacterButtonContainer
## 3,2 Backline 1,0 frontline
@export_range(0,3) var formation_position:int = 0
var assign_position:bool=true

func _can_drop_data(at_position, data):
	return data is CharacterButton

func _drop_data(at_position, data):
	addCharacter(data)

func addCharacter(button: CharacterButton):
	if character_button_container.get_children().size() > 0:
		var current_button = character_button_container.get_children()[0]
		current_button.reparent(button.get_parent())
	
	if button.get_parent() != null:
		button.reparent(character_button_container)
	else:
		character_button_container.add_child(button)
 
func addCharacterNoPos(button: CharacterButton):
	assign_position=false
	character_button_container.add_child(button)
	assign_position=true

func _on_character_button_container_child_entered_tree(node):
	if node is CharacterButton:
		node.combatant.assigned_position=formation_position
