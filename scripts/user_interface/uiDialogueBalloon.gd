extends Node2D


const DIALOGUE_PITCHES = {
	Entity = 0.8,
	Willis = 1
}

const MAX_WIDTH = 256

@export var response_template: Node
@export var file_suffix: String = ""
@onready var talk_sound: AudioStreamPlayer = $TalkSound
@onready var balloon = $Balloon
@onready var panel = $Balloon/Panel
@onready var arrow = $Balloon/TextureRect
@onready var character_portrait: Sprite2D = $Balloon/Portrait/Face
@onready var potrait_holder = $Balloon/Portrait
@onready var character_label: RichTextLabel = $Balloon/CharacterLabel
@onready var dialogue_label := $Balloon/MarginContainer/DialogueLabel
@onready var responses_menu = $Responses
@onready var animator = $AnimationPlayer
## The dialogue resource
var resource: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## The current line
var dialogue_line: DialogueLine:
	set(next_dialogue_line):
		if not next_dialogue_line:
			queue_free()
			return
		
		is_waiting_for_input = false
		
		# Remove any previous responses
		for child in responses_menu.get_children():
			responses_menu.remove_child(child)
			child.queue_free()
		
		dialogue_line = next_dialogue_line
		arrow.hide()
		
		# Character portait setting
		var speaker = dialogue_line.character.split("-")[0]
		var face_path = speaker
		if speaker == 'Player': 
			face_path = determinePlayerSpeaker()
		var portrait_path = "res://images/character_sprites/%s/%s.png" % [face_path.to_lower(), face_path.to_lower()]
		character_label.text = tr(speaker, "dialogue")
		if FileAccess.file_exists(portrait_path):
			var portrait = load(portrait_path)
			potrait_holder.show()
			character_portrait.visible = true
			character_portrait.texture = portrait
		else:
			potrait_holder.hide()
			character_portrait.visible = false
		
		dialogue_label.modulate.a = 0
		#dialogue_label.custom_minimum_size.x = dialogue_label.get_parent().size.x - 1
		dialogue_label.dialogue_line = dialogue_line
		
		setSizePosition(speaker)
		balloon.show()
		
		dialogue_label.modulate.a = 1
		dialogue_label.type_out()
		await dialogue_label.finished_typing
		arrow.show()
		# Show any responses we have
		responses_menu.modulate.a = 0
		if dialogue_line.responses.size() > 0:
			for response in dialogue_line.responses:
				# Duplicate the template so we can grab the fonts, sizing, etc
				var item: RichTextLabel = response_template.duplicate(0)
				item.name = "Response%d" % responses_menu.get_child_count()
				if not response.is_allowed:
					item.name = String(item.name) + "Disallowed"
					item.modulate.a = 0.4
				item.text = response.text
				item.show()
				responses_menu.add_child(item)
		
		# Wait for input
		if dialogue_line.responses.size() > 0:
			responses_menu.modulate.a = 1
			configure_menu()
		elif dialogue_line.time != null:
			var time = dialogue_line.dialogue.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
			await get_tree().create_timer(time).timeout
			next(dialogue_line.next_id)
		else:
			is_waiting_for_input = true
			balloon.focus_mode = Control.FOCUS_ALL
			balloon.grab_focus()
	get:
		return dialogue_line

func determinePlayerSpeaker():
	if OverworldGlobals.player.dialogue_name == 'Willis':
		return 'Willis'
	elif OverworldGlobals.player.dialogue_name == 'Archie':
		return 'Archie'

func setSizePosition(speaker:String):
	balloon.custom_minimum_size.x = min(balloon.size.x, MAX_WIDTH)
	if balloon.size.x > MAX_WIDTH:
		dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		balloon.custom_minimum_size.y = balloon.size.y
	await get_tree().process_frame
	
	var speaker_entity = OverworldGlobals.getEntity(speaker)
	var offset = Vector2.ZERO
	if speaker_entity.has_node('Sprite2D'):
		offset = speaker_entity.get_node('Sprite2D').offset
	var entity_position = Vector2(speaker_entity.global_position.x+offset.x,speaker_entity.global_position.y+offset.y)
	var cam_position = Vector2(entity_position.x,entity_position.y+OverworldGlobals.player.default_camera_pos.y)
	global_position.x = entity_position.x - (balloon.size.x/2)
	global_position.y = entity_position.y - (48+balloon.size.y)
	OverworldGlobals.moveCamera(cam_position)
	animator.play("Show")

func _ready() -> void:
	response_template.hide()
	#balloon.custom_minimum_size.x = MAX_WIDTH
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)


func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	get_viewport().set_input_as_handled()


## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	temporary_game_states = extra_game_states
	is_waiting_for_input = false
	resource = dialogue_resource
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)


## Go to the next line
func next(next_id: String) -> void:
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)


### Helpers


# Set up keyboard movement and signals for the response menu
func configure_menu() -> void:
	balloon.focus_mode = Control.FOCUS_NONE
	
	var items = get_responses()
	for i in items.size():
		var item: Control = items[i]
		
		item.focus_mode = Control.FOCUS_ALL
		
		item.focus_neighbor_left = item.get_path()
		item.focus_neighbor_right = item.get_path()
		
		if i == 0:
			item.focus_neighbor_top = item.get_path()
			item.focus_previous = item.get_path()
		else:
			item.focus_neighbor_top = items[i - 1].get_path()
			item.focus_previous = items[i - 1].get_path()
		
		if i == items.size() - 1:
			item.focus_neighbor_bottom = item.get_path()
			item.focus_next = item.get_path()
		else:
			item.focus_neighbor_bottom = items[i + 1].get_path()
			item.focus_next = items[i + 1].get_path()
		
		item.mouse_entered.connect(_on_response_mouse_entered.bind(item))
		item.gui_input.connect(_on_response_gui_input.bind(item))
	
	items[0].grab_focus()


# Get a list of enabled items
func get_responses() -> Array:
	var items: Array = []
	for child in responses_menu.get_children():
		if "Disallowed" in child.name: continue
		items.append(child)
		
	return items


func handle_resize() -> void:
	if not is_instance_valid(panel):
		call_deferred("handle_resize")
		return
	

	
func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false
	balloon.hide()


func _on_response_mouse_entered(item: Control) -> void:
	if "Disallowed" in item.name: return
	
	item.grab_focus()


func _on_response_gui_input(event: InputEvent, item: Control) -> void:
	if "Disallowed" in item.name: return
	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		next(dialogue_line.responses[item.get_index()].next_id)
	elif event.is_action_pressed("ui_accept") and item in get_responses():
		next(dialogue_line.responses[item.get_index()].next_id)


func _on_balloon_gui_input(event: InputEvent) -> void:
	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing	
	get_viewport().set_input_as_handled()
	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		next(dialogue_line.next_id)
	elif event.is_action_pressed("ui_accept") and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)

func _on_dialogue_label_spoke(letter: String, letter_index: int, speed: float) -> void:
	if not letter in [" ", "."]:
		var actual_speed: int = 4 if speed >= 1 else 2
		if letter_index % actual_speed == 0:
			talk_sound.play()
			var pitch = DIALOGUE_PITCHES.get(dialogue_line.character, 1)
			talk_sound.pitch_scale = randf_range(pitch - 0.1, pitch + 0.1)

func _on_panel_resized():
	handle_resize()


func _on_tree_exited():
	pass # Replace with function body.
