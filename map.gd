class_name Map
extends Node2D

var map_name := "test"
var tileset := {}
var map: Array[Array]
var columns: Array[int]
var cam_pos := Vector2i.ZERO
var map_size := Vector2i(24, 16)
var pm_tweens: Array[Tween] = [null, null, null]
var id: int
var loop := false
var pm_map_pos := {
	
}
var animated_tiles: Dictionary = {
	
}
var curr_frames: Dictionary = {
	
}
var collision_flags: Array[int] = [
	
]
var first_ids: Array[int] = [
	
]
var ground_layer := 0
var obstacle_layer := 1
@onready var player: Player = $PMs/PM1
@onready var pms: Node2D = $PMs
@onready var camera: Camera2D = $Camera
@onready var tmap: TileMap = $Map
@onready var anim: AnimationPlayer = $AnimPlayer

var curr_frame := 0

func _ready() -> void:
	for tween in 3:
		pm_map_pos[str(tween)] = player.map_pos
	
	initialize_map()
	
	player.player_moved.connect(func(spd: int) -> void:
		var targ_pos: Array[Vector2i] = []
		for tween in 3:
			pm_tweens[tween] = null
			targ_pos.append(
				player.map_pos if tween < 1 else targ_pos[tween - 1]
			)
			if player.last_dirs.size() > tween:
				if tween >= 1:
					targ_pos[tween] -= Vector2i(player.inputs[player.last_dirs[tween]]) * 16
				pm_tweens[tween] = create_tween()
				pm_tweens[tween].tween_property(self, "pm_map_pos:%s" % tween, targ_pos[tween], 1.0 / spd)
		if pm_tweens[0]:
			await pm_tweens[0].finished
	)

func _process(_d: float) -> void:
	player.player_process()
	set_positions()
	
	for frame: int in animated_tiles.keys():
		if curr_frame % ceili(animated_tiles[frame][curr_frames[frame]]["duration"] / (1000 / 60.0)) == 0:
			curr_frames[frame] = (curr_frames[frame] + 1) % animated_tiles[frame].size()
	
	tmap.clear()
	tmap.position = -Vector2(cam_pos).posmod(16) - Vector2.ONE * 8
	for l in tmap.tile_set.get_source_count():
		for y in 9:
			for x in 12:
				id = map[l][
					posmod(y - 3 + ((cam_pos.y - 16) >> 4), map_size.y)
				][
					posmod(x - 4 + ((cam_pos.x - 16) >> 4), map_size.x)
				]
				if id > 0:
					if animated_tiles.has(id):
						id = animated_tiles[id][curr_frames[id]]["tileid"] + 1
					tmap.set_cell(l, Vector2i(x, y), l, Vector2i(
						posmod(id - 1, columns[l]),
						floori((id - 1) / float(columns[l]))
					))
	
	curr_frame += 1

func initialize_map() -> void:
	columns.clear()
	
	tileset = (load("res://assets/data/maps/%s.json" % map_name) as JSON).data
	var path := "res://assets/data/maps/"
	
	map.clear()
	collision_flags.clear()
	map_size = Vector2i(
		tileset["width"],
		tileset["height"]
	)
	map.resize(tileset["layers"].size())
	
	for p: Dictionary in tileset["properties"]:
		if p["name"] == "loop":
			loop = p["value"]
			break
	
	first_ids.clear()
	tmap.tile_set = TileSet.new()
	tmap.tile_set.tile_size = Vector2i(16, 16)
	for l in tmap.get_layers_count():
		tmap.remove_layer(l)
	for i in 4:
		if tileset["layers"].size() > i:
			first_ids.append(int(tileset["tilesets"][i]["firstgid"]))
			tmap.add_layer(i)
			tmap.set_layer_z_index(i, i)
			var tmp: TileSetAtlasSource = TileSetAtlasSource.new()
			var ts: Dictionary = (load(path + tileset["tilesets"][i]["source"]) as JSON).data
			var ts_path: String = path + tileset["tilesets"][i]["source"].get_base_dir() + "/"
			var txt: Texture2D = load(ts_path + ts["image"])
			if tileset["layers"][i]["name"] == "ground":
				ground_layer = i
			if tileset["layers"][i]["name"] == "obstacle":
				obstacle_layer = i
			tmp.texture = txt
			if tmp.texture:
				for y in tmp.get_atlas_grid_size().y:
					for x in tmp.get_atlas_grid_size().x:
						tmp.create_tile(Vector2i(x, y))
				for j in (ts["tiles"].size() as int):
					if (ts["tiles"][j] as Dictionary).has("animation"):
						animated_tiles[j + first_ids[i]] = ts["tiles"][j]["animation"]
						curr_frames[j + first_ids[i]] = 0
					collision_flags.append(ts["tiles"][j]["properties"][0]["value"] as int)
			tmap.tile_set.add_source(tmp)
			columns.append(int(ts["columns"]))
	
	for l in map.size():
		map[l].resize(map_size.y)
		for y in map[l].size():
			map[l][y] = []
			map[l][y].resize(map_size.x)
			for x in (map[l][y].size() as int):
				map[l][y][x] = tileset["layers"][l]["data"][x + y * tileset["layers"][l]["width"]]

func set_positions() -> void:
	if loop:
		player.map_pos = Vector2i(
			posmod(int(player.map_pos.x), map_size.x * 16),
			posmod(int(player.map_pos.y), map_size.y * 16)
		)
	
	cam_pos = player.map_pos
	if !loop:
		cam_pos.x = clampi(cam_pos.x, 72, map_size.x * 16 - 88)
		cam_pos.y = clampi(cam_pos.y, 56, map_size.y * 16 - 64)
	
	player.position = (player.map_pos - cam_pos) + Vector2i(72, 52)
	for follower in 3:
		pms.get_node("PM%s" % (follower + 2)).position = (
			pm_map_pos[str(follower)] - cam_pos
		) + Vector2i(72, 52)
