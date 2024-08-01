class_name Player
extends Area2D

var last_dirs: Array[String] = [
	
]

signal player_moved(spd: int)

var tween: Tween
var inputs := {
	"u": Vector2i.UP,
	"d": Vector2i.DOWN,
	"l": Vector2i.LEFT,
	"r": Vector2i.RIGHT
}
var moving := false
var movable := true
var map_pos := Vector2i.ONE * 48
var map: Map

func player_process() -> void:
	map = get_tree().current_scene
	for dir: String in inputs.keys():
		if Input.is_action_pressed(dir) and !moving and Menu.curr_menu == Menu.Menus.NONE and movable and Menu.curr_menu == Menu.Menus.NONE:
			await move(dir, 3)

func move(dir: String, spd: int) -> void:
	$Ray.target_position = inputs[dir] * 16
	$Ray.force_raycast_update()
	
	var id := 0
	var prop := 0
	if map.map.size() >= map.ground_layer + 1:
		id = map.map[map.ground_layer][
			posmod(int(map_pos.y >> 4) + inputs[dir].y, map.map_size.y)
		][
			posmod(int(map_pos.x >> 4) + inputs[dir].x, map.map_size.x)
		]
		
		prop = map.collision_flags[id - 1] & (
			int(inputs[dir] == Vector2i.UP) << 3 |
			int(inputs[dir] == Vector2i.DOWN) << 2 |
			int(inputs[dir] == Vector2i.LEFT) << 1 |
			int(inputs[dir] == Vector2i.RIGHT)
		)
	if map.map.size() >= map.obstacle_layer + 1:
		id = map.map[map.obstacle_layer][
			posmod(int(map_pos.y >> 4) + inputs[dir].y, map.map_size.y)
		][
			posmod(int(map_pos.x >> 4) + inputs[dir].x, map.map_size.x)
		]
	
		prop |= map.collision_flags[id] & (
			int(inputs[dir] == Vector2i.UP) << 3 |
			int(inputs[dir] == Vector2i.DOWN) << 2 |
			int(inputs[dir] == Vector2i.LEFT) << 1 |
			int(inputs[dir] == Vector2i.RIGHT)
		)
	if map.loop and Rect2(Vector2.ZERO, Vector2(map.map_size)).has_point(map_pos + inputs[dir]):
		prop = 1
	
	if (!$Ray.is_colliding() and (prop <= 0)) or (Input.is_key_pressed(KEY_CTRL) and OS.is_debug_build()):
		if last_dirs.size() >= 3:
			last_dirs.pop_back()
		last_dirs.push_front(dir)
		moving = true
		emit_signal("player_moved", spd)
		tween = create_tween()
		tween.tween_property(self, "map_pos", inputs[dir] * 16, 1.0/spd).as_relative()
		await tween.finished
		moving = false
