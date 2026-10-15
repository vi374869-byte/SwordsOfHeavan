extends Control
## Main menu. The art in "Canvas" is laid out at its original 2000x1800 size
## and scaled to fit the window, so you can move pieces around in the editor.

const DESIGN_SIZE := Vector2(2000, 1800)
const HOVER_SCALE := 1.08
const HOVER_TIME := 0.12

@onready var canvas: Control = $Canvas
@onready var play_button: TextureButton = $Canvas/PlayButton
@onready var settings_button: TextureButton = $Canvas/SettingsButton
@onready var quit_button: TextureButton = $Canvas/QuitButton
@onready var settings_layer: Control = $SettingsLayer
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var volume_slider: HSlider = %VolumeSlider
@onready var restart_button: Button = %RestartButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	for b in [play_button, settings_button, quit_button]:
		_setup_hover(b)
	play_button.pressed.connect(_on_play)
	settings_button.pressed.connect(_open_settings)
	quit_button.pressed.connect(_on_quit)

	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	restart_button.pressed.connect(_on_restart)
	back_button.pressed.connect(_close_settings)

	settings_layer.hide()
	get_viewport().size_changed.connect(_fit_canvas)
	_fit_canvas()


func _unhandled_input(event: InputEvent) -> void:
	if settings_layer.visible and event.is_action_pressed("ui_cancel"):
		_close_settings()


# Scale the 2000x1800 art to fit the window and center it.
func _fit_canvas() -> void:
	var vp := get_viewport_rect().size
	var s: float = min(vp.x / DESIGN_SIZE.x, vp.y / DESIGN_SIZE.y)
	canvas.scale = Vector2(s, s)
	canvas.position = (vp - DESIGN_SIZE * s) / 2.0


# ---------- buttons ----------

func _setup_hover(b: TextureButton) -> void:
	b.pivot_offset = b.size / 2.0
	b.mouse_entered.connect(_hover.bind(b, true))
	b.mouse_exited.connect(_hover.bind(b, false))


func _hover(b: TextureButton, on: bool) -> void:
	var t := b.create_tween().set_parallel(true)
	t.tween_property(b, "scale", Vector2.ONE * (HOVER_SCALE if on else 1.0), HOVER_TIME)
	t.tween_property(b, "modulate", Color(1.15, 1.15, 1.15) if on else Color.WHITE, HOVER_TIME)


func _on_play() -> void:
	get_tree().change_scene_to_file(SaveGame.scene_path)


func _on_quit() -> void:
	get_tree().quit()


# ---------- settings ----------

func _open_settings() -> void:
	fullscreen_check.set_pressed_no_signal(SaveGame.fullscreen)
	volume_slider.set_value_no_signal(SaveGame.volume * 100.0)
	restart_button.text = "Restart story"
	settings_layer.show()


func _close_settings() -> void:
	SaveGame.save_game()
	settings_layer.hide()


func _on_fullscreen_toggled(on: bool) -> void:
	SaveGame.fullscreen = on
	SaveGame.apply_settings()


func _on_volume_changed(value: float) -> void:
	SaveGame.volume = value / 100.0
	SaveGame.apply_settings()


func _on_restart() -> void:
	SaveGame.reset_progress()
	restart_button.text = "Story restarted"
