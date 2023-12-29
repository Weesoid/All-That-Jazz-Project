extends PanelContainer

@onready var charm_label = $RichTextLabel

func showEquipped():
	charm_label.text = ''
	for item in InventoryGlobals.INVENTORY:
		if item is ResUtilityCharm and item.isEquipped(): 
			charm_label.text += item.NAME+'\n'
