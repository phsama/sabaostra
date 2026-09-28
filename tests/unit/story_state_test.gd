extends GdUnitTestSuite

const StoryStateScript := preload("res://src/autoload/story_state.gd")

var state: StoryStateScript
var emitted: Array[Array]


func before_test() -> void:
	state = auto_free(StoryStateScript.new())
	state.from_dict({"markers": {"pescador": {"friendship": 3, "trust": 1, "fear": 5}}})
	emitted = []
	state.marker_changed.connect(func(npc_id: String, marker: String, value: int) -> void:
		emitted.append([npc_id, marker, value]))


func test_adjust_adds_delta() -> void:
	state.adjust("pescador", "friendship", 1)
	assert_int(state.get_marker("pescador", "friendship")).is_equal(4)


func test_adjust_clamps_at_max() -> void:
	state.adjust("pescador", "friendship", 10)
	assert_int(state.get_marker("pescador", "friendship")).is_equal(5)


func test_adjust_clamps_at_min() -> void:
	state.adjust("pescador", "friendship", -10)
	assert_int(state.get_marker("pescador", "friendship")).is_equal(1)


func test_adjust_emits_new_value() -> void:
	state.adjust("pescador", "trust", 2)
	assert_array(emitted).is_equal([["pescador", "trust", 3]])


func test_adjust_is_silent_when_already_at_limit() -> void:
	state.adjust("pescador", "fear", 1)
	state.adjust("pescador", "trust", -1)
	assert_array(emitted).is_empty()


func test_unknown_npc_or_marker_changes_nothing() -> void:
	var before := state.to_dict()
	state.adjust("fantasma", "fear", 1)
	state.adjust("pescador", "love", 1)
	assert_dict(state.to_dict()).is_equal(before)
	assert_int(state.get_marker("fantasma", "fear")).is_equal(0)
	assert_array(emitted).is_empty()


func test_flags() -> void:
	assert_bool(state.has_flag("woke_on_beach")).is_false()
	state.set_flag("woke_on_beach")
	assert_bool(state.has_flag("woke_on_beach")).is_true()


func test_round_trip_is_identical() -> void:
	state.set_flag("tv_channel", 7)
	var copy: StoryStateScript = auto_free(StoryStateScript.new())
	copy.from_dict(state.to_dict())
	assert_dict(copy.to_dict()).is_equal(state.to_dict())


func test_round_trip_through_json_keeps_markers_as_int() -> void:
	var copy: StoryStateScript = auto_free(StoryStateScript.new())
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	copy.from_dict(parsed)
	assert_dict(copy.to_dict()).is_equal(state.to_dict())
	assert_int(typeof(copy.markers["pescador"]["fear"])).is_equal(TYPE_INT)


func test_to_dict_is_a_copy() -> void:
	var saved := state.to_dict()
	state.adjust("pescador", "friendship", 1)
	assert_int(saved["markers"]["pescador"]["friendship"]).is_equal(3)
