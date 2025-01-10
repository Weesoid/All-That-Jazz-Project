extends Resource
class_name SavedSettings

@export var window_mode: int = 0
@export var resolution: int = 0
@export var fps_cap: int = 60
@export var vsync: bool = true
@export var master_vol: float = 1.0
@export var music_vol: float = 1.0
@export var sound_vol: float = 1.0
@export var toggle_sprint: bool = true
@export var toggle_cheats: bool = false
@export var binds = InputHelper.serialize_inputs_for_actions()
