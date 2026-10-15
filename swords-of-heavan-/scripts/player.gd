extends CharacterBody2D
## Joan (debug platformer player).
## Standing still -> FRONT sprite. Walking -> SIDE sprite, mirrored when going left.
## Controls: Left/Right or A/D to walk, Space / Up / W to jump.

const SPEED := 420.0
const JUMP_VELOCITY := -950.0
const GRAVITY_SCALE := 2.2

@export var front_texture: Texture2D
@export var side_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * GRAVITY_SCALE * delta

	if _jump_pressed() and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var dir := _direction()
	velocity.x = dir * SPEED
	move_and_slide()
	_update_sprite(dir)


func _direction() -> float:
	var d := 0.0
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		d -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		d += 1.0
	return d


func _jump_pressed() -> bool:
	return Input.is_action_just_pressed("ui_up") \
		or Input.is_physical_key_pressed(KEY_SPACE) \
		or Input.is_physical_key_pressed(KEY_W)


func _update_sprite(dir: float) -> void:
	if dir == 0.0:
		sprite.texture = front_texture
		sprite.flip_h = false
	else:
		sprite.texture = side_texture
		sprite.flip_h = dir < 0.0 # side art faces right; mirror for left
