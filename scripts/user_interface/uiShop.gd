extends Control

@onready var wares = $Wares/Scroll/VBoxContainer
@onready var description = $DescriptionPanel/Label
@onready var stats = $StatsPanel/Label
@onready var purchase_button = $Purchase
@onready var currency = $Currency

var selected_item
var modifier = 1.0

func loadWares(wares_array):
	for item in wares_array:
		var button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = item.NAME
		button.pressed.connect(
			func setSelected():
				selected_item = item
				if currency < selected_item.VALUE * modifier:
					purchase_button.disabled = true
				else:
					purchase_button.disabled = false
		)
		wares.add_child(button)

func _on_purchase_pressed():
	if selected_item is ResItem:
		currency -= selected_item.VALUE * modifier
		PlayerGlobals.addItemResourceToInventory(selected_item)
