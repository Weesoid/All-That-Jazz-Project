extends CustomButton
class_name RecipeButton

@export var item_filename: String
@onready var comp_container = $MarginContainer/HBoxContainer
@onready var comp_a = $MarginContainer/HBoxContainer/CompA
@onready var comp_b = $MarginContainer/HBoxContainer/CompB
@onready var comp_c = $MarginContainer/HBoxContainer/CompC
@onready var result_item = $MarginContainer/HBoxContainer/Item
var recipe
var recipe_result
func _ready():
	$HoldProgress.modulate=hold_color
	var result_item_resource = load("res://resources/items/%s.tres" % item_filename)
	recipe = InventoryGlobals.getItemRecipe(result_item_resource.getFilename())
	recipe_result = InventoryGlobals.getRecipeResult(recipe)
	for i in range(recipe.keys().size()):
		var component_filename = recipe.keys()[i]
		var item = load("res://resources/items/%s.tres" % component_filename)
		var count = recipe[component_filename]
		comp_container.get_child(i).texture = item.icon
		comp_container.get_child(i).get_node('Label').text = 'x'+str(count)
		comp_container.get_child(i).show()
	
	result_item.texture = result_item_resource.icon
	result_item.get_node('Label').text = 'x'+InventoryGlobals.getCraftCount(item_filename)
	updateDisabled()

func canAddToInventory():
	var result = InventoryGlobals.getRecipeResult(recipe)
	return InventoryGlobals.canAdd(result[0], int(result[1]), false) and InventoryGlobals.canCraft(result[0].getFilename())

func updateDisabled():
	disabled = !canAddToInventory()
	if disabled:
		dimButton()
	else:
		undimButton()
	highlightMissingComponents()

func dimButton():
	modulate = Color(Color.DARK_GRAY,0.75)

func undimButton():
	modulate= Color.WHITE

func highlightMissingComponents():
	var i = 0
	for item_filepath in recipe.keys():
		var item = load("res://resources/items/%s.tres"%item_filepath) 
		var component_icon = comp_container.get_child(i)
		var count_label = component_icon.get_node('CurrentCount')
		if InventoryGlobals.hasItem(item,recipe[item_filepath]):
			count_label.modulate = Color.WHITE
			component_icon.self_modulate = Color.WHITE
		else:
			count_label.modulate = Color.RED
			component_icon.self_modulate = Color.RED
		if item is ResStackItem:
			count_label.text = str(item.stack)
			count_label.show()
		else:
			count_label.hide()
		i += 1 
	
	if recipe_result[0] is ResStackItem and InventoryGlobals.hasItem(recipe_result[0]):
		var stack_item = InventoryGlobals.getItem(recipe_result[0])
		result_item.get_node('CurrentCount').show()
		result_item.get_node('CurrentCount').text = str(stack_item.stack)
		if stack_item.stack >= stack_item.max_stack:
			result_item.get_node('CurrentCount').modulate = Color.YELLOW
		else:
			result_item.get_node('CurrentCount').modulate = Color.WHITE
	else:
		result_item.get_node('CurrentCount').hide()
		result_item.get_node('CurrentCount').modulate = Color.WHITE
