extends GdUnitTestSuite

const SaveServiceScript := preload("res://src/autoload/save_service.gd")
const TEST_DIR := "user://test_saves"

var service: SaveServiceScript


func before_test() -> void:
	service = auto_free(SaveServiceScript.new())
	service.save_dir = TEST_DIR
	StoryState.from_dict({
		"flags": {"woke_on_beach": true},
		"markers": {"pescador": {"friendship": 3, "trust": 2, "fear": 4}},
	})


func after_test() -> void:
	if not DirAccess.dir_exists_absolute(TEST_DIR):
		return
	for file in DirAccess.get_files_at(TEST_DIR):
		DirAccess.remove_absolute(TEST_DIR.path_join(file))
	DirAccess.remove_absolute(TEST_DIR)


func test_save_then_load_restores_story_and_position() -> void:
	var expected := StoryState.to_dict()
	service.playtime_sec = 42.7
	assert_int(service.save("slot_2", "beach", "from_apartment")).is_equal(OK)

	StoryState.from_dict({})
	service.playtime_sec = 0.0
	var data := service.load("slot_2")

	assert_str(data.get("map_id")).is_equal("beach")
	assert_str(data.get("spawn_id")).is_equal("from_apartment")
	assert_dict(StoryState.to_dict()).is_equal(expected)
	assert_float(service.playtime_sec).is_equal(42.0)


func test_autosave_writes_its_own_file() -> void:
	service.autosave("outskirts", "from_beach")
	assert_bool(FileAccess.file_exists(TEST_DIR.path_join("autosave.json"))).is_true()
	assert_str(service.load("autosave").get("map_id")).is_equal("outskirts")


func test_save_file_is_readable_json_with_all_fields() -> void:
	service.save("slot_1", "beach", "start")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TEST_DIR.path_join("slot_1.json")))
	assert_array(data.keys()).contains_exactly_in_any_order(
		["version", "saved_at", "map_id", "spawn_id", "playtime_sec", "story_state"])


func test_refuses_unknown_version_without_touching_state() -> void:
	service.save("slot_1", "beach", "start")
	var path := TEST_DIR.path_join("slot_1.json")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	data["version"] = 999
	data["story_state"] = {}
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(data))
	var before := StoryState.to_dict()

	assert_dict(service.load("slot_1")).is_equal({"error": "SAVE_ERROR_VERSION"})
	assert_dict(StoryState.to_dict()).is_equal(before)


func test_missing_slot() -> void:
	assert_dict(service.load("slot_3")).is_equal({"error": "SAVE_ERROR_MISSING"})


func test_corrupt_file() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	FileAccess.open(TEST_DIR.path_join("slot_1.json"), FileAccess.WRITE).store_string("{not json")
	assert_dict(service.load("slot_1")).is_equal({"error": "SAVE_ERROR_CORRUPT"})


func test_unknown_slot_is_refused() -> void:
	assert_int(service.save("slot_9", "beach", "start")).is_equal(ERR_INVALID_PARAMETER)
