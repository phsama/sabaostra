extends Node

const VERSION := 1
const AUTOSAVE := "autosave"
const SLOTS: Array[String] = ["slot_1", "slot_2", "slot_3", AUTOSAVE]

var save_dir := "user://saves"
var playtime_sec := 0.0


func _process(delta: float) -> void:
	playtime_sec += delta


func save(slot: String, map_id: String, spawn_id: String) -> Error:
	if slot not in SLOTS:
		push_error("SaveService: unknown slot '%s'" % slot)
		return ERR_INVALID_PARAMETER
	DirAccess.make_dir_recursive_absolute(save_dir)
	var file := FileAccess.open(_path(slot), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({
		"version": VERSION,
		"saved_at": Time.get_datetime_string_from_system(true),
		"map_id": map_id,
		"spawn_id": spawn_id,
		"playtime_sec": int(playtime_sec),
		"story_state": StoryState.to_dict(),
	}, "\t"))
	return OK


func autosave(map_id: String, spawn_id: String) -> Error:
	return save(AUTOSAVE, map_id, spawn_id)


func load(slot: String) -> Dictionary:
	if not FileAccess.file_exists(_path(slot)):
		return {"error": "SAVE_ERROR_MISSING"}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(_path(slot))) != OK or not json.data is Dictionary:
		return {"error": "SAVE_ERROR_CORRUPT"}
	var data: Dictionary = json.data
	if data.get("version") != VERSION:
		return {"error": "SAVE_ERROR_VERSION"}
	var story_state: Dictionary = data.get("story_state", {})
	StoryState.from_dict(story_state)
	var playtime: float = data.get("playtime_sec", 0.0)
	playtime_sec = playtime
	return data


func _path(slot: String) -> String:
	return save_dir.path_join(slot + ".json")
