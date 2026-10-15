extends Control
## Chapter 1 intro (test).
## Every child node named "Page..." is one page (an Image + an optional Bubble).
## Pages play in the order they appear in the Scene tree.
## Click or press Enter/Space to fade to the next page. Esc goes back to the menu.
## Clicking on the last page ends the story: progress resets and you return to the menu.
## Progress is saved through the SaveGame autoload (scripts/save_game.gd).
## To add a page: duplicate the last Page, rename it (e.g. Page9), swap its textures.

const FADE_TIME := 0.6
const MENU_SCENE := "res://scenes/main_menu.tscn"
const PLATFORMER_SCENE := "res://scenes/platformer_test.tscn" # debug

var pages: Array[Control] = []
var index := 0
var busy := false


func _ready() -> void:
	for child in get_children():
		if child is Control and String(child.name).begins_with("Page"):
			pages.append(child)
	# Debug button in the top-right corner (it's drawn on top because it's the last child).
	$PlatformerButton.pressed.connect(_open_platformer)
	if pages.is_empty():
		return

	# Continue from the saved page (page 0 the first time).
	# A save sitting on the last page means the story was finished, so start over.
	var saved := SaveGame.page_for(scene_file_path)
	if saved >= pages.size() - 1:
		saved = 0
	index = clampi(saved, 0, pages.size() - 1)
	for i in pages.size():
		pages[i].visible = (i == index)
		pages[i].modulate.a = 1.0

	var first_bubble := _bubble_of(pages[index])
	if first_bubble == null:
		return
	first_bubble.modulate.a = 0.0
	busy = true
	var t := create_tween()
	t.tween_property(first_bubble, "modulate:a", 1.0, FADE_TIME)
	t.tween_callback(_finish)


# _unhandled_input (not _input) so clicking the Platformer button doesn't also turn the page.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MENU_SCENE)
		return
	if busy:
		return
	var clicked: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if clicked or event.is_action_pressed("ui_accept"):
		advance()


func advance() -> void:
	if index + 1 >= pages.size():
		_finish_story()
		return
	busy = true
	var old_page: Control = pages[index]
	index += 1
	SaveGame.set_progress(scene_file_path, index)
	var new_page: Control = pages[index]
	var old_bubble := _bubble_of(old_page)
	var new_bubble := _bubble_of(new_page)

	new_page.modulate.a = 0.0
	if new_bubble:
		new_bubble.modulate.a = 0.0
	new_page.visible = true

	var t := create_tween()
	# 1) hide the old bubble (if the page has one)
	if old_bubble:
		t.tween_property(old_bubble, "modulate:a", 0.0, FADE_TIME * 0.5)
	# 2) fade the new picture in over the old one
	t.tween_property(new_page, "modulate:a", 1.0, FADE_TIME)
	t.tween_callback(old_page.hide)
	# 3) show the new bubble (if the page has one)
	if new_bubble:
		t.tween_property(new_bubble, "modulate:a", 1.0, FADE_TIME * 0.5)
	t.tween_callback(_finish)


# Returns the page's "Bubble" node, or null if the page is picture-only.
func _bubble_of(page: Control) -> CanvasItem:
	return page.get_node_or_null("Bubble") as CanvasItem


# End of the story: reset progress so Play starts from page 1, then fade to the menu.
func _finish_story() -> void:
	busy = true
	SaveGame.reset_progress()
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	t.tween_callback(get_tree().change_scene_to_file.bind(MENU_SCENE))


func _open_platformer() -> void:
	get_tree().change_scene_to_file(PLATFORMER_SCENE)


func _finish() -> void:
	busy = false
