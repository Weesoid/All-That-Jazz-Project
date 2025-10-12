extends CustomButton
class_name RecipeButton

@export var item_filename: String
@onready var comp_container = $MarginContainer/HBoxContainer
@onready var comp_a: ItemComponentIcon = $MarginContainer/HBoxContainer/ItemComponentIcon
@onready var comp_b: ItemComponentIcon = $MarginContainer/HBoxContainer/ItemComponentIcon2
@onready var comp_c: ItemComponentIcon = $MarginContainer/HBoxContainer/ItemComponentIcon3
@onready var result_item: ItemComponentIcon = $MarginContainer/HBoxContainer/ItemComponentIcon4
var recipe
var recipe_result
var components = []

func _ready():
	$HoldProgress.modulate=hold_color
	var result_item_resource = load("res://resources/items/%s.tres" % item_filename)
	recipe = InventoryGlobals.getItemRecipe(result_item_resource.getFilename())
	recipe_result = InventoryGlobals.getRecipeResult(recipe)
	var i = 0
	for component_icon in [comp_a,comp_b,comp_c]:
		if i == recipe.size():
			break
		
		var component_filename = recipe.keys()[i]
		var item = load("res://resources/items/%s.tres" % component_filename)
		var count = recipe[component_filename]
		component_icon.item = item
		component_icon.required = count
		component_icon.update()
		component_icon.show()
		i+=1
	
	components = [comp_a,comp_b,comp_c].filter(func(comp): return comp.visible)
	result_item.item = result_item_resource
	result_item.required = InventoryGlobals.getCraftCount(item_filename)
	description_text = recipe_result[0].getInformation()
	description_offset = Vector2(270,0)
	updateInformation()

func canAddToInventory():
	var result = InventoryGlobals.getRecipeResult(recipe)
	return InventoryGlobals.canAdd(result[0], int(result[1]), false) and InventoryGlobals.canCraft(result[0].getFilename())

func updateInformation():
	disabled = !canAddToInventory()
	if disabled:
		dimButton()
	else:
		undimButton()
	highlightMissingComponents()

func dimButton():
	modulate = Color(Color.DARK_GRAY,0.95)

func undimButton():
	modulate= Color.WHITE

func highlightMissingComponents():
	for component_icon in components:
		component_icon.update()
	
	result_item.update(true)


