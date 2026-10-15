extends Node2D
## Debug platformer level. "Back to story" (or Esc) returns to the saved story scene.

@onready var back_button: Button = $UI/BackButton


func _ready() -> void:
	back_button.pressed.connect(_back_to_story)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back_to_story()


func _back_to_story() -> void:
	get_tree().change_scene_to_file(SaveGame.scene_path)
