extends Node
## SaveGame (autoload): remembers where the player is in the story and their settings.
## Saved to user://save.cfg (on Windows: %APPDATA%\Godot\app_userdata\Swords of heavan\).

const SAVE_PATH := "user://save.cfg"
const FIRST_SCENE := "res://scenes/chapter1_intro.tscn"

var scene_path: String = FIRST_SCENE
var page: int = 0
var fullscreen: bool = false
var volume: float = 1.0 # 0.0 to 1.0


func _ready() -> void:
	load_game()
	apply_settings()


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return # no save yet
	scene_path = cfg.get_value("progress", "scene", FIRST_SCENE)
	page = cfg.get_value("progress", "page", 0)
	fullscreen = cfg.get_value("settings", "fullscreen", false)
	volume = cfg.get_value("settings", "volume", 1.0)
	if not ResourceLoader.exists(scene_path):
		scene_path = FIRST_SCENE
		page = 0


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "scene", scene_path)
	cfg.set_value("progress", "page", page)
	cfg.set_value("settings", "fullscreen", fullscreen)
	cfg.set_value("settings", "volume", volume)
	cfg.save(SAVE_PATH)


## Call this whenever the player reaches a new page.
func set_progress(path: String, new_page: int) -> void:
	scene_path = path
	page = new_page
	save_game()


## The saved page for a scene (0 if the save is from a different scene).
func page_for(path: String) -> int:
	return page if path == scene_path else 0


func reset_progress() -> void:
	scene_path = FIRST_SCENE
	page = 0
	save_game()


func apply_settings() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	AudioServer.set_bus_volume_db(0, linear_to_db(max(volume, 0.0001)))
	AudioServer.set_bus_mute(0, volume <= 0.001)
