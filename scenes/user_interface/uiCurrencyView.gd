extends Label

@export var sixteen_size_font:bool = false

func _ready():
	if sixteen_size_font:
		add_theme_font_size_override("font_size", 16)

func _process(_delta):
	text = PlayerGlobals.addCommaToNum()
