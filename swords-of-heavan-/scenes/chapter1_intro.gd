extends Control
## Chapter 1 intro (test).
## Every child node named "Page..." is one page (an Image + a Bubble).
## Click or press Enter/Space to fade to the next page.
## To add a page: duplicate Page2 in the scene, rename it Page3, swap its textures.

const FADE_TIME := 0.6

var pages: Array[Control] = []
var index := 0
var busy := false


func _ready() -> void:
	for child in get_children():
		if child is Control and String(child.name).begins_with("Page"):
			pages.append(child)
	if pages.is_empty():
		return

	# Only the first page is shown when the game starts.
	for i in pages.size():
		pages[i].visible = (i == 0)
		pages[i].modulate.a = 1.0

	var first_bubble := pages[0].get_node("Bubble") as CanvasItem
	first_bubble.modulate.a = 0.0
	busy = true
	var t := create_tween()
	t.tween_property(first_bubble, "modulate:a", 1.0, FADE_TIME)
	t.tween_callback(_finish)


func _input(event: InputEvent) -> void:
	if busy:
		return
	var clicked: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if clicked or event.is_action_pressed("ui_accept"):
		advance()


func advance() -> void:
	if index + 1 >= pages.size():
		return # end of the test scene
	busy = true
	var old_page: Control = pages[index]
	index += 1
	var new_page: Control = pages[index]
	var old_bubble := old_page.get_node("Bubble") as CanvasItem
	var new_bubble := new_page.get_node("Bubble") as CanvasItem

	new_page.modulate.a = 0.0
	new_bubble.modulate.a = 0.0
	new_page.visible = true

	var t := create_tween()
	# 1) hide the old bubble
	t.tween_property(old_bubble, "modulate:a", 0.0, FADE_TIME * 0.5)
	# 2) fade the new picture in over the old one
	t.tween_property(new_page, "modulate:a", 1.0, FADE_TIME)
	t.tween_callback(old_page.hide)
	# 3) show the new bubble
	t.tween_property(new_bubble, "modulate:a", 1.0, FADE_TIME * 0.5)
	t.tween_callback(_finish)


func _finish() -> void:
	busy = false
