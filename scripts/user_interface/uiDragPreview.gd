extends Control
class_name DragPreview

@onready var drag_texture = $TextureRect
var texture: Texture

func _ready():
	drag_texture.texture = texture
