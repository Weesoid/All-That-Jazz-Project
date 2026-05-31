extends CustomButton
class_name RecipeButton

const ANVIL_ICON = preload("res://images/sprites/icon_repair.png")
@export var item: ResItem
@onready var comp_container = $MarginContainer/HBoxContainer/HBoxContainer
@onready var result_item: ItemComponentIcon = $MarginContainer/HBoxContainer/HBoxContainer2/Result
@onready var hammer_texture = $MarginContainer/HBoxContainer/HBoxContainer2/TextureRect
var is_repair_recipe:bool=false
var recipe
var recipe_result
var icons_initialized:bool=false
signal craft_item(item)

func setItem(p_item:ResItem):
	item = p_item
	update()

func _ready():
	for ico in comp_container.get_children():
		ico.hide()
	$HoldProgress.modulate=hold_color
	setTooltip()
	update()
	hold_delay = 0.05
	hold_time = 0.2
	if is_repair_recipe:
		hammer_texture.texture = ANVIL_ICON
	
func update():
	if !icons_initialized:
		initializeIcons()
	for ico in comp_container.get_children():
		if ico.item == null: continue
		ico.update_counts()
	
	result_item.update_counts(is_repair_recipe)
	#setDisabled(!canCraftOrRepair())

func initializeIcons():
	var recipe = InventoryGlobals.getRecipe(item)
	
	var component_container = comp_container.get_children()
	var icon_count=0
	for comp in recipe:
		var component_icon = component_container[icon_count]
		component_icon.setItem(InventoryGlobals.loadItemResource(comp), recipe[comp])
		component_icon.show()
		icon_count += 1
	if is_repair_recipe:
		result_item.setItem(item,1,1)
	else:
		result_item.setItem(item,1,InventoryGlobals.getCraftCount(item.getFilename()))
	icons_initialized = true

func _on_held_press():
	if canCraftOrRepair():
		craft_item.emit(item)

func canCraftOrRepair():
	return (!is_repair_recipe and InventoryGlobals.canCraft(item)) or (is_repair_recipe and item.canRepair(1))
