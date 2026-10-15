extends Control
## Chapter 1 intro (test).
## Every child node named "Page..." is one page (an Image + an optional Bubble).
## Pages play in the order they appear in the Scene tree.
## Click or press Enter/Space for the next page. Esc goes back to the menu.
## Transition: old page fades to black -> short pause -> new page fades in from a slight zoom
## -> bubble pops in. Pages never overlap. Timings are the constants below.
## Clicking on the last page ends the story: progress resets and you return to the menu.
## Progress is saved through the SaveGame autoload (scripts/save_game.gd).
## To add a page: duplicate the last Page, rename it (e.g. Page9), swap its textures.

const FADE_TIME := 0.6 # used for the ending fade
const BUBBLE_OUT_TIME := 0.22 # old bubble shrinks away
const FADE_OUT_TIME := 0.45 # old page -> black
const HOLD_TIME := 0.3 # pause on black (the dramatic beat)
const FADE_IN_TIME := 0.6 # black -> new page
const ZOOM_FROM := 1.06 # new page starts 6% zoomed in...
const ZOOM_TIME := 1.4 # ...and settles to 100% over this time
const BUBBLE_FROM := 0.85 # bubble pops from 85% size
const BUBBLE_TIME := 0.35
const MENU_SCENE := "res://scenes/main_menu.tscn"
const PLATFORMER_SCENE := "res://scenes/platformer_test.tscn" # debug

var pages: Array[Control] = []
var index := 0
var busy := false
var curtain: ColorRect # black layer above the pages, created in _make_curtain()


func _ready() -> void:
	for child in get_children():
		if child is Control and String(child.name).begins_with("Page"):
			pages.append(child)
	# Debug button in the top-right corner (it's drawn on top because it's the last child).
	$PlatformerButton.pressed.connect(_open_platformer)
	_make_curtain()
	if pages.is_empty():
		return

	# Continue from the saved page (page 0 the first time).
	# A save sitting on the last page means the story was finished, so start over.
	var saved := SaveGame.page_for(scene_file_path)
	if saved >= pages.size() - 1:
		saved = 0
	index = clampi(saved, 0, pages.size() - 1)
	for page in pages:
		page.hide()

	# Start on black and reveal the first page the same dramatic way.
	busy = true
	curtain.modulate.a = 1.0
	await get_tree().process_frame # let sizes settle so zoom/pop scale from the center
	_reveal(pages[index])


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

	var t := create_tween()
	# 1) old bubble shrinks away (if the page has one)
	if old_bubble:
		old_bubble.pivot_offset = old_bubble.size / 2.0
		t.tween_property(old_bubble, "modulate:a", 0.0, BUBBLE_OUT_TIME)
		t.parallel().tween_property(old_bubble, "scale", Vector2.ONE * BUBBLE_FROM, BUBBLE_OUT_TIME) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	# 2) old page fades out to black
	t.tween_property(curtain, "modulate:a", 1.0, FADE_OUT_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# 3) swap pages while the screen is fully black, then hold for a beat
	t.tween_callback(_swap_pages.bind(old_page))
	t.tween_interval(HOLD_TIME)
	# 4) reveal the new page
	t.tween_callback(_reveal.bind(new_page))


# Fades the black curtain away from `page`, which settles from a slight zoom; then the bubble pops in.
func _reveal(page: Control) -> void:
	var bubble := _bubble_of(page)
	page.pivot_offset = page.size / 2.0
	page.scale = Vector2.ONE * ZOOM_FROM
	page.modulate.a = 1.0
	page.show()
	if bubble:
		bubble.pivot_offset = bubble.size / 2.0
		bubble.scale = Vector2.ONE * BUBBLE_FROM
		bubble.modulate.a = 0.0

	var zoom := create_tween()
	zoom.tween_property(page, "scale", Vector2.ONE, ZOOM_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var t := create_tween()
	t.tween_property(curtain, "modulate:a", 0.0, FADE_IN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if bubble:
		t.tween_property(bubble, "modulate:a", 1.0, BUBBLE_TIME * 0.6)
		t.parallel().tween_property(bubble, "scale", Vector2.ONE, BUBBLE_TIME) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(_finish)


# Hides the old page and resets it, so it looks right if it's shown again later.
func _swap_pages(old_page: Control) -> void:
	old_page.hide()
	old_page.scale = Vector2.ONE
	var b := _bubble_of(old_page)
	if b:
		b.scale = Vector2.ONE
		b.modulate.a = 1.0


# Black layer drawn above the pages but below the Platformer button.
func _make_curtain() -> void:
	curtain = ColorRect.new()
	curtain.name = "Curtain"
	curtain.color = Color.BLACK
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	curtain.modulate.a = 0.0
	add_child(curtain)
	move_child(curtain, $PlatformerButton.get_index())


# Returns the page's "Bubble" node, or null if the page is picture-only.
func _bubble_of(page: Control) -> CanvasItem:
	return page.get_node_or_null("Bubble") as CanvasItem


# End of the story: reset progress so Play starts from page 1, then fade to black and go to the menu.
func _finish_story() -> void:
	busy = true
	SaveGame.reset_progress()
	var t := create_tween()
	t.tween_property(curtain, "modulate:a", 1.0, FADE_TIME * 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_interval(HOLD_TIME)
	t.tween_callback(get_tree().change_scene_to_file.bind(MENU_SCENE))


func _open_platformer() -> void:
	get_tree().change_scene_to_file(PLATFORMER_SCENE)


func _finish() -> void:
	busy = false
