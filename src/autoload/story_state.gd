extends Node

signal marker_changed(npc_id: String, marker: String, value: int)

const MIN_LEVEL := 1
const MAX_LEVEL := 5
const MARKERS: Array[String] = ["friendship", "trust", "fear"]

var flags: Dictionary[String, Variant] = {}
var markers: Dictionary[String, Dictionary] = {}


func new_game(profiles: Array[NpcProfile]) -> void:
	flags.clear()
	markers.clear()
	for profile in profiles:
		var npc_markers: Dictionary[String, int] = {
			"friendship": profile.friendship,
			"trust": profile.trust,
			"fear": profile.fear,
		}
		markers[profile.id] = npc_markers


func adjust(npc_id: String, marker: String, delta: int) -> void:
	if not _is_known(npc_id, marker):
		return
	var old_value := get_marker(npc_id, marker)
	var new_value := clampi(old_value + delta, MIN_LEVEL, MAX_LEVEL)
	if new_value == old_value:
		return
	markers[npc_id][marker] = new_value
	marker_changed.emit(npc_id, marker, new_value)


func get_marker(npc_id: String, marker: String) -> int:
	if not _is_known(npc_id, marker):
		return 0
	return markers[npc_id][marker]


func set_flag(flag: String, value: Variant = true) -> void:
	flags[flag] = value


func has_flag(flag: String) -> bool:
	return flags.has(flag)


func to_dict() -> Dictionary:
	return {"flags": flags.duplicate(true), "markers": markers.duplicate(true)}


func from_dict(data: Dictionary) -> void:
	flags.clear()
	markers.clear()
	var saved_flags: Dictionary = data.get("flags", {})
	flags.assign(saved_flags)
	var saved_markers: Dictionary = data.get("markers", {})
	for npc_id: String in saved_markers:
		var levels: Dictionary = saved_markers[npc_id]
		var npc_markers: Dictionary[String, int] = {}
		for marker: String in levels:
			var level: float = levels[marker]
			npc_markers[marker] = int(level)
		markers[npc_id] = npc_markers


func _is_known(npc_id: String, marker: String) -> bool:
	if not markers.has(npc_id):
		push_error("StoryState: unknown npc '%s'" % npc_id)
		return false
	if marker not in MARKERS:
		push_error("StoryState: unknown marker '%s'" % marker)
		return false
	return true
