extends Control

@onready var craftables = $Craftables/ScrollContainer/VBoxContainer
@onready var description = $DescriptionPanel/DescriptionLabel
@onready var craft_button = $Recipe/Craft
@onready var recipe_label = $Recipe/RecipeLabel

var selected_recipe: ResRecipe

func _on_ready():
	craft_button.hide()
	for recipe in PlayerGlobals.KNOWN_RECIPES:
		var button = Button.new()
		button.size.x = 9999
		button.text = str(recipe.OUTPUT.NAME)
		addButtonToPanel(recipe, button)

func addButtonToPanel(recipe: ResRecipe, button: Button):
	craftables.add_child(button)
	button.pressed.connect(
		func setSelectedItem(): 
			selected_recipe = PlayerGlobals.getRecipe(recipe)
			description.text = recipe.OUTPUT.DESCRIPTION
			recipe_label.text = recipe.getStringRecipe()
			craft_button.visible = recipe.hasRequiredItems()
			)

func _on_craft_pressed():
	selected_recipe.craft()
	if !selected_recipe.hasRequiredItems():
		craft_button.hide()
